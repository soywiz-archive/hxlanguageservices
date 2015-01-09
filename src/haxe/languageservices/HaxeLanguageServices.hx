package haxe.languageservices;

import haxe.languageservices.parser.TypeContext;
import haxe.languageservices.parser.Completion.CompletionEntry;
import haxe.languageservices.parser.Completion.CompletionList;
import haxe.languageservices.parser.Errors.ErrorContext;
import haxe.languageservices.parser.Parser;

class HaxeLanguageServices {
    private var fileProvider:HaxeFileProvider;
    private var typeContext = new TypeContext();
    private var parsers = new Map<String, Parser>();

    public function new(fileProvider:HaxeFileProvider) {
        this.fileProvider = fileProvider;
    }

    public function updateFile(path:String):Void {
        var parser = new Parser(typeContext);
        var fileContent = fileProvider.readFile(path);
        parser.setInputString(fileContent);
        var expr = parser.parseExpressions();
        parsers[path] = parser;
    }

    public function getCompletionAt(path:String, offset:Int):CompletionList {
        var parser:Parser = parsers[path];
        return parser.completionsAt(offset);
    }
    
    public function getCallInfoAt(path:String, offset:Int):Dynamic {
        return null;
    }

    public function getErrors(path:String):ErrorContext {
        var parser:Parser = parsers[path];
        return parser.errors;
    }
}

class LambdaHaxeFileProvider implements HaxeFileProvider {
    private var _readFile: String -> String;

    public function new(readFile: String -> String) {
        this._readFile = readFile;
    }

    public function readFile(path:String):String return _readFile(path);
}

interface HaxeFileProvider {
    function readFile(path:String):String;
} 
