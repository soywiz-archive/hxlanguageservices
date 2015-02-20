package haxe.languageservices.completion;
import haxe.languageservices.type.HaxeCompilerElement;
class CombinedCompletionProvider implements CompletionProvider {
    private var providers:Array<CompletionProvider>;

    public function new(providers:Array<CompletionProvider>) {
        this.providers = providers;
    }

    function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        for (provider in providers) out = provider.getEntries(out);
        return out;
    }
    
    function getEntryByName(name:String):HaxeCompilerElement {
        for (provider in providers) {
            var result = provider.getEntryByName(name);
            if (result != null) return result;
        }
        return null;
    }
}
