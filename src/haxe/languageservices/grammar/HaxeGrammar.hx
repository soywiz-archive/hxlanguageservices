package haxe.languageservices.grammar;

import haxe.languageservices.grammar.Grammar;
import haxe.languageservices.grammar.Grammar.Term;
import haxe.languageservices.grammar.Grammar.Reader;

class HaxeGrammar extends Grammar<Node> {
    public var ints:Term;
    public var fqName:Term;
    public var packageDesc:Term;
    public var expr:Term;

    public function new() {
        var int = TReg(~/^\d+/, function(v) return Node.NConst(Const.CInt(Std.parseInt(v))));
        var identifier = TReg(~/^[a-zA-Z]\w*/, function(v) return Node.NId(v));
        var comma = TLit(',');
        var dot = TLit('.');
        fqName = TList(identifier, dot, function(v) return Node.NIdList(v));
        ints = TList(int, comma, function(v) return Node.NConstList(v));
        packageDesc = TSeq([TLit('package'), fqName, TLit(';')], function(v) return Node.NPackage(v[0]));
        var _expr = new TermRef();
        expr = TRef(_expr);
        //expr.term
        var ifExpr = TSeq([TLit('if'), TLit('('), expr, TLit(')'), expr], function (v) return Node.NIf(v[0], v[1]));
        var constant = TAny([ int, identifier ]);
        _expr.term = TAny([ ifExpr, constant ]);
        var intOrId = TAny([int, identifier]);
    }

    private var spaces = ~/^\s+/;
    override private function skipNonGrammar(str:Reader) {
        str.matchEReg(spaces);
    }
}

enum Const {
    CInt(value:Int);
}

enum Node {
    NId(value:String);
    NConst(value:Dynamic);
    NIdList(value:Array<NNode<Node>>);
    NConstList(items:Array<NNode<Node>>);
    NPackage(fqName:Node);
    NIf(cond:Node, result:Node);
}

