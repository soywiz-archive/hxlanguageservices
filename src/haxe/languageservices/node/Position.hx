package haxe.languageservices.node;

class Position {
    public var min(default, null):Int;
    public var max(default, null):Int;
    public var reader(default, null):Reader;
    public var text(get, never):String;
    public var file(get, never):String;
    public function new(min:Int, max:Int, reader:Reader) { this.min = min; this.max = max; this.reader = reader; }
    public function contains(index:Int) return index >= min && index <= max;
    public function toString() return '$min:$max';
    private function get_file():String return reader.file;
    private function get_text():String return reader.slice(min, max);
}
