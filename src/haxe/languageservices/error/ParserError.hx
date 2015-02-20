package haxe.languageservices.error;

import haxe.languageservices.node.TextRange;

class ParserError {
    public var pos:TextRange;
    public var message:String;
    
    public function new(pos:TextRange, message:String) {
        this.pos = pos;
        this.message = message;
    }

    public function toString() return '$pos:$message';
}
