package haxe.languageservices.type;

import haxe.languageservices.node.ZNode;

class TypeReference {
    public var types:HaxeTypes;
    public var fqName:String;
    public var expr:ZNode;
    public function new(types:HaxeTypes, fqName:String, expr:ZNode) { this.types = types; this.fqName = fqName; this.expr = expr; }
    public function getType() return types.getType(fqName);
    public function getClass() return types.getClass(fqName);
    public function getInterface() return types.getInterface(fqName);
}
