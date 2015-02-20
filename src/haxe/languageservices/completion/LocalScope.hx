package haxe.languageservices.completion;
import haxe.languageservices.type.HaxeCompilerElement;

class LocalScope implements CompletionProvider {
    public var parent:CompletionProvider;
    private var locals:Array<HaxeCompilerElement> = [];
    
    public function new(?parent:CompletionProvider) {
        this.parent = parent;
    }
    
    public function add(local:HaxeCompilerElement) {
        locals.push(local);
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        for (local in locals) out.push(local);
        if (parent != null) parent.getEntries(out);
        return out;
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        for (local in locals) if (local.getName() == name) return local;
        if (parent != null) return parent.getEntryByName(name);
        return null;
    }
}
