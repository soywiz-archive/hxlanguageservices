package hscript;
import hscript.Expr;

import hscript.Tokenizer.Token;

class Parser {

// config / variables
    public var opPriority:Map<String, Int>;
    public var opRightAssoc:Map<String, Bool>;
    public var unops:Map<String, Bool>; // true if allow postfix

// implementation
    var uid:Int = 0;
    private var tokenizer:Tokenizer;
    private var completion = new CompletionContext();

    public function new() {
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

    public function parseString(s:String) {
        uid = 0;
        return parse(new haxe.io.StringInput(s));
    }

    public function parse(s:haxe.io.Input) {
        tokenizer = new Tokenizer(s);
        var a = new Array();
        while (true) {
            var tk = token();
            if (tk == TEof) break;
            push(tk);
            a.push(parseFullExpr());
        }
        return if (a.length == 1) a[0] else mk(EBlock(a), 0);
    }

    function unexpected(tk:Token):Dynamic {
        tokenizer.error(EUnexpected(tokenizer.tokenString(tk)), tokenizer.tokenMin, tokenizer.tokenMax);
        return null;
    }

    private function push(t:Token) return tokenizer.push(t);

    private function token() return tokenizer.token();

    inline function ensure(tk) {
        var t = token();
        if (t != tk) unexpected(t);
    }

    inline function expr(e:Expr) return e.e;

    inline function pmin(e:Expr) return e.pmin;

    inline function pmax(e:Expr) return e.pmax;

    inline function mk(e, ?pmin, ?pmax):Expr {
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
            if (isBlock(e)) push(tk); else unexpected(tk);
        }
        return e;
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
                        default: unexpected(tk);
                    }
                case TBrClose: break;
                default: unexpected(tk);
            }
            ensure(TDoubleDot);
            fl.push({ name : id, e : parseExpr() });
            tk = token();
            switch( tk ) {
                case TBrClose: break;
                case TComma:
                default: unexpected(tk);
            }
        }
        return parseExprNext(mk(EObject(fl), p1));
    }

    function parseExpr() {
        var tk = token();
        var p1 = tokenizer.tokenMin;
        switch( tk ) {
            case TId(id):
                var e = parseStructure(id);
                if (e == null) {
                    e = mk(EIdent(id));
                    completion.getLocal(id).addReference(Reference.Read(e));
                }
                return parseExprNext(e);
            case TConst(c): return parseExprNext(mk(EConst(c)));
            case Token.TPOpen:
                var e = parseExpr();
                ensure(TPClose);
                return parseExprNext(mk(EParent(e), p1, tokenizer.tokenMax));
            case TBrOpen:
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
                while (true) {
                    a.push(parseFullExpr());
                    tk = token();
                    if (tk == TBrClose)
                        break;
                    push(tk);
                }
                return mk(EBlock(a), p1);
            case TOp(op):
                if (unops.exists(op)) return makeUnop(op, parseExpr());
                return unexpected(tk);
            case TBkOpen:
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
                return unexpected(tk);
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

    function parseStructure(id) {
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
                var tk = token();
                var ident:String = null;
                switch(tk) {
                    case Token.TId(id): ident = id;
                    default: unexpected(tk);
                }
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
                completion.addLocal(ident, t, e);
                mk(EVar(ident, t, e), p1, (e == null) ? tokenizer.tokenMax : pmax(e));
            case "while":
                var econd = parseExpr();
                var e = parseExpr();
                mk(EWhile(econd, e), p1, pmax(e));
            case "for":
                ensure(TPOpen);
                var tk = token();
                var vname = null;
                switch( tk ) {
                    case TId(id): vname = id;
                    default: unexpected(tk);
                }
                tk = token();
                if (!Type.enumEq(tk, TId("in"))) unexpected(tk);
                var eiter = parseExpr();
                ensure(TPClose);
                var e = parseExpr();
                mk(EFor(vname, eiter, e), p1, pmax(e));
            case "break": mk(EBreak);
            case "continue": mk(EContinue);
            case "else": unexpected(TId(id));
            case "function":
                var tk = token();
                var name = null;
                switch( tk ) {
                    case TId(id): name = id;
                    default: push(tk);
                }
                ensure(TPOpen);
                var args = new Array();
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
                            default: unexpected(tk);
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
                            case TComma: tk = token();
                            case TPClose: done = true;
                            default: unexpected(tk);
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
                var body = parseExpr();
                var expr = mk(EFunction(args, body, name, ret), p1, pmax(body));
                completion.addLocal(name, ret, expr);
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
                    default: unexpected(tk);
                }
                var next = true;
                while (next) {
                    tk = token();
                    switch( tk ) {
                        case TDot:
                            tk = token();
                            switch(tk) {
                                case TId(id): a.push(id);
                                default: unexpected(tk);
                            }
                        case TPOpen:
                            next = false;
                        default:
                            unexpected(tk);
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
                if (!Type.enumEq(tk, TId("catch"))) unexpected(tk);
                ensure(TPOpen);
                tk = token();
                var vname = switch( tk ) {
                    case TId(id): id;
                    default: unexpected(tk);
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
                                        unexpected(tk);
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
                            if (def != null) unexpected(tk);
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
                            unexpected(tk);
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
                switch(tk) {
                    case TId(id): field = id;
                    default: unexpected(tk);
                }
                trace('Completion at dot:' + completion.getType(e1));
                return parseExprNext(mk(EField(e1, field), pmin(e1)));
            case TPOpen:
                return parseExprNext(mk(ECall(e1, parseExprList(TPClose)), pmin(e1)));
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
                            unexpected(t);
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
                                unexpected(t);
                            }
                        } else
                            push(t);
                    default:
                        push(t);
                }
                return parseTypeNext(CTPath(path, params));
            case TPOpen:
                var t = parseType();
                ensure(TPClose);
                return parseTypeNext(CTParent(t));
            case TBrOpen:
                var fields = [];
                while (true) {
                    t = token();
                    switch( t ) {
                        case TBrClose: break;
                        case TId(name):
                            ensure(TDoubleDot);
                            fields.push({ name : name, t : parseType() });
                            t = token();
                            switch( t ) {
                                case TComma:
                                case TBrClose: break;
                                default: unexpected(t);
                            }
                        default:
                            unexpected(t);
                    }
                }
                return parseTypeNext(CTAnon(fields));
            default:
                return unexpected(t);
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

    function parseExprList(etk) {
        var args = [];
        var tk = token();
        if (tk == etk) return args;
        push(tk);
        while (true) {
            args.push(parseExpr());
            tk = token();
            switch( tk ) {
                case TComma:
                default:
                    if (tk == etk) break;
                    unexpected(tk);
            }
        }
        return args;
    }
}

class CompletionVariable {
    public var name:String;
    public var expr:Expr;
    public var references:Array<Reference> = [];

    public function new(name:String, expr:Expr) {
        this.name = name;
        this.expr = expr;
    }

    public function addReference(ref:Reference):Void {
        references.push(ref);
        trace('reference $name $ref');
    }
}

enum Reference {
    Declaration(e:Expr);
    Write(e:Expr);
    Read(e:Expr);
}

enum CompletionType {
    Unknown;
    Dynamic;
    Int;
    Float;
    String;
    Object(items:Array<{ name:String, type:CompletionType }>);
    Array(type:CompletionType);
    Function(args:Array<CompletionType>, ret:CompletionType);
}

class CompletionContext {
    var locals = new Map<String, CompletionVariable>();

    public function new() {
    }

    public function getLocal(name:String):CompletionVariable {
        if (!locals.exists(name)) throw 'Can\'t find local "$name"';
        return locals.get(name);
    }

    public function unificateTypes(types:Array<CompletionType>):CompletionType {
        if (types.length == 0) return CompletionType.Dynamic;
        return types[0];
    }

    public function getType(e:Expr):CompletionType {
        switch (e.e) {
            case ExprDef.EIdent(v):
                return getType(getLocal(v).expr);
            case ExprDef.EConst(CInt(_)): return CompletionType.Int;
            case ExprDef.EConst(CString(_)): return CompletionType.String;
            case ExprDef.EBlock(exprs):
                return getType(exprs[exprs.length - 1]);
            case ExprDef.EReturn(e):
                return getType(e);
            case ExprDef.EFunction(args, e, name, ret):
                return CompletionType.Function(
                    [for (arg in args) CompletionType.Unknown],
                    getType(e)
                );
            case ExprDef.ECall(e, params):
                var type = getType(e);
                switch (getType(e)) {
                    case CompletionType.Function(args, ret): return ret;
                    case CompletionType.Dynamic: return CompletionType.Dynamic;
                    default:
                }
                return CompletionType.Unknown;
            case ExprDef.EArrayDecl(exprs):
                return CompletionType.Array(unificateTypes([for (expr in exprs) getType(expr)]));
            case ExprDef.EObject(parts):
                return CompletionType.Object([for (part in parts) { name: part.name, type: getType(part.e) } ]);
            default:
                throw 'Unhandled expression ${e.e}';
        }
        trace(e);
        return CompletionType.Unknown;
    }

    public function addLocal(ident:String, t:CType, e:Expr):CompletionVariable {
        var v = new CompletionVariable(ident, e);
        v.addReference(Reference.Declaration(e));
        locals.set(ident, v);
        return v;
    }
}

