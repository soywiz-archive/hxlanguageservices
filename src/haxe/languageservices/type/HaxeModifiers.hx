package haxe.languageservices.type;

import haxe.languageservices.node.ZNode;
class HaxeModifiers {
    public var mods:ZNode;
    public var isPublic:Bool = false;
    public var isPrivate:Bool = false;
    public var isInline:Bool = false;
    public var isStatic:Bool = false;
    public var isOverride:Bool = false;

    public function new(?mods:ZNode) { this.mods = mods; }
    
    public function clone():HaxeModifiers {
        var mods = new HaxeModifiers();
        mods.isPublic = this.isPublic;
        mods.isPrivate = this.isPrivate;
        mods.isInline = this.isInline;
        mods.isStatic = this.isStatic;
        mods.isOverride = this.isOverride;
        return mods;
    }

    public function reset() {
        this.isOverride = false;
        this.isPrivate = false;
        this.isInline = false;
        this.isPublic = false;
        this.isStatic = false;
    }

    public function addCloned(n:String):HaxeModifiers {
        return clone().add(n);
    }

    public function removeCloned(n:String):HaxeModifiers {
        return clone().remove(n);
    }

    public function add(n:String):HaxeModifiers {
        return set(n, true);
    }

    public function remove(n:String):HaxeModifiers {
        return set(n, false);
    }

    public function set(n:String, value:Bool):HaxeModifiers {
        switch (n) {
            case 'public': isPublic = value;
            case 'private': isPrivate = value;
            case 'inline': isInline = value;
            case 'static': isStatic = value;
            case 'override': isOverride = value;
            default: throw 'Invalid haxe modifier';
        }
        return this;
    }

    public function toString() {
        var out = [];
        if (isStatic) out.push('static');
        if (isInline) out.push('inline');
        if (isOverride) out.push('override');
        if (isPublic) out.push('public');
        if (isPrivate) out.push('private');
        return out.join(' ');
    }
}
