package haxe.languageservices.error;

import haxe.languageservices.node.TextRange;

class ParserError {
    public var pos:TextRange;
    public var message:String;
    public var fixes:Array<QuickFix>;
    
    public function new(pos:TextRange, message:String, ?fixes:Array<QuickFix>) {
        this.pos = pos;
        this.message = message;
        this.fixes = fixes;
    }

    public function toString() return '$pos:$message';
}
