package haxe.languageservices.grammar;

class ParserError {
    public var pos:Position;
    public var message:String;
    
    public function new(pos:Position, message:String) {
        this.pos = pos;
        this.message = message;
    }

    public function toString() return '$pos:$message';
}
