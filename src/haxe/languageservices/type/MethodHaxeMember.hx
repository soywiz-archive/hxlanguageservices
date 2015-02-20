package haxe.languageservices.type;

class MethodHaxeMember extends HaxeMember {
    public var func:FunctionHaxeType;
    public function new(func:FunctionHaxeType) {
        super(func, func.pos, func.nameNode);
        this.func = func;
    }
    override public function toString() return 'Method($name)';
    override public function getType():SpecificHaxeType {
        return func.types.createSpecific(func);
    }
}
