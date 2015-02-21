package haxe.languageservices.type;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;
class HaxeThisElement implements HaxeCompilerElement {
    public var type:HaxeType;
    public var references = new HaxeCompilerReferences();
    public function new(type:HaxeType) {
        this.type = type;
    }
    public function getPosition():TextRange { return type.node.pos.reader.createPos(0, 0); }
    public function getNode():ZNode { return new ZNode(type.node.pos.reader.createPos(), null); }
    public function getName():String { return 'this'; }
    public function getReferences():HaxeCompilerReferences { return references; }
    public function getResult(?context:ProcessNodeContext):ExpressionResult { return ExpressionResult.withoutValue(new SpecificHaxeType(type.types, type)); }
    public function toString():String { return 'This'; }
}
