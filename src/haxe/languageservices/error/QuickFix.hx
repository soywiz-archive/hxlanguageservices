package haxe.languageservices.error;
class QuickFix {
    public var name:String;
    public var fixer:Void -> Array<QuickFixAction>;

    public function new(name:String, fixer:Void -> Array<QuickFixAction>) {
        this.name = name;
        this.fixer = fixer;
    }
}
