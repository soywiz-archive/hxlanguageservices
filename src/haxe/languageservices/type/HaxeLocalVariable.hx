package haxe.languageservices.type;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;

class HaxeLocalVariable extends HaxeNodeElement {
    public function new(node:ZNode) { super(node); }

    override public function toString():String {
        return 'Local(${getName()}:${getResult()})';
    }

}
