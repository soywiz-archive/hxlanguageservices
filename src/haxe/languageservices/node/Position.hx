package haxe.languageservices.node;

class Position {
    public var min:Int;
    public var max:Int;
    public var file:String;
    public function new(min:Int, max:Int, file:String) { this.min = min; this.max = max; this.file = file; }
    public function contains(index:Int) return index >= min && index <= max;
    public function toString() return '$min:$max';
}
