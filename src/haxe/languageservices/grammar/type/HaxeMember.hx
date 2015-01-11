package haxe.languageservices.grammar.type;
class HaxeMember {
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var typeResolver:HaxeTypeResolver;
    
    public function new(name:String) {
        this.name = name;
    }

    public function getType():HaxeType return (typeResolver != null) ? typeResolver.resolve() : null;
}

class MethodHaxeMember extends HaxeMember {
}

class FieldHaxeMember extends HaxeMember {
}
