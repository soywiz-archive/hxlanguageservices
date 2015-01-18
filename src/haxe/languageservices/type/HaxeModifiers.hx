package haxe.languageservices.type;

class HaxeModifiers {
    public var isPublic:Bool = false;
    public var isPrivate:Bool = false;
    public var isInline:Bool = false;
    public var isStatic:Bool = false;
    public var isOverride:Bool = false;

    public function new() { }

    public function reset() {
        this.isOverride = false;
        this.isPrivate = false;
        this.isInline = false;
        this.isPublic = false;
        this.isStatic = false;
    }

    public function add(n:String):Void {
        switch (n) {
            case 'public': isPublic = true;
            case 'private': isPrivate = true;
            case 'inline': isInline = true;
            case 'static': isStatic = true;
            case 'override': isOverride = true;
            default: throw 'Invalid haxe modifier';
        }
    }
}
