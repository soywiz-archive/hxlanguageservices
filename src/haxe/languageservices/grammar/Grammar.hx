package haxe.languageservices.grammar;

import haxe.languageservices.node.Node;
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
    private function opt(v:Dynamic):Term return Term.TOpt(term(v), null);
    private function optError(v:Dynamic, message:String):Term return Term.TOpt(term(v), message);
    private function list(item:Dynamic, separator:Dynamic, ?conv: Dynamic -> Dynamic):Term return Term.TList(term(item), term(separator), conv);
    private function list2(item:Dynamic, ?conv: Dynamic -> Dynamic):Term return Term.TList(term(item), null, conv);

    private function skipNonGrammar(str:Reader) {
    }

    public function parseStringNode(t:Term, str:String, file:String, ?errors:HaxeErrors):NNode<TNode> {
        var result = parseString(t, str, file, errors);
        return switch (result) {
            case Result.RUnmatched(_) | Result.RMatched: return null;
            case Result.RMatchedValue(v): return cast(v);
        }
    }

    public function parseString(t:Term, str:String, file:String, ?errors:HaxeErrors):Result return parse(t, new Reader(str, file), errors);

    public function parse(t:Term, reader:Reader, ?errors:HaxeErrors):Result {
        skipNonGrammar(reader);
        var start:Int = reader.pos;
        function gen(result:Dynamic, conv: Dynamic -> Dynamic) {
            if (result == null) return Result.RUnmatched(0);
            if (conv == null) return Result.RMatched;
            return Result.RMatchedValue(simplify(new NNode(reader.createPos(start, reader.pos), conv(result))));
        }
        switch (t) {
            case Term.TLit(lit, conv): return gen(reader.matchLit(lit), conv);
            case Term.TReg(reg, conv): return gen(reader.matchEReg(reg), conv);
            case Term.TRef(ref): return parse(ref.term, reader, errors);
            case Term.TOpt(item, error):
                switch (parse(item, reader, errors)) {
                    case Result.RMatchedValue(v): return Result.RMatchedValue(v);
                    case Result.RUnmatched(_):
                        if (errors != null && error != null) {
                            errors.add(new ParserError(reader.createPos(start, reader.pos), error));
                        }
                        return Result.RMatchedValue(null);
                    default:
                        return Result.RMatchedValue(null);
                }
            case Term.TAny(items):
                var maxValidCount = 0;
                var maxTerm = null;
                for (item in items) {
                    var r = parse(item, reader, errors);
                    switch (r) {
                        case Result.RUnmatched(validCount):
                            if (validCount > maxValidCount) {
                                maxTerm = item;
                                maxValidCount = validCount;
                            }
                        default: return r;
                    }
                }
                if (maxValidCount > 0) {
                    trace('maxValidCount:' + maxValidCount);
                    trace('maxTerm:' + maxTerm);
                    trace('ctx:' + reader.peek(20));
                }
                return Result.RUnmatched(maxValidCount);
            case Term.TSeq(items, conv):
                var results = [];
                var count = 0;
                for (item in items) {
                    var r = parse(item, reader, errors);
                    switch (r) {
                        case Result.RUnmatched(validCount):
                            reader.pos = start;
                            return Result.RUnmatched(validCount + count);
                        case Result.RMatched:
                        case Result.RMatchedValue(v):
                            results.push(v);
                    }
                    count++;
                }
                return gen(results, conv);
            case Term.TList(item, separator, conv):
                var items = [];
                var count = 0;
                while (true) {
                    var resultItem = parse(item, reader, errors);
                    switch (resultItem) {
                        case Result.RUnmatched(_): break;
                        case Result.RMatched:
                        case Result.RMatchedValue(value): items.push(value);
                    }
                    count++;
                    if (separator != null) {
                        var resultSep = parse(separator, reader, errors);
                        switch (resultSep) {
                            case Result.RUnmatched(_): break;
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
    public function locateIndex(index:Int):NNode<T> {
        return staticLocateIndex(this, index);
    }
    static public function staticLocateIndex<T>(item:Dynamic, index:Int):NNode<T> {
        if (Std.is(item, NNode)) {
            var result = staticLocateIndex(cast(item).node, index);
            if (result != null) return result;
            return item;
        }
        if (Type.getEnum(item) != null) {
            var params = Type.enumParameters(item);
            for (param in params) {
                var result = staticLocateIndex(param, index);
                if (result != null && result.pos.contains(index)) {
                    return result;
                }
            }
        }
        return null;
    }
    public function toString() return '$node@$pos';
}

enum Result {
    RMatched;
    RUnmatched(validCount:Int);
    RMatchedValue(value:NNode<Dynamic>);
}

enum Term {
    TLit(lit:String, ?conv:Dynamic -> Dynamic);
    TReg(reg:EReg, ?conv:Dynamic -> Dynamic);
    TRef(ref:TermRef);
    TAny(items:Array<Term>);
    TSeq(items:Array<Term>, ?conv: Dynamic -> Dynamic);
    TOpt(term:Term, errorMessage:String);
    TList(item:Term, separator:Term, conv:Dynamic -> Dynamic);
}

class Reader {
    private var str:String;
    public var file(default, null):String;
    public var pos:Int;

    public function new(str:String, ?file:String) {
        this.str = str;
        this.file = file;
        this.pos = 0;
    }
    
    public function createPos(start:Int, end:Int):Position {
        return new Position(start, end, file);
    }
    
    public function peek(count:Int):String {
        return str.substr(pos, count);
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
