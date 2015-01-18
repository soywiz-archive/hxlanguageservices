package haxe.languageservices.type;

class ClassHaxeType extends HaxeType {
    public var extending:TypeReference;
    public var implementing:Array<TypeReference> = [];

    private function getExtending():ClassHaxeType {
        if (extending == null) return null;
        return extending.getClass();
    }

    override public function getAllMembers(?out2:Array<HaxeMember>):Array<HaxeMember> {
        var out = super.getAllMembers(out2);
        if (extending != null) getExtending().getAllMembers(out);
        return out;
    }

    override public function getInheritedMemberByName(name:String):HaxeMember {
        var result = super.getInheritedMemberByName(name);
        if (result == null && extending != null) return extending.getType().getInheritedMemberByName(name);
        return result;
    }

    public function getAncestorMembers():Map<String, HaxeMember> {
        if (getExtending() == null) return new Map<String, HaxeMember>();
        return getExtending().getThisAndAncestorMembers();
    }

    public function getThisMembers():Map<String, HaxeMember> return membersByName;

    public function getThisAndAncestorMembers(?out:Map<String, HaxeMember>):Map<String, HaxeMember> {
        if (out == null) out = new Map<String, HaxeMember>();
        for (m in members) out.set(m.name, m);
        if (getExtending() != null) getExtending().getThisAndAncestorMembers(out);
        return out;
    }

    public function getAllExpectedImplementingMembers():Array<HaxeMember> {
        var out = new Array<HaxeMember>();
        for (i in implementing) {
            var ii = i.getInterface();
            if (ii != null) ii.getAllImplementingMembers(out);
        }
        return out;
    }
}
