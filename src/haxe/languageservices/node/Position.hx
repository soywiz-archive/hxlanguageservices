package haxe.languageservices.node;

class Position {
    public var min:Int;
    public var max:Int;
    public function new(min:Int, max:Int) { this.min = min; this.max = max; }
    public function contains(index:Int) return index >= min && index <= max;
    public function toString() return '$min:$max';
}
