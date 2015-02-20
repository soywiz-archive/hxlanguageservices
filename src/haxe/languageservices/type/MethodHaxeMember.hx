package haxe.languageservices.type;

class MethodHaxeMember extends HaxeMember {
    private var type:FunctionHaxeType;
    public function new(type:FunctionHaxeType) {
        super(type, type.pos, type.nameNode);
        this.type = type;
    }
    override public function toString() return 'Method($name)';
    override public function getType():SpecificHaxeType {
        return type.types.createSpecific(type);
    }
}
