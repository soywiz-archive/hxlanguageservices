package haxe.languageservices.parser;
import haxe.languageservices.parser.TypeContext.TypeClass;
import haxe.languageservices.parser.TypeContext.TypeTypedef;
import haxe.languageservices.util.StringUtils;
import haxe.io.Input;
import haxe.languageservices.parser.Completion.CompletionContext;
import haxe.languageservices.parser.Completion.CompletionScope;
import haxe.languageservices.parser.Completion.CompletionType;
import haxe.languageservices.parser.Completion.CompletionEntry;
import haxe.languageservices.parser.Completion.CompletionList;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.parser.Completion.CCompletion;
import haxe.languageservices.parser.Completion.Reference;
import haxe.languageservices.parser.Expr.CType;
import haxe.languageservices.parser.Expr.ErrorDef;
import haxe.languageservices.parser.Expr.Argument;
import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.parser.Expr.Expr;
import haxe.languageservices.parser.Expr.ExprDef;
import haxe.languageservices.parser.Expr.Stm;
import haxe.languageservices.parser.Expr.StmDef;
import haxe.languageservices.parser.Expr.TypeParameter;
import haxe.languageservices.parser.Expr.TypeParameters;
import haxe.languageservices.parser.Errors.ErrorContext;

import haxe.languageservices.parser.Tokenizer.Token;

class Parser {

// config / variables
    public var opPriority:Map<String, Int>;
    public var opRightAssoc:Map<String, Bool>;
    public var unops:Map<String, Bool>; // true if allow postfix

// implementation
    var uid:Int = 0;
    public var typeContext:TypeContext;
    private var tokenizer:Tokenizer;
    public var errors:ErrorContext;
    private var completion:CompletionContext;
    
    public function new(?typeContext:TypeContext) {
        if (typeContext == null) typeContext = new TypeContext();
        this.typeContext = typeContext;
        var priorities = [
        ["%"],
        ["*", "/"],
        ["+", "-"],
        ["<<", ">>", ">>>"],
        ["|", "&", "^"],
        ["==", "!=", ">", "<", ">=", "<="],
        ["..."],
        ["&&"],
        ["||"],
        ["=", "+=", "-=", "*=", "/=", "%=", "<<=", ">>=", ">>>=", "|=", "&=", "^="],
        ];
        opPriority = new Map();
        opRightAssoc = new Map();
        unops = new Map();
        for (i in 0...priorities.length) {
            for (x in priorities[i]) {
                opPriority.set(x, i);
                if (i == 9) opRightAssoc.set(x, true);
            }
        }
        for (x in ["!", "++", "--", "-", "~"]) {
            unops.set(x, x == "++" || x == "--");
        }
    }

    public function parseExpressionsString(s:String, ?path:String) {
        setInputString(s, path);
        return parseExpressions();
    }

    public function parseFileString(s:String, ?path:String) {
        setInputString(s, path);
        return parseHaxeFile();
    }
    
    public function parseHaxeFile():Stm {
        return parseTopLevel();
    }
    
    private function isValidPackagePath(path:Array<String>) {
        for (i in path) if (!StringUtils.isLowerCase(i)) return false;
        return true;
    }
    
