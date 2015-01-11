package haxe.languageservices.grammar.type;

import haxe.languageservices.grammar.type.HaxePackage;
class HaxeType {
    public var packag:HaxePackage;
    public var name:String;
    public var members = new Array<HaxeMember>();
    public var membersByName = new Map<String, HaxeMember>();

    public function new(packag:HaxePackage, name:String) { this.packag = packag; this.name = name; }
    public function addMember(member:HaxeMember) {
        members.push(member);
        membersByName.set(member.name, member);
    }
}

class ClassHaxeType extends HaxeType {
}

class EnumHaxeType extends HaxeType {
}

class TypedefHaxeType extends HaxeType {
}
