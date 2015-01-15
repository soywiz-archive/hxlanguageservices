package haxe.languageservices.util;

class Scope<TValue> {
    public var parent:Scope<TValue>;
    private var map:Map<String, TValue>;

    public function new(?parent:Scope<TValue>) {
        this.parent = parent;
        this.map = new Map<String, TValue>();
    }

    public function exists(key:String):Bool {
        if (map.exists(key)) return true;
        if (parent != null) return parent.exists(key);
        return false;
    }

    public function get(key:String):TValue {
        if (map.exists(key)) return map.get(key);
        if (parent != null) return parent.get(key);
        //throw new Error2('Can\'t find "$key"');
        return null;
    }

    public function set(key:String, value:TValue) return map.set(key, value);

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
        for (key in this.keys()) out.push(get(cast(key)));
        return out;
    }

    public function createChild():Scope<TValue> return new Scope<TValue>(this);

    public function toString() {
        return 'Scope(${[for (key in map.keys()) key]}, $parent)';
    }
}
