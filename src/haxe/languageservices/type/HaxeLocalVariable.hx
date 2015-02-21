package haxe.languageservices.type;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;

class HaxeLocalVariable extends HaxeNodeElement {
    public function new(node:ZNode, ?resolver:ProcessNodeContext -> ExpressionResult) {
        super(node);
        this.resultResolver = resolver;
    }

    override public function toString():String {
        //return 'Local(${getName()}:${getResult()})';
        return 'Local(${getName()})';
    }

}
