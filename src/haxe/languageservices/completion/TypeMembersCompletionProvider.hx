package haxe.languageservices.completion;

import haxe.languageservices.type.HaxeModifiers;
import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;

class TypeMembersCompletionProvider implements CompletionProvider {
    private var type:HaxeType;
    private var filter: HaxeMember -> Bool;

    public function new(type:HaxeType, ?filter: HaxeMember -> Bool) {
        this.type = type;
        this.filter = filter;
    }
    
    static public function forType(type:HaxeType, viewInstance:Bool, viewPrivate:Bool):CompletionProvider {
        return new TypeMembersCompletionProvider(type, function(member:HaxeMember) {
            if (!viewInstance && !member.modifiers.isStatic) return false;
            if (!viewPrivate && member.modifiers.isPrivate) return false;
            return true;
        });
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        var member = this.type.getInheritedMemberByName(name);
        if (filter != null && !filter(member)) return null;
        if (member == null) return null;
        return member;
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        if (type != null) for (member in type.getAllMembers()) {
            if (filter != null && !filter(member)) continue;
            out.push(member);
        }
        return out;
    }
}
