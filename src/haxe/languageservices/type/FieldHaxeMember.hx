package haxe.languageservices.type;

class FieldHaxeMember extends HaxeMember {
    public var fieldtype:TypeReference;
    override public function toString() return 'Field($name)';
}
