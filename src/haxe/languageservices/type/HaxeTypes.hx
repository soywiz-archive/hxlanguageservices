package haxe.languageservices.type;

import haxe.languageservices.node.Reader;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.type.HaxeType.ClassHaxeType;
import haxe.languageservices.node.Position;
class HaxeTypes {
    public var rootPackage:HaxePackage;
    public var typeDynamic(default, null):HaxeType;
    public var typeBool(default, null):HaxeType;
    public var typeInt(default, null):HaxeType;
    public var typeFloat(default, null):HaxeType;

    public function new() {
        rootPackage = new HaxePackage(this, '');
        typeDynamic = rootPackage.accessTypeCreate('Dynamic', new Position(0, 0, new Reader('', 'Dynamic.hx')), ClassHaxeType);
        typeBool = rootPackage.accessTypeCreate('Bool', new Position(0, 0, new Reader('', 'Bool.hx')), ClassHaxeType);
        typeInt = rootPackage.accessTypeCreate('Int', new Position(0, 0, new Reader('', 'Int.hx')), ClassHaxeType);
        typeFloat = rootPackage.accessTypeCreate('Float', new Position(0, 0, new Reader('', 'Float.hx')), ClassHaxeType);
    }

    public function unify(types:Array<HaxeType>):HaxeType {
        // @TODO
        if (types.length == 0) return typeDynamic;
        return types[0];
    }

    public function getType(path:String):HaxeType return rootPackage.accessType(path);

    public function getAllTypes():Array<HaxeType> return rootPackage.getAllTypes();

    public function getLeafPackageNames():Array<String> {
        return rootPackage.getLeafs().map(function(p:HaxePackage) return p.fqName);
    }
}
