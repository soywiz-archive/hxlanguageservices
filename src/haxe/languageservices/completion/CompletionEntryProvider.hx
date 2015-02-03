package haxe.languageservices.completion;

import haxe.languageservices.type.HaxeCompilerElement;
interface CompletionEntryProvider {
    function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement>;
    function getEntryByName(name:String):HaxeCompilerElement;
}