    private function parseTopLevel():Stm {
        var p0 = tokenizer.tokenMin;
        var parts = new Array<Stm>();
        var packageName = new Array<String>();
        var imports = new Array<Array<String>>();
        var importCount = 0;
        var typeCount = 0;
        while (true) {
            var p1 = tokenizer.tokenMin;
            var tk = token();
            switch (tk) {
                case Token.TId("package"):
                    if (importCount != 0 || typeCount != 0) {
                        errors.add(new Error(ErrorDef.EUnknown("Package must appear at the beggining of the file"), p1, tokenizer.tokenMax));
                    }
                    packageName = parseFullyQualifiedName();
                    if (!isValidPackagePath(packageName)) {
                        errors.add(new Error(ErrorDef.EUnknown("Package name must be all lower case"), p1, tokenizer.tokenMax));
                    }
                    ensure(Token.TSemicolon);
                    parts.push(mkStm(StmDef.EPackage(packageName), p1, tokenizer.tokenMax));
                case Token.TId("import"):
                    importCount++;
                    if (typeCount != 0) {
                        errors.add(new Error(ErrorDef.EUnknown("Package must appear at the beggining of the file"), p1, tokenizer.tokenMax));
                    }
                    var fqname = parseFullyQualifiedName();
                    ensure(Token.TSemicolon);
                    parts.push(mkStm(StmDef.EImport(fqname), p1, tokenizer.tokenMax));
                    imports.push(fqname);
                case Token.TId("typedef"):
                    typeCount++;
                    var typedefName = parseIdentifier();
                    if (typedefName == null) {

                    } else {
                        var type = typeContext.getPackage(packageName.join('.')).getClass(typedefName, TypeTypedef);
                        type.typeParams = parseTypeParametersWithDiamonds();
                        ensure(Token.TOp('='));
                        var ttype:CType = null;
                        completion.pushContext(function(c:CompletionScope) {
                            for (p in type.typeParams) c.addLocal(p.name, CType.CTTypeParam, null);
                            ttype = parseType();
                        });
                        var ctype = CompletionTypeUtils.fromCType(ttype);
                        ensure(Token.TSemicolon);
                        cast(type, TypeTypedef).setTargetType(ctype);

                        parts.push(mkStm(StmDef.ETypedef(packageName, typedefName), p1, tokenizer.tokenMax));
                    }
                case Token.TId("class"):
                    typeCount++;
                    var className = parseIdentifier();
                    if (className == null) {
                    
                    } else {
                        var type = typeContext.getPackage(packageName.join('.')).getClass(className, TypeClass);

                        if (!StringUtils.isFirstUpper(className)) {
                            errors.add(new Error(ErrorDef.EUnknown("Class name must be capitalized"), tokenizer.tokenMin, tokenizer.tokenMax));
                        }

                        type.typeParams = parseTypeParametersWithDiamonds();

                        completion.pushContext(function(c:CompletionScope) {
                            ensure(Token.TBrOpen);
                            for (p in type.typeParams) {
                                c.addLocal(p.name, CType.CTTypeParam, null, CompletionTypeUtils.fromCType(CType.CTTypeParam));
                            }
                            /*
                            c.addLocal('public', CType.CTInvalid, null, CompletionType.Keyword);
                            c.addLocal('private', CType.CTInvalid, null, CompletionType.Keyword);
                            c.addLocal('var', CType.CTInvalid, null, CompletionType.Keyword);
                            c.addLocal('function', CType.CTInvalid, null, CompletionType.Keyword);
                            */
                            parseClassElements();
                            ensure(Token.TBrClose);
                        });

                        parts.push(mkStm(StmDef.EClass(packageName, className, type.typeParams), p1, tokenizer.tokenMax));
                    }

                case Token.TEof:
                    break;
                default:
                    unexpected(tk, 'Expected eof, package, import or class');
                    push(tk);
                    break;
            }
        }
        return mkStm(StmDef.EFile(parts), p0);
    }
    
    private function parseTypeParametersWithDiamonds():TypeParameters {
        var tk = token();
        switch (tk) {
            case Token.TOp('<'):
                var typeParameters = parseTypeParameters();
                ensure(Token.TOp('>'));
                return typeParameters;
            default:
                push(tk);
        }
        return [];
    }
    
    private function parseTypeParameters():TypeParameters {
        var params = new TypeParameters();
        while (true) {
            var param = parseTypeParameter();
            if (param == null) break;
            params.push(param);
            var tk = token();
            switch (tk) {
                case Token.TComma:
                default:
                    push(tk);
                    break;
            }
        }
        return params;
    }

    private function parseTypeParameter():TypeParameter {
        var tk = token();
        switch (tk) {
            case Token.TId(name):
                tk = token();
                var constraints:Array<CType> = null;
                switch (tk) {
                    case Token.TDoubleDot:
                        constraints = parseTypeParameterConstraints();
                    default:
                        push(tk);
                }
                return { name: name, constraints: constraints };
            default:
                push(tk);
        }
        return null;
    }

    private function parseTypeParameterConstraints():Array<CType> {
        var tk = token();
        switch (tk) {
            case Token.TPOpen:
                var types = parseTypeList();
                ensure(Token.TPClose);
                return types;
            case Token.TId(name):
                push(tk);
                return [parseType()];
            default:
        }
        return null;
    }

    private function parseClassElements() {
        while (true) {
            var r = parseClassElement();
            if (r == null) break;
        }
    }

