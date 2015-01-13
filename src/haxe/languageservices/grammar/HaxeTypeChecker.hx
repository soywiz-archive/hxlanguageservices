package haxe.languageservices.grammar;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.node.ZNode;

class HaxeTypeChecker {
    public var errors:HaxeErrors;
    private var types:HaxeTypes;

    public function new(types:HaxeTypes, errors:HaxeErrors) {
        this.types = types;
        this.errors = errors;
    }

    public function checkType(type:HaxeType) {
        if (Std.is(type, ClassHaxeType)) {
            //errors.add(new ParserError(type.pos, 'test'));
            checkClass(cast(type, ClassHaxeType));
        }
    }
    
    private function checkClass(type:ClassHaxeType) {
        var expectedImplementingMembers = type.getAllExpectedImplementingMembers();
        var allMembers = type.getThisAndAncestorMembers();
        var ancestorMembers =  type.getAncestorMembers();
        var thisMembers = type.getThisMembers();

        // Check implementing methods
        for (mem in expectedImplementingMembers) {
            if (!allMembers.exists(mem.name)) {
                errors.add(new ParserError(type.pos, 'member ${mem.name} not implemented'));
            }
            // @TODO: Check compatible signature
        }
        
        // Check extending methods
        for (_mem in thisMembers) {
            var mem:HaxeMember = _mem;
            if (ancestorMembers.exists(mem.name)) {
                if (!mem.modifiers.isOverride) {
                    errors.add(new ParserError(mem.pos, 'member ${mem.name} must override'));
                }
            } else {
                if (mem.modifiers.isOverride) {
                    errors.add(new ParserError(mem.pos, 'member ${mem.name} not overriding anything'));
                }
            }
        }

        // Check overriding invalid
        
        for (member in type.members) {
            var expectedType = getType(member.typeNode);
            var expressionType = getType(member.valueNode);
            if (!expectedType.canAssign(expressionType)) {
            //if (true) {
                errors.add(new ParserError(member.pos, 'expression cannnot be assigned to explicit type'));
            }
        }
    }
    
    private function getType(node:ZNode):HaxeType {
        return types.getType('Dynamic');
    }
}
