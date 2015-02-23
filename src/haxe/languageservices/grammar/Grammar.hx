package haxe.languageservices.grammar;

import haxe.languageservices.error.ParserError;
import haxe.languageservices.error.HaxeErrors;
import haxe.languageservices.node.Reader;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.TextRange;

class Grammar<TNode> {
    private function term(z:Dynamic, ?conv: Dynamic -> Dynamic):GrammarTerm {
        if (Std.is(z, String)) return GrammarTerm.TLit(cast(z, String), conv);
        if (Std.is(z, EReg)) {
            throw 'unsupported $z';
            //return Term.TReg(cast(z, EReg), conv);
        }
        if (Std.is(z, GrammarTermRef)) return GrammarTerm.TRef(z);
        return cast(z, GrammarTerm);
    }

    private function _term(z:Dynamic):GrammarTerm return term(z);
    
    private function createRef():GrammarTerm return GrammarTerm.TRef(new GrammarTermRef());
    private function setRef(ref:GrammarTerm, value:GrammarTerm) {
        switch (ref) {
            case GrammarTerm.TRef(t): t.term = value;
            default: throw "Invalid ref";
        }
    }

    private function simplify(znode:GrammarNode<TNode>, term:GrammarTerm):GrammarNode<TNode> {
        return znode;
    }

    private function identity(v) return v;
    private function sure():GrammarTerm return GrammarTerm.TSure;
    private function seq(v:Array<Dynamic>, conv: Dynamic -> Dynamic):GrammarTerm return GrammarTerm.TSeq(v.map(_term), conv);
    private function seqi(v:Array<Dynamic>):GrammarTerm return seq(v, function(v) return v[0]);
    private function any(v:Array<Dynamic>):GrammarTerm return GrammarTerm.TAny(v.map(_term), null);
    private function anyRecover(v:Array<Dynamic>, recover:Array<Dynamic>):GrammarTerm return GrammarTerm.TAny(v.map(_term), recover.map(_term));
    private function opt(v:Dynamic):GrammarTerm return GrammarTerm.TOpt(term(v), null);
    private function optError(v:Dynamic, message:String):GrammarTerm return GrammarTerm.TOpt(term(v), message);
    private function list(item:Dynamic, separator:Dynamic, minCount:Int, allowExtraSeparator:Bool, ?conv: Dynamic -> Dynamic):GrammarTerm return GrammarTerm.TList(term(item), term(separator), minCount, allowExtraSeparator, conv);
    private function list2(item:Dynamic, minCount:Int, ?conv: Dynamic -> Dynamic):GrammarTerm return GrammarTerm.TList(term(item), null, minCount, true, conv);

    private function customSkipper(handler: GrammarContext -> Void) {
        return GrammarTerm.TCustomSkipper(handler);
    }

    private function not(v:Dynamic):GrammarTerm return GrammarTerm.TNot(term(v));
    
    private function skipNonGrammar(context:GrammarContext) {
    }

    public function parseStringNode(t:GrammarTerm, str:String, file:String, ?errors:HaxeErrors):GrammarNode<TNode> {
        var result = parseString(t, str, file, errors);
        return switch (result) {
            case GrammarResult.RUnmatched(_) | GrammarResult.RMatched: return null;
            case GrammarResult.RMatchedValue(v): return cast(v);
        }
    }

    public function parseString(t:GrammarTerm, str:String, file:String, ?errors:HaxeErrors):GrammarResult return parse(t, new Reader(str, file), errors);
    
    private function describe(t:GrammarTerm):String {
        switch (t) {
            case GrammarTerm.TLit(lit, _): return '"$lit"';
            case GrammarTerm.TReg(name, _, _, _): return '$name';
            case GrammarTerm.TCustomMatcher(name, _): return '$name';
            case GrammarTerm.TRef(ref): return describe(ref.term);
            case GrammarTerm.TOpt(item, _): return describe(item);
            case GrammarTerm.TSeq(items, _): return describe(items[0]);
            case GrammarTerm.TList(item, _, _, _, _): return describe(item);
            case GrammarTerm.TAny(items, _): return [for (item in items) describe(item)].join(' or ');
            default: return '???';
        }
    }
    
    private function createContext(reader:Reader, errors:HaxeErrors):GrammarContext {
        return new GrammarContext(reader, errors);
    }
    
    public function parse(t:GrammarTerm, reader:Reader, ?errors:HaxeErrors):GrammarResult {
        if (errors == null) errors = new HaxeErrors();
        var grammarContext = createContext(reader, errors);
        var result = _parse(t, grammarContext, this.skipNonGrammar);
        if (!reader.eof()) {
            grammarContext.errors.add(new ParserError(reader.createPos(), 'unexpected end of file'));
        }
        return result;
    }