    private function parseClassElement() {
        var modifier:String = null;
        var isStatic = false;
        while (true) {
            var tk = token();
            switch (tk) {
                case Token.TId('public'), Token.TId('private'):
                    if (modifier != null) unexpected(tk, 'already has a modifier');
                    modifier = switch (tk) {
                        case Token.TId('public'): "public";
                        case Token.TId('private'): "public";
                        default: null;
                    }
                case Token.TId('static'):
                    if (isStatic == true) unexpected(tk, 'already has the static modifier');
                    isStatic = true;
                case Token.TId('var'):
                    var varName = parseIdentifier();
                    ensure(Token.TSemicolon);
                    break;
                case Token.TBrClose:
                    push(tk);
                    break;
                default:
                    unexpected(tk, 'field info');
                    break;
            }
        }
        return null;
    }

    private function parseIdentifier():String {
        var tk = token();
        var ident:String = null;
        switch(tk) {
            case Token.TId(id): ident = id;
            default: unexpected(tk, "identifier");
        }
        return ident;
    }

    private function parseFullyQualifiedName():Array<String> {
        var chunks = new Array<String>();
        while (true) {
            var tk = token();
            switch (tk) {
                case Token.TId(name):
                    chunks.push(name);
                    if (!check(Token.TDot)) break;
                default:
                    push(tk);
                    break;
            }
        }
        return chunks;
    }

    public function setInput(s:Input, ?path:String):Void {
        this.uid = 0;
        this.tokenizer = new Tokenizer(s, path);
        this.errors = new ErrorContext();
        this.completion = new CompletionContext(tokenizer, errors);
    }

    public function setInputString(s:String, ?path:String):Void {
        setInput(new haxe.io.StringInput(s), path);
    }

    public function parseExpressions() {
        var a:Array<Expr> = [];

        completion.pushContext(function(c) {
            while (true) {
                var tk = token();
                if (tk == TEof) break;
                push(tk);
                a.push(parseFullExpr());
            }
        });
        return if (a.length == 1) a[0] else mk(EBlock(a), 0);
    }

    function unexpected(tk:Token, expected:String):Dynamic {
        tokenizer.error(EUnexpected('expected:' + expected + ', found:' + tokenizer.tokenString(tk) + ""), tokenizer.tokenMin, tokenizer.tokenMax);
        return null;
    }

    private function push(t:Token) return tokenizer.push(t);

    private function token():Token return tokenizer.token();

    inline function ensure(tk:Token) {
        var t = token();
        if ('' + t != '' + tk) unexpected(t, tokenizer.tokenString(tk));
    }

    inline function check(tk:Token) {
        var t = token();
        if (t != tk) {
            push(t);
            return false;
        } else {
            return true;
        }
    }

    inline function expr(e:Expr) return e.e;

    inline function pmin(e:Expr) return e.pmin;

    inline function pmax(e:Expr) return e.pmax;

    inline function mk(e:ExprDef, ?pmin:Int, ?pmax:Int):Expr {
        if (pmin == null) pmin = tokenizer.tokenMin;
        if (pmax == null) pmax = tokenizer.tokenMax;
        return { e : e, pmin : pmin, pmax : pmax };
    }

    inline function mkStm(e:StmDef, ?pmin:Int, ?pmax:Int):Stm {
        if (pmin == null) pmin = tokenizer.tokenMin;
        if (pmax == null) pmax = tokenizer.tokenMax;
        return { e : e, pmin : pmin, pmax : pmax };
    }

    function isBlock(e:Expr) {
        return switch( expr(e) ) {
            case EBlock(_), EObject(_), ESwitch(_): true;
            case EFunction(_, e, _, _): isBlock(e);
            case EVar(_, _, e): e != null && isBlock(e);
            case EIf(_, e1, e2): if (e2 != null) isBlock(e2) else isBlock(e1);
            case EBinop(_, _, e): isBlock(e);
            case EUnop(_, prefix, e): !prefix && isBlock(e);
            case EWhile(_, e): isBlock(e);
            case EFor(_, _, e): isBlock(e);
            case EReturn(e): e != null && isBlock(e);
            default: false;
        }
    }

    function parseFullExpr() {
        var e = parseExpr();
        var tk = token();
        if (tk != TSemicolon && tk != TEof) {
            if (isBlock(e)) push(tk); else unexpected(tk, 'block');
        }
        return e;
    }
    
    public function callCompletionAt(index:Int):CCompletion {
        return completion.root.locateIndex(index).callCompletion;
    }

