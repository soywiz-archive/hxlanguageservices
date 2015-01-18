package haxe.languageservices.type;

class SpecificHaxeType {
    public var type:HaxeType;
    public var parameters:Array<SpecificHaxeType>;
    
    public function new(types:HaxeTypes, type:HaxeType, ?parameters:Array<SpecificHaxeType>) {
        if (type == null) type = types.typeDynamic;
        if (parameters == null) parameters = [];
        this.type = type;
        this.parameters = parameters;
    }
    
    public function toString() {
        var res = '$type';
        if (parameters.length > 0) {
            res += '<' + parameters.join(',') + '>';
        }
        return res;
    }

    public function canAssign(that:SpecificHaxeType):Bool {
        return this.type.canAssign(that.type);
    }
}
