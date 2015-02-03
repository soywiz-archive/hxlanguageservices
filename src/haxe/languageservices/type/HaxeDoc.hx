package haxe.languageservices.type;
class HaxeDoc {
    public var text:String;

    public function new(text:String) {
        this.text = text;
    }

    public function toString() { return text; }
}
