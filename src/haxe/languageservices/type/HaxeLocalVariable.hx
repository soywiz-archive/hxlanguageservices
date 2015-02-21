package haxe.languageservices.type;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;
class HaxeLocalVariable extends HaxeNodeElement {
    public var result:ExpressionResult;
    public var resultResolver:ProcessNodeContext -> ExpressionResult;
    public function new(node:ZNode) { super(node); }
    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        if (result != null) return result;
        if (context == null) context = new ProcessNodeContext();
        return resultResolver(context);
    }

    override public function toString():String {
        return 'Local(${getName()}:${getResult()})';
    }

}
