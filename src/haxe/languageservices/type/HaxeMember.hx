package haxe.languageservices.type;

import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class HaxeMember {
    public var pos:Position;
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var typeNode:ZNode;
    public var valueNode:ZNode;

    public function new(pos:Position, name:String) {
        this.pos = pos;
        this.name = name;
    }
    
    public function toString() return 'Member($name)';

    public function getType(types:HaxeTypes):SpecificHaxeType return types.specTypeDynamic;
}

class MethodHaxeMember extends HaxeMember {
    private var type:FunctionHaxeType;
    public function new(type:FunctionHaxeType) {
        super(type.pos, type.name);
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
