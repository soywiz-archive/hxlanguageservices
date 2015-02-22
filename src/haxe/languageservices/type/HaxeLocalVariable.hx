package haxe.languageservices.type;
import haxe.languageservices.completion.CompletionProvider;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;

class HaxeLocalVariable extends HaxeNodeElement {
    public function new(node:ZNode, scope:CompletionProvider, ?resolver:ProcessNodeContext -> ExpressionResult) {
        super(node, scope);
        this.resultResolver = resolver;
    }

    override public function toString():String {
        return 'Local(${getName()}:${getResult()})';
        //return 'Local(${getName()})';
    }

}
