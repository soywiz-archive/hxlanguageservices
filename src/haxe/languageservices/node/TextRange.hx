package haxe.languageservices.node;

class TextRange {
    public var min(default, null):Int;
    public var max(default, null):Int;
    public var reader(default, null):Reader;
    public var text(get, never):String;
    public var file(get, never):String;
    public function new(min:Int, max:Int, reader:Reader) { this.min = min; this.max = max; this.reader = reader; }
    static public function combine(a:TextRange, b:TextRange):TextRange {
        return new TextRange(Std.int(Math.min(a.min, b.min)), Std.int(Math.max(a.max, b.max)), a.reader);
    }
    public function contains(index:Int) return index >= min && index <= max;
    public function toString() return '$min:$max';
    private function get_file():String return reader.file;
    private function get_text():String return reader.slice(min, max);
    
    public function startEmptyRange():TextRange {
        return new TextRange(min, min, reader);
    }

    public function endEmptyRange():TextRange {
        return new TextRange(max, max, reader);
    }

    public function displace(offset:Int):TextRange {
        return new TextRange(min + offset, max + offset, reader);
    }

    static public function createDummy() {
        return new TextRange(0, 0, new Reader(''));
    }
}