    public function completionsAt(index:Int):CompletionList {
        var out = [];
        var scope = completion.root.locateIndex(index);
        switch (scope.getCompletionType()) {
            case CompletionType.Object(items):
                out = out.concat(items);
            default:
        }
        return new CompletionList(out);
    }

    function parseObject(p1) {
// parse object
        var fl = new Array();
        while (true) {
            var tk = token();
            var id = null;
            switch( tk ) {
                case TId(i): id = i;
                case TConst(c):
                    switch( c ) {
                        case CString(s): id = s;
                        default: unexpected(tk, 'string');
                    }
                case TBrClose: break;
                default: unexpected(tk, 'identifier, const or }');
            }
            ensure(TDoubleDot);
            fl.push({ name : id, e : parseExpr() });
            tk = token();
            switch( tk ) {
                case TBrClose: break;
                case TComma:
                default: unexpected(tk, '} or ,');
            }
        }
        return parseExprNext(mk(EObject(fl), p1));
    }

    function parseExpr():Expr {
        var tk = token();
        var p1 = tokenizer.tokenMin;
        switch( tk ) {
            case TId(id):
                var e:Expr = parseStructure(id);
                if (e == null) {
                    e = mk(EIdent(id));
                    var local = completion.scope.getLocal(id);
                    if (local != null) {
                        local.addReference(Reference.Read(e));
                    } else {
                        errors.errors.push(new Error(ErrorDef.EUnknownVariable('Can\'t find "$id"'), e.pmin, e.pmax));
                    }
                }
                return parseExprNext(e);
            case TConst(c): return parseExprNext(mk(EConst(c)));
            case Token.TPOpen:
                var e = parseExpr();
                ensure(TPClose);
                return parseExprNext(mk(EParent(e), p1, tokenizer.tokenMax));
            case Token.TBrOpen:
                tk = token();
                switch( tk ) {
                    case TBrClose:
                        return parseExprNext(mk(EObject([]), p1));
                    case TId(_):
                        var tk2 = token();
                        push(tk2);
                        push(tk);
                        switch( tk2 ) {
                            case TDoubleDot:
                                return parseExprNext(parseObject(p1));
                            default:
                        }
                    case TConst(c):
                        switch( c ) {
                            case CString(_):
                                var tk2 = token();
                                push(tk2);
                                push(tk);
                                switch( tk2 ) {
                                    case TDoubleDot:
                                        return parseExprNext(parseObject(p1));
                                    default:
                                }
                            default:
                                push(tk);
                        }
                    default:
                        push(tk);
                }
                var a = new Array();
                completion.pushContext(function(c) {
                    while (true) {
                        a.push(parseFullExpr());
                        tk = token();
                        if (tk == TBrClose) break;
                        push(tk);
                    }
                });
                return mk(EBlock(a), p1);
            case TOp(op):
                if (unops.exists(op)) return makeUnop(op, parseExpr());
                return unexpected(tk, 'unary operator');
            case Token.TBkOpen: // [
                var a = new Array();
                tk = token();
                while (tk != TBkClose) {
                    push(tk);
                    a.push(parseExpr());
                    tk = token();
                    if (tk == TComma)
                        tk = token();
                }
                if (a.length == 1)
                    switch( expr(a[0]) ) {
                        case EFor(_), EWhile(_):
                            var tmp = "__a_" + (uid++);
                            var e = mk(EBlock([
                                mk(EVar(tmp, null, mk(EArrayDecl([]), p1)), p1),
                                mapCompr(tmp, a[0]),
                                mk(EIdent(tmp), p1),
                            ]), p1);
                            return parseExprNext(e);
                        default:
                    }
                return parseExprNext(mk(EArrayDecl(a), p1));
            default:
                return unexpected(tk, '----');
        }
    }

    function mapCompr(tmp:String, e:Expr) {
        var edef = switch( expr(e) ) {
            case EFor(v, it, e2): EFor(v, it, mapCompr(tmp, e2));
            case EWhile(cond, e2): EWhile(cond, mapCompr(tmp, e2));
            case EIf(cond, e1, e2) if( e2 == null ): EIf(cond, mapCompr(tmp, e1), null);
            case EBlock([e]): EBlock([mapCompr(tmp, e)]);
            case EParent(e2): EParent(mapCompr(tmp, e2));
            default: ECall(mk(EField(mk(EIdent(tmp), pmin(e), pmax(e)), "push"), pmin(e), pmax(e)), [e]);
        }
        return mk(edef, pmin(e), pmax(e));
    }

