package haxe.languageservices.completion;
import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.type.HaxeTypes;
class TypesCompletionProvider implements CompletionProvider {
    private var types:HaxeTypes;

    public function new(types:HaxeTypes) {
        this.types = types;
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        for (type in types.getAllTypes()) out.push(type);
        return out;
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        //var _package = types.getPackage(name);
        //if (_package != null) return _package;
        var _type = types.getType(name);
        if (_type != null) return _type;
        return null;
    }
}
