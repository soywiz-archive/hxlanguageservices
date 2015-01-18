package haxe.languageservices.type;

class FunctionRetval {
    public var fqName:String;
    public var doc:String;

    public function new(fqName:String, doc:String = '') {
        this.fqName = fqName;
        this.doc = doc;
    }
    public function toString() return fqName;
}
