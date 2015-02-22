package haxe.languageservices.type;

class SpecificHaxeType {
    public var types:HaxeTypes;
    public var type:HaxeType;
    public var parameters:Array<SpecificHaxeType>;
    
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
