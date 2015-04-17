package haxe.languageservices.completion;
import haxe.languageservices.type.HaxeCompilerElement;
class CombinedCompletionProvider implements CompletionProvider {
    public var providers:Array<CompletionProvider>;
    public function new(providers:Array<CompletionProvider> = null) {
        if (providers == null) providers = [];
        this.providers = providers;
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        for (provider in providers) {
            provider.getEntries(out);
        }
        return out;
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        for (provider in providers) {
            var result = provider.getEntryByName(name);
            if (result != null) return result;
        }
        return null;
    }
}
