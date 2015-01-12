package haxe.languageservices.type;

import haxe.languageservices.node.Position;
class HaxeType {
    public var pos:Position;
    public var packag:HaxePackage;
    public var name:String;
    public var fqName:String;
    
    public var typeParameters = new Array<HaxeTypeParameter>();
    public var members = new Array<HaxeMember>();
    public var membersByName = new Map<String, HaxeMember>();

    public function new(packag:HaxePackage, pos:Position, name:String) {
        this.packag = packag;
        this.pos = pos;
        this.name = name;
        this.fqName = (packag.fqName != '') ? '${packag.fqName}.$name' : name;
    }
    
    public function toString() return 'Type("$fqName", $members)';
    
    public function addMember(member:HaxeMember) {
        members.push(member);
        membersByName.set(member.name, member);
    }

    public function canAssign(that:HaxeType):Bool {
        // @TODO
        return true;
    }
}

class ClassHaxeType extends HaxeType {
    public var extending:ClassHaxeType;
    public var implementing:Array<InterfaceHaxeType> = new Array<InterfaceHaxeType>();

    public function getAncestorMembers():Map<String, HaxeMember> {
        if (extending == null) return new Map<String, HaxeMember>();
        return extending.getThisAndAncestorMembers();
    }
    
    public function getThisMembers():Map<String, HaxeMember> return membersByName;
    
    public function getThisAndAncestorMembers(?out:Map<String, HaxeMember>):Map<String, HaxeMember> {
        if (out == null) out = new Map<String, HaxeMember>();
        for (m in members) out.set(m.name, m);
        if (extending != null) extending.getThisAndAncestorMembers(out);
        return out;
    }

    public function getAllExpectedImplementingMembers():Array<HaxeMember> {
        var out = new Array<HaxeMember>();
        for (i in implementing) i.getAllImplementingMembers(out);
        return out;
    }
}

class InterfaceHaxeType extends HaxeType {
    public var implementing = new Array<InterfaceHaxeType>();

    public function getAllImplementingMembers(?out:Array<HaxeMember>):Array<HaxeMember> {
        if (out == null) out = [];
        for (i in implementing) i.getAllImplementingMembers(out);
        for (m in members) out.push(m);
        return out;
    }
}

class EnumHaxeType extends HaxeType {
}

class TypedefHaxeType extends HaxeType {
    public var destType:HaxeType;
}
