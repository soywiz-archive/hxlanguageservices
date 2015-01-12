package haxe.languageservices.type;

class HaxeType {
    public var packag:HaxePackage;
    public var name:String;
    public var fqName:String;
    
    public var typeParameters = new Array<HaxeTypeParameter>();
    public var members = new Array<HaxeMember>();
    public var membersByName = new Map<String, HaxeMember>();

    public function new(packag:HaxePackage, name:String) {
        this.packag = packag;
        this.name = name;
        this.fqName = (packag.fqName != '') ? '${packag.fqName}.$name' : name;
    }
    
    public function toString() return 'Type("$fqName", $members)';
    
    public function addMember(member:HaxeMember) {
        members.push(member);
        membersByName.set(member.name, member);
    }
}

class ClassHaxeType extends HaxeType {
    public var extending:HaxeType;
    public var implementing = new Array<HaxeType>();
}

class EnumHaxeType extends HaxeType {
}

class TypedefHaxeType extends HaxeType {
    public var destType:HaxeType;
}
