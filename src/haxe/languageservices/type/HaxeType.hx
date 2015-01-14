package haxe.languageservices.type;

import haxe.languageservices.type.HaxeType.ClassHaxeType;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Position;
class HaxeType {
    public var pos:Position;
    public var packag:HaxePackage;
    public var types:HaxeTypes;
    public var name:String;
    public var fqName:String;
    
    public var typeParameters = new Array<HaxeTypeParameter>();
    public var members = new Array<HaxeMember>();
    public var membersByName = new Map<String, HaxeMember>();

    public var node:ZNode;

    public function new(packag:HaxePackage, pos:Position, name:String) {
        this.packag = packag;
        this.types = packag.base;
        this.pos = pos;
        this.name = name;
        this.fqName = (packag.fqName != '') ? '${packag.fqName}.$name' : name;
    }
    
    public function toString() return 'Type("$fqName", $members)';
    
    public function existsMember(name:String):Bool return membersByName.exists(name);
    public function getMember(name:String):HaxeMember return membersByName[name];
    
    public function addMember(member:HaxeMember):Void {
        members.push(member);
        membersByName.set(member.name, member);
    }

    public function remove() {
        packag.types.remove(this.name);
    }

    public function canAssign(that:HaxeType):Bool {
        // @TODO
        return true;
    }
}

class TypeReference {
    public var types:HaxeTypes;
    public var fqName:String;
    public var expr:ZNode;
    public function new(types:HaxeTypes, fqName:String, expr:ZNode) { this.types = types; this.fqName = fqName; this.expr = expr; }
    public function getType() return types.getType(fqName);
    public function getClass() return types.getClass(fqName);
    public function getInterface() return types.getInterface(fqName);
}

class ClassHaxeType extends HaxeType {
    public var extending:TypeReference;
    public var implementing:Array<TypeReference> = [];
    
    private function getExtending():ClassHaxeType {
        if (extending == null) return null;
        return extending.getClass();
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
