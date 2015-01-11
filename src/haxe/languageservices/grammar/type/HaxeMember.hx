package haxe.languageservices.grammar.type;
import haxe.languageservices.grammar.HaxeGrammar.Node;
class HaxeMember {
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var typeNode:Node;
    public var valueNode:Node;
    public var typeResolver:HaxeTypeResolver;
    
    public function new(name:String) {
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
