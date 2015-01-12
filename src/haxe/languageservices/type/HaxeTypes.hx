package haxe.languageservices.type;

import haxe.languageservices.node.ZNode;
import haxe.languageservices.type.HaxeType.ClassHaxeType;
import haxe.languageservices.node.Position;
class HaxeTypes {
    public var rootPackage:HaxePackage;
    public var typeDynamic(default, null):HaxeType;
    public var typeInt(default, null):HaxeType;
    public var typeFloat(default, null):HaxeType;

    public function new() {
        rootPackage = new HaxePackage(this, '');
        typeDynamic = rootPackage.accessTypeCreate('Dynamic', new Position(0, 0), ClassHaxeType);
        typeInt = rootPackage.accessTypeCreate('Int', new Position(0, 0), ClassHaxeType);
        typeFloat = rootPackage.accessTypeCreate('Float', new Position(0, 0), ClassHaxeType);
    }

    public function unify(types:Array<HaxeType>):HaxeType {
        // @TODO
        if (types.length == 0) return getType('Dynamic');
        return types[0];
    }

    public function getType(path:String):HaxeType return rootPackage.accessType(path);

    public function getAllTypes():Array<HaxeType> return rootPackage.getAllTypes();

    public function getLeafPackageNames():Array<String> {
        return rootPackage.getLeafs().map(function(p:HaxePackage) return p.fqName);
    }
}
