package haxe.languageservices.parser;

import haxe.languageservices.parser.Completion.CompletionType;
class TypeContext {
    public var packages = new Map<String, TypePackage>();

    public function new() {
    }

    public function getPackage(name:String):TypePackage {
        var packag = packages[name];
        if (packag == null) packag = packages[name] = new TypePackage(this, name);
        return packag;
    }

    public function getAllClasses(?out:Array<TypeType>):Array<TypeType> {
        if (out == null) out = [];
        for (packag in packages) packag.getClasses(out);
        return out;
    }
}

class TypePackage {
    public var context:TypeContext;
    public var parts:Array<String>;
    public var name:String;
    public var classes = new Map<String, TypeType>();

    public function new(context:TypeContext, name:String) {
        this.context = context;
        this.name = name;
        this.parts = name.split('.');
    }
    
    public function toString() return 'TypePackage($name)';

    public function getClass(name:String, _newKind:Class<TypeType>):TypeType {
        var clazz = classes[name];
        if (clazz == null) clazz = classes[name] = Type.createInstance(_newKind, [this, name]);
        return clazz;
    }

    public function getClasses(?out:Array<TypeType>):Array<TypeType> {
        if (out == null) out = [];
        for (clazz in classes) out.push(clazz);
        return out;
    }
}

class TypeType {
    public var packag:TypePackage;
    public var name:String;
    public var fqName:String;
    public var imports = new Array<TypeType>();
    public var members = new Array<TypeMember>();

    public function new(packag:TypePackage, name:String) {
        this.packag = packag;
        this.name = name;
        this.fqName = (packag.name.length > 0) ? (packag.name + '.' + name) : name;
    }

    public function toString() return 'TypeType($fqName)';
}

class TypeClass extends TypeType {
    override public function toString() return 'TypeClass($fqName)';
}

class TypeEnum extends TypeType {
    override public function toString() return 'TypeEnum($fqName)';
}

class TypeAbstract extends TypeType {
    override public function toString() return 'TypeAbstract($fqName)';
}

class TypeTypedef extends TypeType {
    public var targetType:CompletionType;
    override public function toString() return 'TypeTypedef($fqName->$targetType)';
    public function setTargetType(targetType:CompletionType) {
        this.targetType = targetType;
    }
}

class TypeMember {
    public var visibility:String;
    public var isStatic:Bool;
    public var name:String;
}

class TypeField extends TypeMember {
}

class TypeMethod extends TypeMember {
}