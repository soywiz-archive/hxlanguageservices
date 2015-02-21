package haxe.languageservices.type;

class FieldHaxeMember extends HaxeMember {
    public var fieldtype:FunctionRetval;
    override public function toString() return 'Field($name)';
}
