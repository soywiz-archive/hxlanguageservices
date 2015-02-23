package haxe.languageservices.type;

class InterfaceHaxeType extends HaxeType {
    public var implementing = new Array<InterfaceHaxeType>();

    override public function hasAncestor(ancestor:HaxeType):Bool {
        for (i in implementing) if (i.hasAncestor(ancestor)) return true;
        return false;
    }

    public function getAllImplementingMembers(?out:Array<HaxeMember>):Array<HaxeMember> {
        if (out == null) out = [];
        for (i in implementing) i.getAllImplementingMembers(out);
        for (m in members) out.push(m);
        return out;
    }
}
