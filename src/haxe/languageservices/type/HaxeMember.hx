package haxe.languageservices.type;

import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class HaxeMember {
    public var pos:Position;
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var typeNode:ZNode;
    public var valueNode:ZNode;
    public var typeResolver:HaxeTypeResolver;
    
    public function new(pos:Position, name:String) {
        this.pos = pos;
        this.name = name;
    }
    
    public function toString() return 'Member($name)';

    public function getType():HaxeType return (typeResolver != null) ? typeResolver.resolve() : null;
}

class MethodHaxeMember extends HaxeMember {
    override public function toString() return 'Method($name)';
}

class FieldHaxeMember extends HaxeMember {
    override public function toString() return 'Field($name)';
}