    function makeUnop(op, e) {
        return switch( expr(e) ) {
            case EBinop(bop, e1, e2): mk(EBinop(bop, makeUnop(op, e1), e2), pmin(e1), pmax(e2));
            case ETernary(e1, e2, e3): mk(ETernary(makeUnop(op, e1), e2, e3), pmin(e1), pmax(e3));
            default: mk(EUnop(op, true, e), pmin(e), pmax(e));
        }
    }

    function makeBinop(op, e1, e) {
        return switch( expr(e) ) {
            case EBinop(op2, e2, e3):
                if (opPriority.get(op) <= opPriority.get(op2) && !opRightAssoc.exists(op)) {
                    mk(EBinop(op2, makeBinop(op, e1, e2), e3), pmin(e1), pmax(e3));
                } else {
                    mk(EBinop(op, e1, e), pmin(e1), pmax(e));
                }
            case ETernary(e2, e3, e4):
                if (opRightAssoc.exists(op)) {
                    mk(EBinop(op, e1, e), pmin(e1), pmax(e));
                } else {
                    mk(ETernary(makeBinop(op, e1, e2), e3, e4), pmin(e1), pmax(e));
                }
            default:
                mk(EBinop(op, e1, e), pmin(e1), pmax(e));
        }
    }

    function parseStructure(id:String):Expr {
        var p1 = tokenizer.tokenMin;
        return switch( id ) {
            case "if":
                var cond = parseExpr();
                var e1 = parseExpr();
                var e2 = null;
                var semic = false;
                var tk = token();
                if (tk == TSemicolon) {
                    semic = true;
                    tk = token();
                }
                if (Type.enumEq(tk, TId("else"))) {
                    e2 = parseExpr();
                } else {
                    push(tk);
                    if (semic) push(TSemicolon);
                }
                mk(EIf(cond, e1, e2), p1, (e2 == null) ? tokenizer.tokenMax : pmax(e2));
            case "var":
                var tk:Token;
                var ident:String = parseIdentifier();
                tk = token();
                var t = null;
                if (tk == TDoubleDot) {
                    t = parseType();
                    tk = token();
                }
                var e = null;
                if (Type.enumEq(tk, TOp("="))) {
                    e = parseExpr();
                } else {
                    push(tk);
                }
                completion.scope.addLocal(ident, t, e);
                mk(EVar(ident, t, e), p1, (e == null) ? tokenizer.tokenMax : pmax(e));
            case "while":
                var econd = parseExpr();
                var e = parseExpr();
                mk(EWhile(econd, e), p1, pmax(e));
            case "for":
                ensure(TPOpen);
                var tk = token();
                var vname:String = null;
                switch( tk ) {
                    case TId(id): vname = id;
                    default: unexpected(tk, 'identifier');
                }
                tk = token();
                if (!Type.enumEq(tk, TId("in"))) unexpected(tk, 'in');
                var eiter = parseExpr();
                ensure(TPClose);
                var e:Expr = null;
                var forContext = completion.pushContext(function(scope:CompletionScope) {
                    scope.addLocal(vname, null, eiter, scope.getElementType(eiter));
                    e = parseExpr();
                });
                mk(EFor(vname, eiter, e), p1, pmax(e));
            case "break": mk(EBreak);
            case "continue": mk(EContinue);
            case "else": unexpected(TId(id), '--');
            case "function":
                var tk = token();
                var name = null;
                switch( tk ) {
                    case TId(id): name = id;
                    default: push(tk);
                }
                ensure(TPOpen);
                var args:Array<Argument> = [];
                tk = token();
                if (tk != TPClose) {
                    var done = false;
                    while (!done) {
                        var name = null, opt = false;
                        switch( tk ) {
                            case TQuestion:
                                opt = true;
                                tk = token();
                            default:
                        }
                        switch( tk ) {
                            case TId(id): name = id;
                            default: unexpected(tk, 'identifier');
                        }
                        tk = token();
                        var arg:Argument = { name : name };
                        args.push(arg);
                        if (opt) arg.opt = true;
                        if (tk == TDoubleDot) {
                            arg.t = parseType();
                            tk = token();
                        }
                        switch( tk ) {
                            case Token.TComma: tk = token();
                            case Token.TPClose: done = true;
                            default: unexpected(tk, 'comma or )');
                        }
                    }
                }
                var ret = null;
                tk = token();
                if (tk != TDoubleDot) {
                    push(tk);
                } else {
                    ret = parseType();
                }
                var body:Expr = null;
                var bodyScope = completion.pushContext(function(scope:CompletionScope) {
                    for (arg in args) {
                        scope.addLocal(arg.name, arg.t, null, CompletionTypeUtils.fromCType(arg.t));
                    }
                    body = parseExpr();
                });
                var expr = mk(EFunction(args, body, name, ret), p1, pmax(body));
                completion.scope.addLocal(name, ret, expr, bodyScope);
                expr;
            case "return":
                var tk = token();
                push(tk);
                var e = if (tk == TSemicolon) null else parseExpr();
                mk(EReturn(e), p1, if (e == null) tokenizer.tokenMax else pmax(e));
            case "new":
                var a = new Array();
                var tk = token();
                switch( tk ) {
                    case TId(id): a.push(id);
                    default: unexpected(tk, 'identifier');
                }
                var next = true;
                while (next) {
                    tk = token();
                    switch( tk ) {
                        case Token.TDot:
                            tk = token();
                            switch(tk) {
                                case TId(id): a.push(id);
                                default: unexpected(tk, 'identifier');
                            }
                        case Token.TPOpen:
                            next = false;
                        default:
                            unexpected(tk, '. or (');
                    }
                }
                var args = parseExprList(TPClose);
                mk(ENew(a.join("."), args), p1);
            case "throw":
                var e = parseExpr();
                mk(EThrow(e), p1, pmax(e));
            case "try":
                var e = parseExpr();
                var tk = token();
                if (!Type.enumEq(tk, TId("catch"))) unexpected(tk, 'catch');
                ensure(TPOpen);
                tk = token();
                var vname = switch( tk ) {
                    case TId(id): id;
                    default: unexpected(tk, 'identifier');
                }
                ensure(TDoubleDot);
                var t = null;
                t = parseType();
                ensure(TPClose);
                var ec = parseExpr();
                mk(ETry(e, vname, t, ec), p1, pmax(ec));
            case "switch":
                var e = parseExpr();
                var def = null, cases = [];
                ensure(TBrOpen);
                while (true) {
                    var tk = token();
                    switch( tk ) {
                        case TId("case"):
                            var c = { values : [], expr : null };
                            cases.push(c);
                            while (true) {
                                var e = parseExpr();
                                c.values.push(e);
                                tk = token();
                                switch( tk ) {
                                    case TComma:
// next expr
                                    case TDoubleDot:
                                        break;
                                    default:
                                        unexpected(tk, ', or :');
                                }
                            }
                            var exprs = [];
                            while (true) {
                                tk = token();
                                push(tk);
                                switch( tk ) {
                                    case TId("case"), TId("default"), TBrClose:
                                        break;
                                    default:
                                        exprs.push(parseFullExpr());
                                }
                            }
                            c.expr = if (exprs.length == 1)
                                exprs[0];
                            else if (exprs.length == 0)
                                mk(EBlock([]), tokenizer.tokenMin, tokenizer.tokenMin);
                            else
                                mk(EBlock(exprs), pmin(exprs[0]), pmax(exprs[exprs.length - 1]));
                        case TId("default"):
                            if (def != null) unexpected(tk, 'default already specified');
                            ensure(TDoubleDot);
                            var exprs = [];
                            while (true) {
                                tk = token();
                                push(tk);
                                switch( tk ) {
                                    case TId("case"), TId("default"), TBrClose:
                                        break;
                                    default:
                                        exprs.push(parseFullExpr());
                                }
                            }
                            def = if (exprs.length == 1)
                                exprs[0];
                            else if (exprs.length == 0)
                                mk(EBlock([]), tokenizer.tokenMin, tokenizer.tokenMin);
                            else
                                mk(EBlock(exprs), pmin(exprs[0]), pmax(exprs[exprs.length - 1]));
                        case TBrClose:
                            break;
                        default:
                            unexpected(tk, 'case or default or }');
                    }
                }
                mk(ESwitch(e, cases, def), p1, tokenizer.tokenMax);
            default:
                null;
        }
    }

