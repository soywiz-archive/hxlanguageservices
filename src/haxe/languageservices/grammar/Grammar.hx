package haxe.languageservices.grammar;

import haxe.languageservices.node.Reader;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.Position;
class Grammar<TNode> {
    private function term(z:Dynamic, ?conv: Dynamic -> Dynamic):Term {
        if (Std.is(z, String)) return Term.TLit(cast(z, String), conv);
        if (Std.is(z, EReg)) {
            throw 'unsupported $z';
            //return Term.TReg(cast(z, EReg), conv);
        }
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

    private function simplify(znode:NNode<TNode>, term:Term):NNode<TNode> {
        return znode;
    }

    private function identity(v) return v;
    private function sure():Term return Term.TSure;
    private function seq(v:Array<Dynamic>, conv: Dynamic -> Dynamic):Term return Term.TSeq(v.map(_term), conv);
    private function seqi(v:Array<Dynamic>):Term return seq(v, function(v) return v[0]);
    private function any(v:Array<Dynamic>):Term return Term.TAny(v.map(_term), null);
    private function anyRecover(v:Array<Dynamic>, recover:Array<Dynamic>):Term return Term.TAny(v.map(_term), recover.map(_term));
    private function opt(v:Dynamic):Term return Term.TOpt(term(v), null);
    private function optError(v:Dynamic, message:String):Term return Term.TOpt(term(v), message);
    private function list(item:Dynamic, separator:Dynamic, minCount:Int, allowExtraSeparator:Bool, ?conv: Dynamic -> Dynamic):Term return Term.TList(term(item), term(separator), minCount, allowExtraSeparator, conv);
    private function list2(item:Dynamic, minCount:Int, ?conv: Dynamic -> Dynamic):Term return Term.TList(term(item), null, minCount, true, conv);

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
    
    private function describe(t:Term):String {
        switch (t) {
            case Term.TLit(lit, _): return '"$lit"';
            case Term.TReg(name, _, _, _): return '$name';
            case Term.TCustomMatcher(name, _): return '$name';
            case Term.TRef(ref): return describe(ref.term);
            case Term.TOpt(item, _): return describe(item);
            case Term.TSeq(items, _): return describe(items[0]);
            case Term.TList(item, _, _, _, _): return describe(item);
            case Term.TAny(items, _): return [for (item in items) describe(item)].join(' or ');
            default: return '???';
        }
    }
    
    public function parse(t:Term, reader:Reader, ?errors:HaxeErrors):Result {
        if (errors == null) errors = new HaxeErrors();
        var result = _parse(t, reader, errors);
        if (!reader.eof()) {
            errors.add(new ParserError(reader.createPos(), 'unexpected end of file'));
        }
        return result;
    }

    private function _parse(t:Term, reader:Reader, errors:HaxeErrors):Result {
        skipNonGrammar(reader);
        var start:Int = reader.pos;
        function gen(result:Dynamic, conv: Dynamic -> Dynamic) {
            if (result == null) return Result.RUnmatched(0, start);
            if (conv == null) return Result.RMatched;
            var rresult:Dynamic = conv(result);
            if (Std.is(rresult, NNode)) {
                //rresult = new NNode(Position.combine(rresult.pos, result.pos), rresult.node);
                return Result.RMatchedValue(simplify(rresult, t));
            }
            return Result.RMatchedValue(simplify(new NNode(reader.createPos(start, reader.pos), rresult), t));
        }
        switch (t) {
            case Term.TLit(lit, conv): return gen(reader.matchLit(lit), conv);
            case Term.TReg(name, reg, conv, checker):
                var res = reader.matchEReg(reg);
                if (checker != null) {
                    if (!checker(res)) {
                        //reader.pos = start;
                        //errors.add(new ParserError(reader.createPos(start, reader.pos), 'identifier ' + res + ' is a keyword'));
                        //return Result.RUnmatched(0, start);
                    }
                }
                return gen(res, conv);
            case Term.TCustomMatcher(name, matcher):
                var result = matcher(reader);
                if (result == null) return Result.RUnmatched(0, start);
                var resultnode = new NNode(reader.createPos(start, reader.pos), result);
                return Result.RMatchedValue(simplify(resultnode, t));
            case Term.TRef(ref): return _parse(ref.term, reader, errors);
            case Term.TOpt(item, error):
                switch (_parse(item, reader, errors)) {
                    case Result.RMatchedValue(v): return Result.RMatchedValue(v);
                    case Result.RUnmatched(_, _):
                        if (error != null) {
                            errors.add(new ParserError(reader.createPos(start, reader.pos), error));
                        }
                        return Result.RMatchedValue(null);
                    default:
                        return Result.RMatchedValue(null);
                }
            case Term.TAny(items, recover):
                var maxValidCount = 0;
                var maxValidPos = start;
                var maxTerm = null;
                for (item in items) {
                    var r = _parse(item, reader, errors);
                    switch (r) {
                        case Result.RUnmatched(validCount, lastPos):
                            if (validCount > maxValidCount) {
                                maxTerm = item;
                                maxValidCount = validCount;
                                maxValidPos = lastPos;
                            }
                        default: return r;
                    }
                }
                /*
                if (recover != null) {
                    while (!reader.eof()) {
                        for (item in recover) {
                            var r = _parse(item, reader, errors);
                            switch (r) {
                                case Result.RMatched | Result.RMatchedValue(_):
                                    return Result.RUnmatched(maxValidCount, maxValidPos);
                                default:
                            }
                        }
                        reader.skip(1);
                    }
                }
                */
                if (maxValidCount > 0) {
                    //trace('maxValidCount:' + maxValidCount);
                    //trace('maxValidPos:' + maxValidPos);
                    //trace('maxTerm:' + maxTerm);
                    //trace('ctx:' + reader.peek(20));
                }
                return Result.RUnmatched(maxValidCount, maxValidPos);
            case Term.TSeq(items, conv):
                var results = [];
                var count = 0;
                var sure = false;
                var lastItemIndex = reader.pos;
                for (item in items) {
                    if (Type.enumEq(item, Term.TSure)) {
                        sure = true;
                        continue;
                    }
                    var itemIndex = reader.pos;
                    var r = _parse(item, reader, errors);
                    switch (r) {
                        case Result.RUnmatched(validCount, lastPos):
                            if (sure) {
                                errors.add(new ParserError(reader.createPos(lastItemIndex, lastItemIndex), 'expected ' + describe(item)));
                                reader.pos = lastPos;
                                break;
                            } else {
                                reader.pos = start;
                                return Result.RUnmatched(validCount + count, lastPos);
                            }
                        case Result.RMatched:
                        case Result.RMatchedValue(v):
                            results.push(v);
                            if (v != null) lastItemIndex = v.pos.max;
                    }
                    
                    count++;
                }
                //trace('aaaa');
                return gen(results, conv);
            case Term.TList(item, separator, minCount, allowExtraSeparator, conv):
                var items = [];
                var count = 0;
                var separatorCount = 0;
                var lastSeparatorPos = reader.createPos(start, start);
                while (true) {
                    var resultItem = _parse(item, reader, errors);
                    switch (resultItem) {
                        case Result.RUnmatched(_):
                            break;
                        case Result.RMatched:
                        case Result.RMatchedValue(value): items.push(value);
                    }
                    count++;
                    if (separator != null) {
                        var rpos = reader.pos;
                        var resultSep = _parse(separator, reader, errors);
                        switch (resultSep) {
                            case Result.RUnmatched(_): break;
                            default:
                                lastSeparatorPos = reader.createPos(rpos, reader.pos);
                        }
                        separatorCount++;
                    }
                }
                
                var unmatched = false;
                if (count < minCount) unmatched = true;
                if (!allowExtraSeparator) {
                    if (separatorCount >= count) {
                        if (separator != null && count > 0) {
                            errors.add(new ParserError(lastSeparatorPos, 'unexpected ' + lastSeparatorPos.text));
                        } else {
                            unmatched = true;
                        }
                    }
                    //trace(count + ':' + separatorCount);
                }
                
                if (unmatched) {
                    var lastPos = reader.pos;
                    //reader.pos = start;
                    return Result.RUnmatched(count, lastPos);
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
        if (Std.is(item, Array)) {
            //throw 'IS ARRAY!';
            var array = Std.instance(item, Array);
            for (item in array) {
                var result = staticLocateIndex(item, index);
                if (result != null && result.pos.contains(index)) {
                    return result;
                }
            }
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
    static public function isValid<T>(node:NNode<T>):Bool {
        return node != null && node.node != null;
    }
    public function toString() return '$node@$pos';
}

enum Result {
    RMatched;
    RUnmatched(validCount:Int, lastPos:Int);
    RMatchedValue(value:NNode<Dynamic>);
}

enum Term {
    TLit(lit:String, ?conv:Dynamic -> Dynamic);
    TReg(name:String, reg:EReg, ?conv:Dynamic -> Dynamic, ?checker: String -> Bool);
    TCustomMatcher(name:String, matcher: Reader -> Dynamic);
    TRef(ref:TermRef);
    TAny(items:Array<Term>, recover:Array<Term>);
    TSure;
    TSeq(items:Array<Term>, ?conv: Dynamic -> Dynamic);
    TOpt(term:Term, errorMessage:String);
    TList(item:Term, separator:Term, minCount:Int, allowExtraSeparator:Bool, conv:Dynamic -> Dynamic);
}


