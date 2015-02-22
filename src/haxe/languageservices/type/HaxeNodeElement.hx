package haxe.languageservices.type;
import haxe.languageservices.completion.CompletionProvider;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;

class HaxeNodeElement implements HaxeCompilerElement {
    public var scope:CompletionProvider;
    private var node:ZNode;
    private var references = new HaxeCompilerReferences();
    public var result:ExpressionResult;
    public var resultResolver:ProcessNodeContext -> ExpressionResult;

    public function new(node:ZNode, scope:CompletionProvider) {
        this.node = node;
        this.scope = scope;
    }

    public function getPosition():TextRange { return node.pos; }
    public function getNode():ZNode { return node; }
    public function getName():String { return node.pos.text; }
    public function getReferences():HaxeCompilerReferences { return references; }
    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        if (result != null) return result;
        if (resultResolver != null) {
            if (context == null) context = new ProcessNodeContext();
            return resultResolver(context);
        }
        return null;
    }
    public function toString():String { return this.getName(); }
}
