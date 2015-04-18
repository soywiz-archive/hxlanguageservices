package haxe.languageservices.type;

class InterfaceHaxeType extends HaxeType {
    public var implementing = new Array<TypeReference>();

    override public function getAllBaseTypes():Array<HaxeType> {
        var out = super.getAllBaseTypes();
        for (interfaze in implementing) out = out.concat(interfaze.getType().getAllBaseTypes());
        return out;
    }

    override public function hasAncestor(ancestor:HaxeType):Bool {
        for (i in implementing) if (i.getType().hasAncestor(ancestor)) return true;
        return false;
    }

    public function getAllImplementingMembers(?out:Array<HaxeMember>):Array<HaxeMember> {
        if (out == null) out = [];
        for (i in implementing) i.getInterface().getAllImplementingMembers(out);
        for (m in members) out.push(m);
        return out;
    }
}
