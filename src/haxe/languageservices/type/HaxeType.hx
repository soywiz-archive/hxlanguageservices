package haxe.languageservices.type;

import js.html.svg.AnimatedBoolean;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Position;
class HaxeType {
    public var pos:Position;
    public var packag:HaxePackage;
    public var types:HaxeTypes;
    public var name:String;
    //public var nameNode:String;
    public var fqName:String;
    
    public var typeParameters = new Array<HaxeTypeParameter>();
    public var members = new Array<HaxeMember>();
    private var membersByName = new Map<String, HaxeMember>();

    public var node:ZNode;
    
    public function getAllMembers(?out:Array<HaxeMember>):Array<HaxeMember> {
        if (out == null) out = [];
        for (member in members) out.push(member);
        return out;
    }
    
    public function getInheritedMemberByName(name:String):HaxeMember {
        return membersByName[name];
    }

    public function new(packag:HaxePackage, pos:Position, name:String) {
        this.packag = packag;
        this.types = packag.base;
        this.pos = pos;
        this.name = name;
        this.fqName = (packag.fqName != '') ? '${packag.fqName}.$name' : name;
    }
    
    public function getName() return 'Type("$fqName", $members)';
    public function toString() return '$fqName';

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
