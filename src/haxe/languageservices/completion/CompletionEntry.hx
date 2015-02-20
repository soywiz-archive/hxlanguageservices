package haxe.languageservices.completion;

import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.type.HaxeCompilerReferences;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.type.HaxeCompilerElement;

class CompletionEntry implements HaxeCompilerElement {
    public var scope:CompletionScope;
    public var pos:TextRange;
    public var name:String;
    public var type:ZNode;
    public var type2:SpecificHaxeType;
    public var expr:ZNode;
    public var refs = new HaxeCompilerReferences();

    public function new(scope:CompletionScope, pos:TextRange, type:ZNode, expr:ZNode, name:String, ?type2:SpecificHaxeType) {
        this.scope = scope;
        this.pos = pos;
        this.type = type;
        this.type2 = type2;
        this.expr = expr;
        this.name = name;
    }

    public function getNode() return expr;
    public function getPosition() return pos;
    public function getName() return name;
    public function getReferences():HaxeCompilerReferences return refs;

    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        var ctype:ExpressionResult = null;
        if (type2 != null) return ExpressionResult.withoutValue(type2);
        if (type != null) ctype = ExpressionResult.withoutValue(scope.types.createSpecific(scope.types.getType(type.pos.text)));
        if (expr != null) ctype = scope.getNodeResult(expr, context);
        if (ctype == null) ctype = ExpressionResult.withoutValue(scope.types.specTypeDynamic);
        return ctype;
    }

    public function toString() return '$name@$pos';
}
