package haxe.languageservices.type;

import haxe.languageservices.type.HaxeMember.MethodHaxeMember;
import haxe.languageservices.node.Reader;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Position;
class HaxeTypes {
    public var rootPackage:HaxePackage;

    public var typeVoid(default, null):HaxeType;
    public var typeDynamic(default, null):HaxeType;
    public var typeBool(default, null):HaxeType;
    public var typeInt(default, null):HaxeType;
    public var typeFloat(default, null):HaxeType;
    public var typeString(default, null):HaxeType;

    public var specTypeVoid(default, null):SpecificHaxeType;
    public var specTypeDynamic(default, null):SpecificHaxeType;
    public var specTypeBool(default, null):SpecificHaxeType;
    public var specTypeInt(default, null):SpecificHaxeType;
    public var specTypeFloat(default, null):SpecificHaxeType;
    public var specTypeString(default, null):SpecificHaxeType;

    public var typeArray(default, null):HaxeType;

    public function new() {
        var typesPos = new Position(0, 0, new Reader('', '_Types.hx'));
    
        rootPackage = new HaxePackage(this, '');
        typeVoid = rootPackage.accessTypeCreate('Void', typesPos, ClassHaxeType);
        typeDynamic = rootPackage.accessTypeCreate('Dynamic', typesPos, ClassHaxeType);
        typeBool = rootPackage.accessTypeCreate('Bool', typesPos, ClassHaxeType);
        typeInt = rootPackage.accessTypeCreate('Int', typesPos, ClassHaxeType);
        typeFloat = rootPackage.accessTypeCreate('Float', typesPos, ClassHaxeType);
        typeArray = rootPackage.accessTypeCreate('Array', typesPos, ClassHaxeType);
        typeString = rootPackage.accessTypeCreate('String', typesPos, ClassHaxeType);

        specTypeVoid = new SpecificHaxeType(typeVoid);
        specTypeDynamic = new SpecificHaxeType(typeDynamic);
        specTypeBool = new SpecificHaxeType(typeBool);
        specTypeInt = new SpecificHaxeType(typeInt);
        specTypeFloat = new SpecificHaxeType(typeFloat);
        specTypeString = new SpecificHaxeType(typeString);

        typeBool.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeBool.pos, 'testBoolMethod', [], new FunctionRetval('Dynamic'))));
        typeBool.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeBool.pos, 'testBoolMethod2', [], new FunctionRetval('Dynamic'))));
        typeInt.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeInt.pos, 'testIntMethod', [], new FunctionRetval('Dynamic'))));
        typeInt.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeInt.pos, 'testIntMethod2', [], new FunctionRetval('Dynamic'))));
        typeArray.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeArray.pos, 'indexOf', [new FunctionArgument('element', 'Dynamic')], new FunctionRetval('Int'))));
        typeArray.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeArray.pos, 'charAt', [new FunctionArgument('index', 'Int')], new FunctionRetval('String'))));
    }

    public function unify(types:Array<SpecificHaxeType>):SpecificHaxeType {
        // @TODO
        if (types.length == 0) return new SpecificHaxeType(typeDynamic);
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
        return new SpecificHaxeType(typeArray, [elementType]);
    }
    
    public function getArrayElement(arrayType:SpecificHaxeType):SpecificHaxeType {
        if (arrayType == null || arrayType.parameters.length < 1) return new SpecificHaxeType(typeDynamic);
        return arrayType.parameters[0];
    }

    public function getAllTypes():Array<HaxeType> return rootPackage.getAllTypes();

    public function getLeafPackageNames():Array<String> {
        return rootPackage.getLeafs().map(function(p:HaxePackage) return p.fqName);
    }
}
