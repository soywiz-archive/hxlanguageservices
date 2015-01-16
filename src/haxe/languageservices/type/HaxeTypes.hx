package haxe.languageservices.type;

import haxe.languageservices.type.HaxeMember.MethodHaxeMember;
import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.node.Reader;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.type.HaxeType.ClassHaxeType;
import haxe.languageservices.type.HaxeType.InterfaceHaxeType;
import haxe.languageservices.node.Position;
class HaxeTypes {
    public var rootPackage:HaxePackage;
    public var typeDynamic(default, null):HaxeType;
    public var typeBool(default, null):HaxeType;
    public var typeInt(default, null):HaxeType;
    public var typeFloat(default, null):HaxeType;
    public var typeArray(default, null):HaxeType;

    public var specTypeDynamic(default, null):SpecificHaxeType;
    public var specTypeBool(default, null):SpecificHaxeType;
    public var specTypeInt(default, null):SpecificHaxeType;
    public var specTypeFloat(default, null):SpecificHaxeType;

    public function new() {
        rootPackage = new HaxePackage(this, '');
        typeDynamic = rootPackage.accessTypeCreate('Dynamic', new Position(0, 0, new Reader('', 'Dynamic.hx')), ClassHaxeType);
        typeBool = rootPackage.accessTypeCreate('Bool', new Position(0, 0, new Reader('', 'Bool.hx')), ClassHaxeType);
        typeInt = rootPackage.accessTypeCreate('Int', new Position(0, 0, new Reader('', 'Int.hx')), ClassHaxeType);
        typeFloat = rootPackage.accessTypeCreate('Float', new Position(0, 0, new Reader('', 'Float.hx')), ClassHaxeType);
        typeArray = rootPackage.accessTypeCreate('Array', new Position(0, 0, new Reader('', 'Array.hx')), ClassHaxeType);
        typeArray.addMember(new MethodHaxeMember(typeArray.pos, 'indexOf'));
        typeArray.addMember(new MethodHaxeMember(typeArray.pos, 'charAt'));
        specTypeDynamic = new SpecificHaxeType(this, typeDynamic);
        specTypeBool = new SpecificHaxeType(this, typeBool);
        specTypeInt = new SpecificHaxeType(this, typeInt);
        specTypeFloat = new SpecificHaxeType(this, typeFloat);
    }

    public function unify(types:Array<SpecificHaxeType>):SpecificHaxeType {
        // @TODO
        if (types.length == 0) return new SpecificHaxeType(this, typeDynamic);
        return types[0];
    }

    public function getType(path:String):HaxeType {
        if (path.substr(0, 1) == ':') return getType(path.substr(1));
        return rootPackage.accessType(path);
    }
    public function getClass(path:String):ClassHaxeType {
        return Std.instance(getType(path), ClassHaxeType);
    }
    public function getInterface(path:String):InterfaceHaxeType {
        return Std.instance(getType(path), InterfaceHaxeType);
    }
    
    public function createArray(elementType:SpecificHaxeType):SpecificHaxeType {
        return new SpecificHaxeType(this, typeArray, [elementType]);
    }
    
    public function getArrayElement(arrayType:SpecificHaxeType):SpecificHaxeType {
        if (arrayType == null || arrayType.parameters.length < 1) return new SpecificHaxeType(this, typeDynamic);
        return arrayType.parameters[0];
    }

    public function getAllTypes():Array<HaxeType> return rootPackage.getAllTypes();

    public function getLeafPackageNames():Array<String> {
        return rootPackage.getLeafs().map(function(p:HaxePackage) return p.fqName);
    }
}
