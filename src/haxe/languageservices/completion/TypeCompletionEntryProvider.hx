package haxe.languageservices.completion;

import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;

class TypeCompletionEntryProvider implements CompletionEntryProvider {
    private var type:HaxeType;
    private var filter: HaxeMember -> Bool;

    public function new(type:HaxeType, ?filter: HaxeMember -> Bool) {
        this.type = type;
        this.filter = filter;
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        var member = type.getInheritedMemberByName(name);
        if (filter != null && !filter(member)) return null;
        if (member == null) return null;
        return member;
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        for (member in type.getAllMembers()) {
            if (filter != null && !filter(member)) continue;
            out.push(member);
        }
        return out;
    }
}