    function parseExprNext(e1:Expr) {
        var tk = token();
        switch( tk ) {
            case TOp(op):
                if (unops.get(op)) {
                    if (isBlock(e1) || switch(expr(e1)) { case EParent(_): true; default: false; }) {
                        push(tk);
                        return e1;
                    }
                    return parseExprNext(mk(EUnop(op, false, e1), pmin(e1)));
                }
                return makeBinop(op, e1, parseExpr());
            case TDot:
                tk = token();
                var field = null;


                var tp = completion.scope.getType(e1);
                completion.scope.createChild()
                    .setBounds(tokenizer.tokenMax, tokenizer.tokenMax)
                    .setCompletionType(tp)
                ;

                switch(tk) {
                    case TId(id): field = id;
                    default: unexpected(tk, 'identifier');
                }
                var exprType = completion.scope.getType(e1);
                if (!CompletionTypeUtils.hasField(exprType, field)) {
                    trace('Expression $e1 doesn\'t contain field $field');
                    trace('type:' + exprType);
                }
                return parseExprNext(mk(EField(e1, field), pmin(e1)));
            case TPOpen:
                var args = parseExprList(TPClose);
                
                var type = completion.scope.getType(e1);
                switch (type) {
                    case CompletionType.Function(type, name, targs, tret):
                        for (aindex in 0 ... args.length) {
                            var arg = args[aindex];
                            completion.scope.createChild().setBounds(arg.pmin, arg.pmax).setCallCompletion(
                                CCompletion.CallCompletion(type, name, targs, { type: tret }, aindex)
                            );
                        }
                    default:
                }
                return parseExprNext(mk(ECall(e1, args), pmin(e1)));
            case TBkOpen:
                var e2 = parseExpr();
                ensure(TBkClose);
                return parseExprNext(mk(EArray(e1, e2), pmin(e1)));
            case TQuestion:
                var e2 = parseExpr();
                ensure(TDoubleDot);
                var e3 = parseExpr();
                return mk(ETernary(e1, e2, e3), pmin(e1), pmax(e3));
            default:
                push(tk);
                return e1;
        }
    }
    
