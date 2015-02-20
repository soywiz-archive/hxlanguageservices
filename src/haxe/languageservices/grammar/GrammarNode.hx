package haxe.languageservices.grammar;

import haxe.languageservices.node.TextRange;

class GrammarNode<T> {
    public var pos:TextRange;
    public var node:T;
    public function new(pos:TextRange, node:T) { this.pos = pos; this.node = node; }
    public function locateIndex(index:Int):GrammarNode<T> {
        return staticLocateIndex(this, index);
    }
    static public function staticLocateIndex<T>(item:Dynamic, index:Int):GrammarNode<T> {
        if (Std.is(item, GrammarNode)) {
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
    static public function isValid<T>(node:GrammarNode<T>):Bool {
        return node != null && node.node != null;
    }
    public function toString() return '$node@$pos';
}
