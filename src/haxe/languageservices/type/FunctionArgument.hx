package haxe.languageservices.type;

import haxe.languageservices.node.ZNode;
class FunctionArgument {
    public var opt:Bool;
    public var name:String;
    public var fqName:String;
    public var defaultValue:ZNode;
    public var doc:String;

    public function new(name:String, fqName:String, opt:Bool = false, defaultValue:ZNode = null, doc:String = '') {
        this.opt = opt;
        this.name = name;
        this.fqName = fqName;
        this.defaultValue = defaultValue;
        this.doc = doc;
    }

    public function toString() return '$name:$fqName';
}
