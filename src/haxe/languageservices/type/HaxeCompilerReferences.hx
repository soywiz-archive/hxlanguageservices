package haxe.languageservices.type;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;

class HaxeCompilerReferences {
    public var usages = new Array<HaxeCompilerUsage>();

    public function addPos(type:UsageType, pos:TextRange) {
        usages.push(new HaxeCompilerUsage(pos, type));
    }

    public function addNode(type:UsageType, node:ZNode) {
        usages.push(new HaxeCompilerUsage(node.pos, type, node));
    }

    public function new() {
    }
}
