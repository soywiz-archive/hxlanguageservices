package haxe.languageservices.grammar;
import haxe.languageservices.grammar.ParserError;
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

        // Check extending
        if (type.extending != null) {
            var t2 = type.extending.getType();
            var t2p = type.extending.expr.pos;
            if (t2 == null) {
                errors.add(new ParserError(t2p, 'type ${type.extending.fqName} not defined'));
            } else if (!Std.is(t2, ClassHaxeType)) {
                errors.add(new ParserError(t2p, 'type ${type.extending.fqName} is not a class'));
            } else {
            }
        }
        
        // Check implementing
        for (i in type.implementing) {
            var t2 = i.getType();
            var t2p = i.expr.pos;
            if (t2 == null) {
                errors.add(new ParserError(t2p, 'type ${i.fqName} not defined'));
            } else if (!Std.is(t2, InterfaceHaxeType)) {
                errors.add(new ParserError(t2p, 'type ${i.fqName} is not an interface'));
            } else {
            }
        } 

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
                var ancestorMem:HaxeMember = ancestorMembers[mem.name];
                if (!mem.modifiers.isOverride) {
                    errors.add(new ParserError(mem.pos, 'member ${mem.name} must override'));
                }
                if (ancestorMem.modifiers.isStatic) {
                    errors.add(new ParserError(mem.pos, 'static member ${mem.name} cannot be overriden'));
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

class A {
    private function test() if (true) 1; else 2;
}