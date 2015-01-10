package haxe.languageservices.parser;

import haxe.languageservices.parser.Expr.TypeParameter;
import haxe.languageservices.parser.Expr.TypeParameters;
import haxe.languageservices.parser.Expr.CType;
import haxe.languageservices.parser.Completion.CompletionType;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
class TypeContext {
    public var packages = new Map<String, TypePackage>();

    public function new() {
    }

    public function getPackage(name:String):TypePackage {
        var packag = packages[name];
        if (packag == null) packag = packages[name] = new TypePackage(this, name);
        return packag;
    }

    public function getPackage2(chunks:Array<String>):TypePackage {
        return getPackage(chunks.join('.'));
    }

    public function getTypeFq(fqName:String):TypeType {
        var items = fqName.split('.');
        var typeName = items.pop();
        return getPackage2(items).getClass(typeName, null);
    }
    
    public function getAllTypes(?out:Array<TypeType>):Array<TypeType> {
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
    static private var lastUid = 0;
    public var uid = lastUid++;
    public var packag:TypePackage;
    public var name:String;
    public var fqName:String;
    public var imports = new Array<TypeType>();
    public var members = new Array<TypeMember>();
    public var typeParams = new TypeParameters();

    public function new(packag:TypePackage, name:String) {
        this.packag = packag;
        this.name = name;
        this.fqName = (packag.name.length > 0) ? (packag.name + '.' + name) : name;
    }
    
    private function getDescription() {
        function getParamTypeString(p:TypeParameter):String {
            function getConstraints(p:Array<CType>):String {
                if (p == null || p.length == 0) return '';
                if (p.length == 1) return ':' + CompletionTypeUtils.fromCType(p[0]);
                return ':(' + [for (n in p) '' + CompletionTypeUtils.fromCType(n)].join(',') + ')';
            }

            return p.name + getConstraints(p.constraints);
        }
    
        if (typeParams != null && typeParams.length > 0) {
            return '$fqName<' + [for (p in typeParams) getParamTypeString(p)].join(',') + '>';
        } else {
            return fqName;
        }
    }

    public function toString() return 'TypeType(${this.getDescription()})';
}

class TypeClass extends TypeType {
    override public function toString() return 'TypeClass(${this.getDescription()})';
}

class TypeEnum extends TypeType {
    override public function toString() return 'TypeEnum(${this.getDescription()})';
}

class TypeAbstract extends TypeType {
    override public function toString() return 'TypeAbstract(${this.getDescription()})';
}

class TypeTypedef extends TypeType {
    public var targetType:CompletionType;
    override public function toString() return 'TypeTypedef(${this.getDescription()}->$targetType)';
    public function setTargetType(targetType:CompletionType) {
        this.targetType = targetType;
    }
}

class TypeMember {
    public var visibility:String;
    public var isStatic:Bool;
    public var name:String;
    public var type:CompletionType;

    public function new(name:String, type:CompletionType) {
        this.name = name;
        this.type = type;
    }
}

class TypeField extends TypeMember {
}

class TypeMethod extends TypeMember {
}