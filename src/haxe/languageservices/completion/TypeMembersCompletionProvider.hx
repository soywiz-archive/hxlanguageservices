package haxe.languageservices.completion;

import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.type.HaxeModifiers;
import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;

class TypeMembersCompletionProvider implements CompletionProvider {
    private var stype:SpecificHaxeType;
    private var stypeShow:SpecificHaxeType;
    private var filter: HaxeMember -> Bool;

    private function new(stype:SpecificHaxeType, ?filter: HaxeMember -> Bool) {
        this.stype = stype;
        this.stypeShow = stype;
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

    public function getEntryByName(name:String):HaxeCompilerElement {
        var member = stypeShow.getInheritedMemberByName(name);
        if (filter != null && !filter(member)) return null;
        if (member == null) return null;
        return member;
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        if (stypeShow != null) for (member in stypeShow.getAllMembers()) {
            if (filter != null && !filter(member)) continue;
            out.push(member);
        }
        return out;
    }
}
