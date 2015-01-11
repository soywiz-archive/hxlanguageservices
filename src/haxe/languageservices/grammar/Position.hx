package haxe.languageservices.grammar;

class Position {
    public var min:Int;
    public var max:Int;
    public function new(min:Int, max:Int) { this.min = min; this.max = max; }
    public function toString() return '$min:$max';
}
