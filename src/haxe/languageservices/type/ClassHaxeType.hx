package haxe.languageservices.type;

using Lambda;

class ClassHaxeType extends HaxeType {
    public var extending:TypeReference;
    public var implementing:Array<TypeReference> = [];

    private function getExtending():ClassHaxeType {
        if (extending == null) return null;
        return extending.getClass();
    }

    override public function hasAncestor(ancestor:HaxeType):Bool {
        if (extending != null && extending.getType().hasAncestor(ancestor)) return true;
        for (i in implementing) if (i.getType().hasAncestor(ancestor)) return true;
        return false;
    }

    override public function getAllMembers(?out2:Array<HaxeMember>):Array<HaxeMember> {
        var out = super.getAllMembers(out2);
        var extending = getExtending();
        if (extending != null) extending.getAllMembers(out);
        return out;
    }

    override public function getInheritedMemberByName(name:String):HaxeMember {
        var result = super.getInheritedMemberByName(name);
        if (result == null) {
            var extending = getExtending();
            if (extending != null) return extending.getInheritedMemberByName(name);
        }
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

    override public function canAssignTo(that:HaxeType):Bool {
        for (i in implementing) {
            if (i.fqName == that.fqName) return true;
        }
        if (extending != null && that.fqName == extending.fqName) return true;
        return super.canAssignTo(that);
    }
}
