package haxe.languageservices.grammar;

import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Reader;
import haxe.languageservices.node.Const;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Node;
import haxe.languageservices.grammar.Grammar;
import haxe.languageservices.grammar.Grammar.Term;

class HaxeGrammar extends Grammar<Node> {
    public var ints:Term;
    public var fqName:Term;
    public var packageDecl:Term;
    public var importDecl:Term;
    public var usingDecl:Term;
    public var expr:Term;
    public var stm:Term;
    public var program:Term;
    
    private function buildNode(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, v);
    }

    private function buildNode2(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, [v]);
    }
    
    /*
    private function accessList(items:Array<ZNode>):Array<ZNode> {
        switch (znode.node) {
            case Node.NList(items): return items;
            case Node.NList(items): return items;
        }
    }
    */
    
    override private function simplify(znode:ZNode, term:Term):ZNode {
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
                            var lpos = Position.combine(lnode.pos, item.pos);
                            switch (item.node) {
                                case Node.NCallPart(rnode):
                                    lnode = simplify(new ZNode(lpos, Node.NCall(lnode, rnode)), term);
                                case Node.NBinOpPart(op, rnode):
                                    var opp = NodeTools.getId(op);
                                    switch (rnode.node) {
                                        case Node.NBinOp(l, o, r):
                                            var oldPriority = opsPriority[o];
                                            var newPriority = opsPriority[opp];
                                            if (oldPriority < newPriority) {
                                                //trace('[1]');
                                                lnode = simplify(new ZNode(lpos, Node.NBinOp(lnode, opp, rnode)), term);
                                            } else {
                                                //trace('[2] $l :::: $r :::: $lnode');
                                                lnode = simplify(new ZNode(lpos, Node.NBinOp(new ZNode(lpos, Node.NBinOp(lnode, opp, l)), opp, r)), term);
                                            }
                                        default:
                                            //trace('[3]: $lnode ||| $opp ||| $rnode');
                                            lnode = simplify(new ZNode(lpos, Node.NBinOp(lnode, opp, rnode)), term);
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
    
    private function operator(v:Dynamic):Term return term(v, buildNode2('NOp'));
    private function optError2(tok:String) return optError(tok, 'expected $tok');
    private function litS(z:String) return Term.TLit(z, function(v) return Node.NId(z));
    private function litK(z:String) return Term.TLit(z, function(v) return Node.NKeyword(z));
    
    static private var opsPriority:Map<String, Int>;

    public function new() {
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


        var int = Term.TReg('int', ~/^\d+/, function(v) return Node.NConst(Const.CInt(Std.parseInt(v))));
        var identifier = Term.TReg('identifier', ~/^[a-zA-Z]\w*/, function(v) return Node.NId(v));
        fqName = list(identifier, '.', 1, false, function(v) return Node.NIdList(v));
        ints = list(int, ',', 1, false, function(v) return Node.NConstList(v));
        packageDecl = seq(['package', sure(), fqName, ';'], buildNode('NPackage'));
        importDecl = seq(['import', sure(), fqName, ';'], buildNode('NImport'));
        usingDecl = seq(['using', sure(), fqName, ';'], buildNode('NUsing'));
        expr = createRef();
        stm = createRef();
        //expr.term
        var ifStm = seq(['if', sure(), '(', expr, ')', stm, opt(seqi(['else', stm]))], buildNode('NIf'));
        var forStm = seq(['for', sure(), '(', identifier, 'in', expr, ')', stm], buildNode('NFor'));
        var whileStm = seq(['while', sure(), '(', expr, ')', stm], buildNode('NWhile'));
        var doWhileStm = seq(['do', sure(), stm, 'while', '(', expr, ')', optError2(';')], buildNode('NDoWhile'));
        var breakStm = seq(['break', sure(), ';'], buildNode('NBreak'));
        var continueStm = seq(['continue', sure(), ';'], buildNode('NContinue'));
        var returnStm = seq(['return', sure(), opt(expr), ';'], buildNode('NReturn'));
        var blockStm = seq(['{', list2(stm, 0, rlist), '}'], buildNode2('NBlock'));

        var switchCaseStm = seq(['case', sure(), identifier, ':'], buildNode2('NCase'));
        var switchDefaultStm = seq(['default', sure(), ':'], buildNode2('NDefault'));
        var switchStm = seq(['switch', sure(), '(', expr, ')', '{', list2(any([switchCaseStm, switchDefaultStm, stm]), 0), '}'], buildNode2('NSwitch'));
        var parenExpr = seqi(['(', sure(), expr, ')']);
        var constant = any([ int, identifier ]);
        var type = createRef();
        var typeParamItem = type;
        var typeParamDecl = seq(['<', sure(), list(typeParamItem, ',', 1, false, rlist), '>'], buildNode2('NTypeParams'));

        var optType = opt(seq([':', sure(), type], buildNode('NWrapper')));

        var typeName = seq([identifier, optType], buildNode('NIdWithType'));
        var typeNameList = list(typeName, ',', 0, false, rlist);
        
        var typeBase = seq([identifier, opt(typeParamDecl)], rlist);
        
        setRef(type, any([
            list(typeBase, '->', 1, false, rlist),
            seq([ '{', typeNameList, '}' ], rlist),
        ]));
        
        var propertyDecl = seq(['(', sure(), identifier, ',', identifier, ')'], buildNode('NProperty'));
        
        var varStm = seq(['var', sure(), identifier, opt(propertyDecl), optType, opt(seqi(['=', expr])), optError(';', 'expected semicolon')], buildNode('NVar'));
        var objectItem = seq([identifier, ':', sure(), expr], buildNode('NObjectItem'));

        var arrayExpr = seq(['[', list(expr, ',', 0, true, rlist), ']'], buildNode2('NArray'));
        var objectExpr = seq(['{', list(objectItem, ',', 0, true, rlist), '}'], buildNode2('NObject'));
        var literal = any([ constant, arrayExpr, objectExpr ]);
        var unaryOp = any([operator('++'), operator('--'), operator('+'), operator('-')]);
        var binaryOp = any([for (i in ['...', '<=', '>=', '&&', '||', '==', '!=', '+', '?', ':', '-', '*', '/', '%', '<', '>', '=']) operator(i)]);
        var primaryExpr = createRef();
        
        var unaryExpr = seq([unaryOp, primaryExpr], buildNode("NUnary"));
        //var binaryExpr = seq([primaryExpr, binaryOp, expr], identity);
    
        var exprCommaList = list(expr, ',', 1, false, rlist);

        var arrayAccess = seq(['[', expr, ']'], buildNode('NAccessPart'));
        var fieldAccess = seq(['.', identifier], buildNode('NAccessPart'));
        var callPart = seq(['(', exprCommaList, ')'], buildNode('NCallPart'));
        var binaryPart = seq([binaryOp, expr], buildNode('NBinOpPart'));

        setRef(primaryExpr, any([
            parenExpr,
            unaryExpr,
            seq(['new', sure(), identifier, callPart], buildNode('NNew')),
            seq(
                [constant, list2(any([fieldAccess, arrayAccess, callPart, binaryPart]), 0, rlist)],
                buildNode('NAccessList')
            ),
        ]));

        setRef(expr, any([
            primaryExpr,
            literal,
        ]));

        setRef(stm, anyRecover([
            varStm,
            blockStm,
            ifStm, switchStm,
            forStm,  whileStm,  doWhileStm, breakStm,  continueStm,
            returnStm,
            seq([primaryExpr, sure(), ';'], rlist)
        ], [';', '}']));


        var memberModifier = any([litK('static'), litK('public'), litK('private'), litK('override'), litK('inline')]);
        var argDecl = seq([opt(litK('?')), identifier, optType, opt(seqi(['=', expr]))], buildNode('NFunctionArg'));
        var functionDecl = seq(['function', sure(), identifier, '(', opt(list(argDecl, ',', 0, false, rlist)), ')', optType, stm], buildNode('NFunction'));
        var memberDecl = seq([opt(list2(memberModifier, 0, rlist)), any([varStm, functionDecl])], buildNode('NMember'));
        
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
            ['enum', sure(), identifier, '{', '}'],
            buildNode('NEnum')
        );

        var abstractDecl = seq(
            ['abstract', sure(), identifier, '{', '}'],
            buildNode('NAbstract')
        );

        var typeDecl = any([classDecl, interfaceDecl, typedefDecl, enumDecl, abstractDecl]);

        program = list2(any([packageDecl, importDecl, usingDecl, typeDecl]), 0, buildNode2('NFile'));
    }

    private var spaces = ~/^\s+/;
    private var singleLineComments = ~/^\/\/(.*?)(\n|$)/;
    override private function skipNonGrammar(str:Reader) {
        str.matchEReg(spaces);
        str.matchStartEnd('/*', '*/');
        str.matchEReg(spaces);
        str.matchEReg(singleLineComments);
        str.matchEReg(spaces);
    }
}
