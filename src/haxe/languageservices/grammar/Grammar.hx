package haxe.languageservices.grammar;

import haxe.languageservices.node.Position;
class Grammar<TNode> {
    private function term(z:Dynamic, ?conv: Dynamic -> Dynamic):Term {
        if (Std.is(z, String)) return Term.TLit(cast(z, String), conv);
        if (Std.is(z, EReg)) return Term.TReg(cast(z, EReg), conv);
        if (Std.is(z, TermRef)) return Term.TRef(z);
        return cast(z, Term);
    }
    private function _term(z:Dynamic):Term return term(z);
    
    private function createRef():Term return Term.TRef(new TermRef());
    private function setRef(ref:Term, value:Term) {
        switch (ref) {
            case Term.TRef(t): t.term = value;
            default: throw "Invalid ref";
        }
    }

    private function simplify(znode:NNode<TNode>):NNode<TNode> {
        return znode;
    }

    private function identity(v) return v;
    private function seq(v:Array<Dynamic>, conv: Dynamic -> Dynamic):Term return Term.TSeq(v.map(_term), conv);
    private function seqi(v:Array<Dynamic>):Term return seq(v, function(v) return v[0]);
    private function any(v:Array<Dynamic>):Term return Term.TAny(v.map(_term));
    private function opt(v:Dynamic):Term return Term.TOpt(term(v));
    private function list(item:Dynamic, separator:Dynamic, ?conv: Dynamic -> Dynamic):Term return Term.TList(term(item), term(separator), conv);
    private function list2(item:Dynamic, ?conv: Dynamic -> Dynamic):Term return Term.TList(term(item), null, conv);

    private function skipNonGrammar(str:Reader) {
    }

    public function parseString(t:Term, str:String):Result return parse(t, new Reader(str));

    public function parse(t:Term, reader:Reader):Result {
        skipNonGrammar(reader);
        var start:Int = reader.pos;
        function gen(result:Dynamic, conv: Dynamic -> Dynamic) {
            if (result == null) return Result.RUnmatched;
            if (conv == null) return Result.RMatched;
            return Result.RMatchedValue(simplify(new NNode(new Position(start, reader.pos), conv(result))));
        }
        switch (t) {
            case Term.TLit(lit, conv): return gen(reader.matchLit(lit), conv);
            case Term.TReg(reg, conv): return gen(reader.matchEReg(reg), conv);
            case Term.TRef(ref): return parse(ref.term, reader);
            case Term.TOpt(item):
                return switch (parse(item, reader)) {
                    case Result.RMatchedValue(v): Result.RMatchedValue(v);
                    default: Result.RMatchedValue(null);
                }
            case Term.TAny(items):
                for (item in items) {
                    var r = parse(item, reader);
                    switch (r) {
                        case Result.RUnmatched:
                        default: return r;
                    }
                }
                return Result.RUnmatched;
            case Term.TSeq(items, conv):
                var results = [];
                for (item in items) {
                    var r = parse(item, reader);
                    switch (r) {
                        case Result.RUnmatched:
                            reader.pos = start;
                            return Result.RUnmatched;
                        case Result.RMatched:
                        case Result.RMatchedValue(v):
                            results.push(v);
                    }
                }
                return gen(results, conv);
            case Term.TList(item, separator, conv):
                var items = [];
                while (true) {
                    var resultItem = parse(item, reader);
                    switch (resultItem) {
                        case Result.RUnmatched: break;
                        case Result.RMatched:
                        case Result.RMatchedValue(value): items.push(value);
                    }
                    if (separator != null) {
                        var resultSep = parse(separator, reader);
                        switch (resultItem) {
                            case Result.RUnmatched: break;
                            default:
                        }
                    }
                }
                return gen(items, conv);
            default:
                throw 'Unmatched $t';
        }
    }
}

class TermRef { public var term:Term; public function new() { } }

class NNode<T> {
    public var pos:Position;
    public var node:T;
    public function new(pos:Position, node:T) { this.pos = pos; this.node = node; }
    public function toString() return '$node@$pos';
}

enum Result {
    RMatched;
    RUnmatched;
    RMatchedValue(value:NNode<Dynamic>);
}

enum Term {
    TLit(lit:String, ?conv:Dynamic -> Dynamic);
    TReg(reg:EReg, ?conv:Dynamic -> Dynamic);
    TRef(ref:TermRef);
    TAny(items:Array<Term>);
    TSeq(items:Array<Term>, ?conv: Dynamic -> Dynamic);
    TOpt(term:Term);
    TList(item:Term, separator:Term, conv:Dynamic -> Dynamic);
}

class Reader {
    private var str:String;
    public var pos:Int;

    public function new(str:String) {
        this.str = str;
        this.pos = 0;
    }
    
    public function matchLit(lit:String) {
        if (str.substr(pos, lit.length) != lit) return null;
        pos += lit.length;
        return lit;
    }

    public function matchEReg(v:EReg) {
        if (!v.match(str.substr(pos))) return null;
        var m = v.matched(0);
        pos += m.length;
        return m;
    }
}
