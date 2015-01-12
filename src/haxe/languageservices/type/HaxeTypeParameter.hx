package haxe.languageservices.type;

class HaxeTypeParameter {
    public var name:String;
    public var constraints:Array<HaxeType>;

    public function new(name:String, constraints:Array<HaxeType>) {
        this.name = name;
        this.constraints = constraints;
    }
}
