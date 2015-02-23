package haxe.languageservices.grammar;

import haxe.languageservices.error.ParserError;
import haxe.languageservices.error.HaxeErrors;
import haxe.languageservices.node.ConstTools;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Reader;
import haxe.languageservices.node.Const;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Node;
import haxe.languageservices.grammar.Grammar;
import haxe.languageservices.grammar.GrammarTerm;

using StringTools;

class HaxeGrammar extends Grammar<Node> {
    public var ints:GrammarTerm;
    public var fqName:GrammarTerm;
    public var packageDecl:GrammarTerm;
    public var importDecl:GrammarTerm;
    public var usingDecl:GrammarTerm;
    public var expr:GrammarTerm;
    public var stm:GrammarTerm;
    public var program:GrammarTerm;
    public var stringDqLit:GrammarTerm;
    
    private function buildNode(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, v);
    }

    private function buildNode2(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, [v]);
    }
    
    private function operator(v:Dynamic):GrammarTerm return term(v, buildNode2('NOp'));
    private function optError2(tok:String) return optError(tok, 'expected $tok');
    private function litS(z:String) return GrammarTerm.TLit(z, function(v) return Node.NId(z));
    private function litK(z:String) return GrammarTerm.TLit(z, function(v) return Node.NKeyword(z));
    private function doc() return GrammarTerm.TCustomMatcher('doc', function(context:GrammarContext):Node {
        var doc = context.doc;
        context.doc = '';
        return Node.NDoc(doc);
    });

    static private var opsPriority:Map<String, Int>;

    public function new() {
        expr = createRef();
        stm = createRef();
        var type = createRef();
        var primaryExpr = createRef();

        if (opsPriority == null) {
            opsPriority = new Map();

            var oops = [
            ["%"],
            ["*", "/"],
            ["+", "-"],
            ["<<", ">>", ">>>"],
            ["|", "&", "^"],
            ["==", "!=", ">", "<", ">=", "<="],
            ["..."],
            ["&&"],
            ["||"],
            ["=","+=","-=","*=","/=","%=","<<=",">>=",">>>=","|=","&=","^="],
            ];

            for (priority in 0 ... oops.length) {
                for (i in oops[priority]) {
                    opsPriority[i] = priority;
                }
            }

            //trace(opsPriority);
        }

        
        function rlist(v) return Node.NList(v);
        //function rlist2(v) return Node.NListDummy(v);
    
        function parseString(s:String) {
            return s.substr(1, s.length - 2);
        }

        var float = GrammarTerm.TReg('float', ~/^(\d+\.\d+|\d*\.\d+|\d+\.[^\.])/, function(v) return Node.NConst(Const.CFloat(Std.parseFloat(v))));
        var int = GrammarTerm.TReg('int', ~/^\d+/, function(v) return Node.NConst(Const.CInt(Std.parseInt(v))));
        //stringDqLit = Term.TReg('string', ~/^"[^"]*"/, function(v) return Node.NConst(Const.CString(parseString(v))));

        function readEscape(errors:HaxeErrors, reader:Reader):String {
            var s2 = reader.read(1);
            switch (s2) {
                // check if octal is supported
                case '0': return String.fromCharCode(0);
                case '1': return String.fromCharCode(1);
                case '2': return String.fromCharCode(2);
                case '3': return String.fromCharCode(3);
                // check if hexadecimal is supported
                case 'x':
                    var startHex = reader.pos;
                    var hex = reader.matchEReg(~/^[0-9a-f]{2}/i);
                    if (hex != null) {
                        return String.fromCharCode(Std.parseInt('0x' + hex));
                    } else {
                        errors.add(new ParserError(reader.createPos(startHex, startHex + 2), 'Not an hex escape sequence'));
                    }
                // Unicode
                case 'u':
                    var startUnicode = reader.pos;
                    var unicode = reader.matchEReg(~/^[0-9a-f]{4}/i);
                    if (unicode != null) {
                        return String.fromCharCode(Std.parseInt('0x' + unicode));
                    } else {
                        errors.add(new ParserError(reader.createPos(startUnicode, startUnicode + 4), 'Not an unicode escape sequence'));
                    }
                case 'n': return "\n";
                case 'r': return "\r";
                case 't': return "\t";
                default: return s2;
            }
            return null;
        }

        stringDqLit = GrammarTerm.TCustomMatcher('string', function(context:GrammarContext) {
            var errors:HaxeErrors = context.errors;
            var reader:Reader = context.reader;
            var out = '';
            if (reader.matchLit('"') == null) return null;
            while (true) {
                if (reader.eof()) return null;
                var s = reader.read(1);
                switch (s) {
                    case '"': break;
                    case '\\':
                        var escape = readEscape(errors, reader);
                        if (escape != null) out += escape;
                    default: out += s;
                }
            }
            return Node.NConst(Const.CString(out));
        });
        //var stringSqLit = Term.TReg('string', ~/^'[^']*'/, function(v) return Node.NConst(Const.CString(parseString(v))));
        var identifier = GrammarTerm.TReg(
            'identifier',
            ~/^[a-zA-Z_\$]\w*/,
            function(v) return Node.NId(v),
            function(v) return !ConstTools.isKeyword(v)
            //function(v) return !ConstTools.isKeyword(v) && !ConstTools.isPredefinedConstant(v)
        );
        var stringSqDollarSimpleChunk = seq(["$", sure(), identifier], buildNode('NStringSqDollarPart'));
        var stringSqDollarExprChunk = seq(["$", "{", sure(), customSkipper(this.skipNonGrammar), expr, "}"], buildNode('NStringSqDollarPart'));
        var stringSqLiteralChunk = GrammarTerm.TCustomMatcher('literalchunk', function(context:GrammarContext) {
            var errors = context.errors;
            var reader = context.reader;
            var out = '';
            if (reader.eof()) return null;
            if (reader.peek(1) == "'") return null;
            if (reader.peek(1) == "$") return null;
            while (!reader.eof()) {
                var c = reader.read(1);
                switch (c) {
                    case '$': reader.unread(1); break;
                    case "'": reader.unread(1); break;
                    case '\\':
                        var escape = readEscape(errors, reader);
                        if (escape != null) out += escape;
                    default: out += c;
                }
            }
            //if (out.length == 0) return null;
            return Node.NConst(Const.CString(out));
        });
        var stringSqChunks = any([stringSqDollarExprChunk, stringSqDollarSimpleChunk, stringSqLiteralChunk]);
        var stringSqLit = seq(["'", customSkipper(function(context) { }), list2(stringSqChunks, 0, buildNode2('NStringParts')), "'"], buildNode('NStringSq'));

        fqName = list(identifier, '.', 1, false, function(v) return Node.NIdList(v));
        ints = list(int, ',', 1, false, function(v) return Node.NConstList(v));
        packageDecl = seq(['package', sure(), fqName, ';'], buildNode('NPackage'));
        importDecl = seq(['import', sure(), fqName, ';'], buildNode('NImport'));
        usingDecl = seq(['using', sure(), fqName, ';'], buildNode('NUsing'));
        //expr.term

        var typeList = opt(list(type, ',', 1, false, rlist));
        var typeParamItem = any([
            seq([identifier, ':', type], buildNode('NWrapper')),
            seq([identifier, ':', '(', typeList, ')'], buildNode('NWrapper')),
            identifier
        ]);
        var typeParamDecl = seq(['<', sure(), list(typeParamItem, ',', 1, false, rlist), '>'], buildNode2('NTypeParams'));

        var optType = opt(seq([':', sure(), type], buildNode('NWrapper')));


        var ifStm = seq(['if', sure(), '(', expr, ')', stm, opt(seqi(['else', stm]))], buildNode('NIf'));
        var ifExpr = seq(['if', sure(), '(', expr, ')', expr, opt(seqi(['else', expr]))], buildNode('NIf'));
        var forStm = seq(['for', sure(), '(', identifier, 'in', expr, ')', stm], buildNode('NFor'));
        var forExpr = seq(['for', sure(), '(', identifier, 'in', expr, ')', expr], buildNode('NFor'));
        var whileStm = seq(['while', sure(), '(', expr, ')', stm], buildNode('NWhile'));
        var whileExpr = seq(['while', sure(), '(', expr, ')', expr], buildNode('NWhile'));
        var doWhileStm = seq(['do', sure(), stm, 'while', '(', expr, ')', optError2(';')], buildNode('NDoWhile'));
        var breakStm = seq(['break', sure(), ';'], buildNode('NBreak'));
        var continueStm = seq(['continue', sure(), ';'], buildNode('NContinue'));
        var returnStm = seq(['return', sure(), opt(expr), ';'], buildNode('NReturn'));
        var blockStm = seq(['{', list2(stm, 0, rlist), '}'], buildNode2('NBlock'));
        var catchStm2 = seq(['catch', sure(), '(', identifier, optType, ')', stm], buildNode('NCatch'));
        var tryCatchStm = seq(['try', sure(), stm, list2(catchStm2, 1, rlist)], buildNode('NTryCatch'));
        var throwStm = seq(['throw', sure(), expr, ';'], buildNode('NThrow'));

        var switchCaseStm = seq(['case', sure(), identifier, ':'], buildNode2('NCase'));
        var switchDefaultStm = seq(['default', sure(), ':'], buildNode2('NDefault'));
        var switchStm = seq(['switch', sure(), '(', expr, ')', '{', list2(any([switchCaseStm, switchDefaultStm, stm]), 0), '}'], buildNode2('NSwitch'));
        var parenExpr = seqi(['(', sure(), expr, ')']);
        var constant = any([ float, int, stringDqLit, stringSqLit, identifier ]);

        var reqType = seq([':', sure(), type], buildNode('NWrapper'));

        var typeName = seq([identifier, optType], buildNode('NIdWithType'));
        var typeNameList = list(typeName, ',', 0, false, rlist);
        
        var typeNameReq = seq([identifier, reqType], rlist);
        var typeNameReqList = list(typeNameReq, ',', 1, false, rlist);
        
        var anonType = seq([ '{', opt(typeNameReqList), '}' ], rlist);
        var genericsType = seq([ identifier, opt(seqi(['<', type, '>'])) ], rlist);
        var baseType = any([ anonType, genericsType ]);
        
        setRef(type, any([
            list(baseType, '->', 1, false, rlist),
            baseType
        ]));
        
        var propertyDecl = seq(['(', sure(), identifier, ',', identifier, ')'], buildNode('NProperty'));
        
        var varStm = seq(['var', sure(), identifier, opt(propertyDecl), optType, opt(seqi(['=', expr])), optError(';', 'expected semicolon'), doc()], buildNode('NVar'));
        var objectItem = seq([identifier, ':', sure(), expr], buildNode('NObjectItem'));

        var castExpr = seq(['cast', sure(), '(', expr, opt(seq([',', type], rlist)), ')'], buildNode('NCast'));
        var arrayComprehensionExpr = seq(['[', any([forExpr, whileExpr]), sure(), ']'], buildNode('NArrayComprehension'));
        var arrayExpr = seq(['[', list(expr, ',', 0, true, rlist), ']'], buildNode2('NArray'));
        var objectExpr = seq(['{', list(objectItem, ',', 0, true, rlist), '}'], buildNode2('NObject'));
        var literal = any([ constant, arrayExpr, objectExpr ]);
        var unaryOp = any([operator('++'), operator('--'), operator('+'), operator('-')]);
        var binaryOp = any([for (i in ['...', '<=', '>=', '&&', '||', '==', '!=', '+', '?', ':', '-', '*', '/', '%', '<', '>', '=']) operator(i)]);

        var unaryExpr = seq([unaryOp, primaryExpr], buildNode("NUnary"));
        //var binaryExpr = seq([primaryExpr, binaryOp, expr], identity);
    
        var exprCommaList = list(expr, ',', 1, false, rlist);

        var arrayAccess = seq(['[', sure(), expr, ']'], buildNode('NArrayAccessPart'));
        var fieldAccess = seq([not('...'), '.', sure(), identifier], buildNode('NFieldAccessPart'));
        var callEmptyPart = seq(['(', ')'], buildNode('NCallPart'));
        var callPart = seq(['(', exprCommaList, ')'], buildNode('NCallPart'));
        var binaryPart = seq([binaryOp, expr], buildNode('NBinOpPart'));

        setRef(primaryExpr, any([
            castExpr,
            parenExpr,
            unaryExpr,
            seq(['new', sure(), identifier, any([callEmptyPart, callPart])], buildNode('NNew')),
            seq(
                [constant, list2(any([fieldAccess, arrayAccess, callEmptyPart, callPart, binaryPart]), 0, rlist)],
                buildNode('NAccessList')
            ),
        ]));

        setRef(expr, any([
            primaryExpr,
            arrayComprehensionExpr,
            literal,
            ifExpr,
        ]));

        setRef(stm, anyRecover([
            varStm,
            blockStm,
            tryCatchStm,
            ifStm, switchStm,
            forStm,  whileStm,  doWhileStm, breakStm,  continueStm,
            returnStm,
            throwStm,
            seq([primaryExpr, sure(), ';'], rlist)
        ], [';', '}']));


        var memberModifier = any([litK('static'), litK('public'), litK('private'), litK('override'), litK('inline')]);
        var argDecl = seq([opt(litK('?')), identifier, optType, opt(seqi(['=', expr]))], buildNode('NFunctionArg'));
        var functionDecl = seq(['function', sure(), doc(), identifier, opt(typeParamDecl), '(', opt(list(argDecl, ',', 0, false, rlist)), ')', optType, stm], buildNode('NFunction'));
        var memberDecl = seq([opt(list2(memberModifier, 0, rlist)), any([varStm, functionDecl])], buildNode('NMember'));
        var enumArgDecl = seq([opt(litK('?')), identifier, reqType, opt(seqi(['=', expr]))], buildNode('NFunctionArg'));
        var enumMemberDecl = seq([identifier, sure(), opt(seq(['(', opt(list(enumArgDecl, ',', 0, false, rlist)), ')'], buildNode('NFunctionArg'))), sure(), ';'], buildNode('NMember'));
        
        var extendsDecl = seq(['extends', sure(), fqName, opt(typeParamDecl)], buildNode('NExtends'));
        var implementsDecl = seq(['implements', sure(), fqName, opt(typeParamDecl)], buildNode('NImplements'));
        
        var extendsImplementsList = list2(any([extendsDecl, implementsDecl]), 0, rlist);
        
        var classDecl = seq(
            ['class', sure(), identifier, opt(typeParamDecl), opt(extendsImplementsList), '{', list2(memberDecl, 0, rlist), '}'],
            buildNode('NClass')
        );
        var interfaceDecl = seq(
            ['interface', sure(), identifier, opt(typeParamDecl), opt(extendsImplementsList), '{', list2(memberDecl, 0, rlist), '}'],
            buildNode('NInterface')
        );
        var typedefDecl = seq(
            ['typedef', sure(), identifier, '=', type],
            buildNode('NTypedef')
        );

        var enumDecl = seq(
            ['enum', sure(), identifier, opt(typeParamDecl), '{', list2(enumMemberDecl, 0, rlist), '}'],
            buildNode('NEnum')
        );

        var abstractDecl = seq(
            ['abstract', sure(), identifier, '{', '}'],
            buildNode('NAbstract')
        );

        var typeDecl = any([classDecl, interfaceDecl, typedefDecl, enumDecl, abstractDecl]);

        program = list2(any([packageDecl, importDecl, usingDecl, typeDecl]), 0, buildNode2('NFile'));
    }

    override private function simplify(znode:ZNode, term:GrammarTerm):ZNode {
//if (znode == null) return null;
//if (znode.node == null) return null;
        if (!Std.is(znode.node, Node)) throw 'Invalid simplify: $znode: $term : ' + znode.pos.text;
        switch (znode.node) {
//case Node.NList(items): return new ZNode(znode.pos, Node.NList([for (n in items) simplify(n, term)]));
            case Node.NWrapper(n): return simplify(n, term);
            case Node.NAccessList(node, accessors):
                switch (accessors.node) {
                    case Node.NList([]): return node;
                    case Node.NList(items):
                        var lnode = node;
                        for (item in items) {
                            var cpos = TextRange.combine(lnode.pos, item.pos);
                            switch (item.node) {
                                case Node.NArrayAccessPart(rnode):
                                    lnode = simplify(new ZNode(cpos, Node.NArrayAccess(lnode, rnode)), term);
                                case Node.NFieldAccessPart(rnode):
                                    lnode = simplify(new ZNode(cpos, Node.NFieldAccess(lnode, rnode)), term);
                                case Node.NCallPart(rnode):
                                    lnode = simplify(new ZNode(cpos, Node.NCall(lnode, rnode)), term);
                                case Node.NBinOpPart(op, rnode):
                                    var opp = NodeTools.getId(op);
                                    switch (rnode.node) {
                                        case Node.NBinOp(l, o, r):
                                            var oldPriority = opsPriority[o];
                                            var newPriority = opsPriority[opp];
                                            if (oldPriority < newPriority) {
                                                lnode = simplify(new ZNode(cpos, Node.NBinOp(lnode, opp, rnode)), term);
                                            } else {
                                                lnode = simplify(new ZNode(cpos, Node.NBinOp(new ZNode(cpos, Node.NBinOp(lnode, opp, l)), o, r)), term);
                                            }
                                        default:
                                            lnode = simplify(new ZNode(cpos, Node.NBinOp(lnode, opp, rnode)), term);
                                    }
                                default: throw 'simplify (I): $item';
                            }
                        }
                        return lnode;
                    default: throw 'simplify (II): $accessors';
                }
            default:
        }
        return znode;
    }
    
    private var spaces = ~/^\s+/;
    private var singleLineComments = ~/^\/\/(.*?)(\n|$)/;
    override private function skipNonGrammar(context:GrammarContext) {
        context.reader.matchEReg(spaces);
        var comment = context.reader.matchStartEnd('/*', '*/');
        if (comment != null) {
            if (comment.startsWith('/**')) {
                context.doc = comment.substring(3, comment.length - 2).trim();
            }
        }
        context.reader.matchEReg(spaces);
        context.reader.matchEReg(singleLineComments);
        context.reader.matchEReg(spaces);
    }
}
