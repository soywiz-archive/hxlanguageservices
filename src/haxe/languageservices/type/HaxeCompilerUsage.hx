package haxe.languageservices.type;

import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class HaxeCompilerUsage {
    public var name(default, null):String;
    public var pos(default, null):Position;
    public var optNode(default, null):ZNode;
    public var type(default, null):UsageType;

    public function new(pos:Position, type:UsageType, ?optNode:ZNode) {
        this.name = pos.text;
        this.pos = pos;
        this.type = type;
        this.optNode = optNode;
    }

    public function toString() return '$name:$type@$pos';
}
