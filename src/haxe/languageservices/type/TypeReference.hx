package haxe.languageservices.type;

import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.completion.CompletionProvider;
import haxe.languageservices.node.ZNode;

class TypeReference implements HaxeCompilerElement {
    public var types:HaxeTypes;
    public var fqName:String;
    public var doc:String;
    public var expr:ZNode;
    public function new(types:HaxeTypes, fqName:String, expr:ZNode) {
        this.types = types;
        this.fqName = fqName;
        this.expr = expr;
    }
    static public function create(types:HaxeTypes, nameNode:ZNode) {
        return new TypeReference(types, nameNode.pos.text, nameNode);
    }
    public function getSpecType():SpecificHaxeType return types.createSpecific(getType());
    public function getType():HaxeType return types.getType(fqName);
    public function getClass():ClassHaxeType return types.getClass(fqName);
    public function getInterface():InterfaceHaxeType return types.getInterface(fqName);

    public function getPosition():TextRange return expr.pos;
    public function getNode():ZNode return expr;
    public function getName():String return fqName;
    public function getReferences():HaxeCompilerReferences return getType().getReferences();
    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(getSpecType());
    }
    public function toString():String {
        return 'TypeReference(${getType()})';
    }

}