    private function _parse(t:GrammarTerm, grammarContext:GrammarContext, skipper:GrammarContext -> Void):GrammarResult {
        var reader:Reader = grammarContext.reader;
        var errors:HaxeErrors = grammarContext.errors;
        skipper(grammarContext);
        var start:Int = reader.pos;
        function gen(result:Dynamic, conv: Dynamic -> Dynamic) {
            if (result == null) return GrammarResult.RUnmatched(0, start);
            if (conv == null) return GrammarResult.RMatched;
            var rresult:Dynamic = conv(result);
            if (Std.is(rresult, GrammarNode)) {
                //rresult = new NNode(Position.combine(rresult.pos, result.pos), rresult.node);
                return GrammarResult.RMatchedValue(simplify(rresult, t));
            } else {
                var out = simplify(new GrammarNode(reader.createPos(start, reader.pos), rresult), t);
                if (Std.is(result, Array) && Std.is(out, GrammarNode)) {
                    for (item in cast(result, Array<Dynamic>)) {
                        if (Std.is(item, GrammarNode)) {
                            cast(out, GrammarNode<Dynamic>).addChild(cast(item, GrammarNode<Dynamic>));
                        }
                    }
                }
                return GrammarResult.RMatchedValue(out);
            }
        }
        switch (t) {
            case GrammarTerm.TLit(lit, conv): return gen(reader.matchLit(lit), conv);
            case GrammarTerm.TReg(name, reg, conv, checker):
                var res = reader.matchEReg(reg);
                if (checker != null) {
                    if (!checker(res)) {
                        /*
                        reader.pos = start;
                        //errors.add(new ParserError(reader.createPos(start, reader.pos), 'identifier ' + res + ' is a keyword'));
                        return Result.RUnmatched(0, start);
                        */
                    }
                }
                return gen(res, conv);
            case GrammarTerm.TCustomMatcher(name, matcher):
                var result = matcher(grammarContext);
                if (result == null) return GrammarResult.RUnmatched(0, start);
                var resultnode = new GrammarNode(reader.createPos(start, reader.pos), result);
                return GrammarResult.RMatchedValue(simplify(resultnode, t));
            case GrammarTerm.TRef(ref): return _parse(ref.term, grammarContext, skipper);
            case GrammarTerm.TOpt(item, error):
                switch (_parse(item, grammarContext, skipper)) {
                    case GrammarResult.RMatchedValue(v): return GrammarResult.RMatchedValue(v);
                    case GrammarResult.RUnmatched(_, _):
                        if (error != null) {
                            errors.add(new ParserError(reader.createPos(start, reader.pos), error));
                        }
                        return GrammarResult.RMatchedValue(null);
                    default:
                        return GrammarResult.RMatchedValue(null);
                }
            case GrammarTerm.TAny(items, recover):
                var maxValidCount = 0;
                var maxValidPos = start;
                var maxTerm = null;
                for (item in items) {
                    var r = _parse(item, grammarContext, skipper);
                    switch (r) {
                        case GrammarResult.RUnmatched(validCount, lastPos):
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
                            var r = _parse(item, grammarContext, skipper);
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
                return GrammarResult.RUnmatched(maxValidCount, maxValidPos);
            case GrammarTerm.TSeq(items, conv):
                var results = [];
                var count = 0;
                var sure = false;
                var lastItemIndex = reader.pos;
                for (item in items) {
                    switch (item) {
                        case GrammarTerm.TSure:
                            sure = true;
                            continue;
                        case GrammarTerm.TCustomSkipper(sk):
                            skipper = sk;
                            continue;
                        case GrammarTerm.TNot(t):
                            var old = reader.pos;
                            var r2 = _parse(t, grammarContext, skipper);
                            reader.pos = old;
                            switch (r2) {
                                case GrammarResult.RUnmatched(_, _):
                                default:
                                    return GrammarResult.RUnmatched(count, old);
                            }
                            continue;
                            
                        default:
                    }
                    var itemIndex = reader.pos;
                    var r = _parse(item, grammarContext, skipper);
                    switch (r) {
                        case GrammarResult.RUnmatched(validCount, lastPos):
                            if (sure) {
                                errors.add(new ParserError(reader.createPos(lastItemIndex, lastItemIndex), 'expected ' + describe(item)));
                                reader.pos = lastPos;
                                break;
                            } else {
                                reader.pos = start;
                                return GrammarResult.RUnmatched(validCount + count, lastPos);
                            }
                        case GrammarResult.RMatched:
                        case GrammarResult.RMatchedValue(v):
                            results.push(v);
                            if (v != null) lastItemIndex = v.pos.max;
                    }
                    
                    count++;
                }
                //trace('aaaa');
                return gen(results, conv);
            case GrammarTerm.TList(item, separator, minCount, allowExtraSeparator, conv):
                var items = [];
                var count = 0;
                var separatorCount = 0;
                var lastSeparatorPos = reader.createPos(start, start);
                while (true) {
                    var rpos = reader.pos;
                    var resultItem = _parse(item, grammarContext, skipper);
                    switch (resultItem) {
                        case GrammarResult.RUnmatched(_):
                            //reader.pos = rpos;
                            break;
                        case GrammarResult.RMatched:
                        case GrammarResult.RMatchedValue(value): items.push(value);
                    }
                    count++;
                    if (separator != null) {
                        var rpos = reader.pos;
                        var resultSep = _parse(separator, grammarContext, skipper);
                        switch (resultSep) {
                            case GrammarResult.RUnmatched(_):
                                reader.pos = rpos;
                                break;
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
                    return GrammarResult.RUnmatched(count, lastPos);
                }
                return gen(items, conv);
            default:
                throw 'Unmatched $t';
        }
    }
}






