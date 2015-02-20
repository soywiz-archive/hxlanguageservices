package haxe.languageservices.type;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;

class HaxeNodeElement implements HaxeCompilerElement {
    private var node:ZNode;
    private var references = new HaxeCompilerReferences();

    public function new(node:ZNode) {
        this.node = node;
    }

    public function getPosition():TextRange { return node.pos; }
    public function getNode():ZNode { return node; }
    public function getName():String { return node.pos.text; }
    public function getReferences():HaxeCompilerReferences { return references; }
    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        throw 'Must override HaxeNodeElement.getResult';
        return null;
    }
    public function toString():String { return this.getName(); }
}
