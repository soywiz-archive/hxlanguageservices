package haxe.languageservices.type;

import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class HaxeMember {
    public var baseType:HaxeType;
    public var pos:Position;
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var typeNode:ZNode;
    public var valueNode:ZNode;

    public function new(baseType:HaxeType, pos:Position, name:String) {
        this.baseType = baseType;
        this.pos = pos;
        this.name = name;
    }
    
    public function toString() return 'Member($name)';

    public function getType(types:HaxeTypes):SpecificHaxeType return types.specTypeDynamic;

    static public function staticIsStatic(member:HaxeMember):Bool {
        return member.modifiers.isStatic;
    }

    static public function staticIsNotStatic(member:HaxeMember):Bool {
        return !member.modifiers.isStatic;
    }
}

class MethodHaxeMember extends HaxeMember {
    private var type:FunctionHaxeType;
    public function new(type:FunctionHaxeType) {
        super(type, type.pos, type.name);
        this.type = type;
    }
    override public function toString() return 'Method($name)';
    override public function getType(types:HaxeTypes):SpecificHaxeType {
        return new SpecificHaxeType(type);
    }
}

class FieldHaxeMember extends HaxeMember {
    override public function toString() return 'Field($name)';
}
