package haxe.languageservices.completion;

import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.type.HaxeModifiers;
import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;

class TypeMembersCompletionProvider implements CompletionProvider {
    private var stype:SpecificHaxeType;
    private var filter: HaxeMember -> Bool;

    private function new(stype:SpecificHaxeType, ?filter: HaxeMember -> Bool) {
        this.stype = stype;
        this.filter = filter;
    }

    static public function forGenericType(type:HaxeType, viewInstance:Bool, viewPrivate:Bool):CompletionProvider {
        return forSpecificType(new SpecificHaxeType(type.types, type), viewInstance, viewPrivate);
    }

    static public function forSpecificType(stype:SpecificHaxeType, viewInstance:Bool, viewPrivate:Bool):CompletionProvider {
        return new TypeMembersCompletionProvider(stype, function(member:HaxeMember) {
            if (!viewInstance && !member.modifiers.isStatic) return false;
            if (!viewPrivate && member.modifiers.isPrivate) return false;
            return true;
        });
    }

    private function getReadType() {
        if (this.stype == null) return null;
        if (this.stype.type == stype.types.typeClass) return this.stype.parameters[0].type;
        return this.stype.type;
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        var member = getReadType().getInheritedMemberByName(name);
        if (filter != null && !filter(member)) return null;
        if (member == null) return null;
        return member;
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        if (getReadType() != null) for (member in getReadType().getAllMembers()) {
            if (filter != null && !filter(member)) continue;
            out.push(member);
        }
        return out;
    }
}
