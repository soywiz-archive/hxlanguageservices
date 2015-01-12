package haxe.languageservices.grammar;

import haxe.languageservices.node.Position;
class ParserError {
    public var pos:Position;
    public var message:String;
    
    public function new(pos:Position, message:String) {
        this.pos = pos;
        this.message = message;
    }

    public function toString() return '$pos:$message';
}
