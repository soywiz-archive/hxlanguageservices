package haxe.languageservices.completion;

import haxe.languageservices.type.FunctionHaxeType;
import haxe.languageservices.node.ZNode;

class CallInfo {
    public var argindex:Int;
    public var startPos:Int;
    public var argPosStart:Int;
    public var node:ZNode;
    public var f:FunctionHaxeType;
    public function new(argindex:Int, startPos:Int, argPosStart:Int, node:ZNode, f:FunctionHaxeType) {
        this.argindex = argindex;
        this.startPos = startPos;
        this.argPosStart = argPosStart;
        this.node = node;
        this.f = f;
    }
}