    function parseTypeList():Array<CType> {
        var types = new Array<CType>();
        while (true) {
            var type = parseType();
            if (type == null) break;
            types.push(type);
            if (!check(Token.TComma)) break;
        }
        return types;
    }

    function parseType():CType {
        var t = token();
        switch( t ) {
            case TId(v):
                var path = [v];
                while (true) {
                    t = token();
                    if (t != TDot)
                        break;
                    t = token();
                    switch( t ) {
                        case TId(v):
                            path.push(v);
                        default:
                            unexpected(t, "identifier");
                    }
                }
                var params = null;
                switch( t ) {
                    case TOp(op):
                        if (op == "<") {
                            params = [];
                            while (true) {
                                params.push(parseType());
                                t = token();
                                switch( t ) {
                                    case TComma: continue;
                                    case TOp(op): if (op == ">") break;
                                    default:
                                }
                                unexpected(t, ", or >");
                            }
                        } else {
                            push(t);
                        }
                    default:
                        push(t);
                }
                return parseTypeNext(CTPath(path, params));
            case Token.TPOpen:
                var t = parseType();
                ensure(TPClose);
                return parseTypeNext(CTParent(t));
            case Token.TBrOpen:
                var fields = [];
                while (true) {
                    t = token();
                    switch( t ) {
                        case Token.TBrClose: break;
                        case Token.TId(name):
                            ensure(TDoubleDot);
                            fields.push({ name : name, t : parseType() });
                            t = token();
                            switch( t ) {
                                case Token.TComma:
                                case Token.TBrClose: break;
                                default: unexpected(t, ', or }');
                            }
                        default:
                            unexpected(t, 'identifier or }');
                    }
                }
                return parseTypeNext(CTAnon(fields));
            default:
                return unexpected(t, 'identifier or [ or {');
        }
    }

    function parseTypeNext(t:CType) {
        var tk = token();
        switch( tk ) {
            case TOp(op):
                if (op != "->") {
                    push(tk);
                    return t;
                }
            default:
                push(tk);
                return t;
        }
        var t2 = parseType();
        switch( t2 ) {
            case CTFun(args, _):
                args.unshift(t);
                return t2;
            default:
                return CTFun([t], t2);
        }
    }

    function parseExprList(etk:Token):Array<Expr> {
        var args = [];
        var tk = token();
        if (tk == etk) return args;
        push(tk);
        while (true) {
            args.push(parseExpr());
            tk = token();
            switch (tk) {
                case TComma:
                default:
                    if (tk == etk) break;
                    unexpected(tk, ',');
            }
        }
        return args;
    }
}
