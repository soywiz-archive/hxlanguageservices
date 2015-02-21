package haxe.languageservices.type;

import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.ZNode;
class FunctionArgument extends HaxeNodeElement {
    private var types:HaxeTypes;
    public var opt:Bool;
    public var index:Int;
    public var func:FunctionHaxeType;
    public var defaultValue:ZNode;
    public var type:SpecificHaxeType;
    public var doc:String;
    
    public function new(types:HaxeTypes, index:Int, node:ZNode, result:ExpressionResult = null, opt:Bool = false, doc:String = '') {
        this.types = types;
        this.opt = opt;
        this.index = index;
        this.doc = doc;
        this.result = result;
        super(node);
    }

    public function getFqName() {
        return getResult().type.type.fqName;
    }

    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        if (type != null) return ExpressionResult.withoutValue(type);
        var v = super.getResult(context);
        if (v != null) return v;
        return ExpressionResult.withoutValue(types.specTypeDynamic);
    }

    //override public function toString() return '$name:$fqName';
}
