package haxe.languageservices.type;

class HaxeTypes {
    public var rootPackage = new HaxePackage('');

    public function new() {
    }

    public function getLeafPackageNames():Array<String> {
        return [for (p in rootPackage.getLeafs()) p.fqName];
    }
}
