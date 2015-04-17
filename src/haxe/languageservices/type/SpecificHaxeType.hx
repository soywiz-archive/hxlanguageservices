package haxe.languageservices.type;

import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;
class SpecificHaxeType implements HaxeCompilerElement  {
    public var types:HaxeTypes;
    public var type:HaxeType;
    public var parameters:Array<SpecificHaxeType>;
    public var refs = new HaxeCompilerReferences();

    public function new(types:HaxeTypes, type:HaxeType, ?parameters:Array<SpecificHaxeType>) {
        if (type == null) type = types.typeDynamic;
        if (parameters == null) parameters = [];
        this.types = types;
        this.type = type;
        this.parameters = parameters;
    }

    public function getArrayElement() {
        // Array
        if (type.fqName == 'Array' && parameters.length >= 1) return parameters[0];
        return types.specTypeDynamic;
    }

    public function getPosition():TextRange return types.dummyPosition;
    public function getNode():ZNode return types.dummyNode;

    public function getName():String {
        if (parameters.length == 0) return type.name;
        return type.name + '<' + parameters.map(function(p) return p.getName()).join(', ') + '>';
    }

    public function getReferences():HaxeCompilerReferences return refs;

    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(this);
    }

    public function getInheritedMemberByName(name:String):HaxeMember {
        if (type.fqName == 'Class') {
            return parameters[0].type.getInheritedMemberByName(name);
        } else {
            return type.getInheritedMemberByName(name);
        }
    }

    public function access(name:String):SpecificHaxeType {
        var member = type.getInheritedMemberByName(name);
        if (member == null) return types.specTypeDynamic;
        return member.getType();
    }
    
    public function toString() {
        var res = '$type';
        if (parameters.length > 0) {
            res += '<' + parameters.join(',') + '>';
        }
        return res;
    }

    public function canAssign(that:SpecificHaxeType):Bool {
        return this.type.canAssignFrom(that.type);
    }
}
