package haxe.languageservices.util;

class Scope<TKey : String, TValue> {
    public var parent:Scope<TKey, TValue>;
    private var map:Map<String, TValue>;

    public function new(?parent:Scope<TKey, TValue>) {
        this.parent = parent;
        this.map = new Map<String, TValue>();
    }

    public function exists(key:TKey):Bool {
        if (map.exists(key)) return true;
        if (parent != null) return parent.exists(key);
        return false;
    }

    public function get(key:TKey):TValue {
        if (map.exists(key)) return map.get(key);
        if (parent != null) return parent.get(key);
        //throw new Error2('Can\'t find "$key"');
        return null;
    }

    public function set(key:TKey, value:TValue) return map.set(key, value);

    public function keys(?out:Array<String>):Array<String> {
        if (out == null) out = [];
        for (key in map.keys()) {
            if (out.indexOf(key) < 0) out.push(key);
        }
        if (parent != null) parent.keys(out);
        return out;
    }
    public function values(?out:Array<TValue>):Array<TValue> {
        if (out == null) out = [];
        for (value in map) if (out.indexOf(value) < 0) out.push(value);
        if (parent != null) parent.values(out);
        return out;
    }

    public function createChild():Scope<TKey, TValue> return new Scope<TKey, TValue>(this);

    public function toString() {
        return 'Scope(${[for (key in map.keys()) key]}, $parent)';
    }
}
