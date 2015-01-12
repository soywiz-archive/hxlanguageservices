package haxe.languageservices;

import haxe.languageservices.node.Position;
import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.util.Vfs;
import haxe.languageservices.parser.TypeContext;
import haxe.languageservices.parser.Completion.CompletionEntry;
import haxe.languageservices.parser.Completion.CompletionList;
import haxe.languageservices.parser.Completion.CCompletion;
import haxe.languageservices.parser.Completion.CompletionType;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.parser.Errors.ErrorContext;
import haxe.languageservices.parser.Parser;

class HaxeLanguageServices {
    private var vfs:Vfs;
    private var typeContext = new TypeContext();
    private var parsers = new Map<String, Parser>();
    public var classPaths = ["."];

    public function new(vfs:Vfs) {
        this.vfs = vfs;
    }
    
    public function updateHaxeScriptFile(path:String):Void {
        try {
            var parser = parsers[path] = new Parser(typeContext);
            var fileContent = vfs.readString(path);
            parser.setInputString(fileContent);
            var expr = parser.parseExpressions();
        } catch (e:Error) {
            throw new CompError(new CompPosition(e.pmin, e.pmax), '$e');
        }
    }

    public function updateHaxeFile(path:String):Void {
        try {
            var parser = parsers[path] = new Parser(typeContext);
            var fileContent = vfs.readString(path);
            parser.setInputString(fileContent);
            var expr = parser.parseHaxeFile();
        } catch (e:Error) {
            throw new CompError(new CompPosition(e.pmin, e.pmax), '$e');
        }
    }
    
    public function getCompletionAt(path:String, offset:Int):CompList {
        var clist = getParser(path).completionsAt(offset);
        return new CompList([for (e in clist.items) new CompEntry(e.name, typeConvert(e.type))]);
    }
    
    public function getReferencesAt(path:String, offset:Int):Array<CompReference> {
        return null;
    }
    
    public function getIdAt(path:String, offset:Int):{ pos: CompPosition, name: String } {
        return null;
    }
    
    public function getCallInfoAt(path:String, offset:Int):CompCall {
        return switch (getParser(path).callCompletionAt(offset)) {
            case CCompletion.CallCompletion(baseType, name, args, ret, argIndex, doc):
                return new CompCall(
                    baseType, name,
                    [for (arg in args) new CompArgument(arg.name, typeConvert(arg.type), arg.optional, arg.doc)],
                    new CompReturn(typeConvert(ret.type), ret.doc),
                    argIndex, doc
                );
            default:
                return null;
        }
    }

    public function getErrors(path:String):Array<CompError> {
        var parser:Parser = parsers[path];
        return [for (e in parser.errors.errors) new CompError(new CompPosition(e.pmin, e.pmax), '$e')];
    }

    private function getParser(path:String):Parser {
        var parser:Parser = parsers[path];
        if (parser == null) throw 'Can\'t find parser for file $path';
        return parser;
    }

    static private function typeConvert(type:CompletionType):CompType {
        return new CompType(CompletionTypeUtils.toString(type));
    }
}

enum CompReferenceType {
    Declaration;
    Update;
    Read;
}

typedef CompReference = {
    var pos:CompPosition;
    var type:CompReferenceType;
}

class CompPosition {
    public var min:Int;
    public var max:Int;
    public function new(min:Int, max:Int) { this.min = min; this.max = max; }
}

class CompError {
    public var pos:CompPosition;
    public var text:String;
    public function new(pos:CompPosition, text:String) { this.pos = pos; this.text = text; }
}

class CompArgument {
    var name: String;
    var type: CompType;
    var optional: Bool;
    var doc: String;

    public function new(name:String, type: CompType, optional: Bool, doc:String) {
        this.name = name;
        this.type = type;
        this.optional = optional;
        this.doc = doc;
    }
}

class CompReturn {
    var type: CompType;
    var doc: String;
    
    public function new(type:CompType, doc:String) {
        this.type = type;
        this.doc = doc;
    } 
}

class CompCall {
    public var baseType:String;
    public var name:String;
    public var args:Array<CompArgument>;
    public var ret:CompReturn;
    public var argIndex:Int;
    public var doc:String;

    public function new(baseType:String, name:String, args:Array<CompArgument>, ret:CompReturn, argIndex:Int, doc:String) {
        this.baseType = baseType;
        this.name = name;
        this.args = args;
        this.ret = ret;
        this.argIndex = argIndex;
        this.doc = doc;
    }
}

class CompList {
    public var items:Array<CompEntry>;

    public function new(items:Array<CompEntry>) {
        this.items = items;
    }

    public function toString() {
        return [for (completion in items) '${completion.name}:${completion.type}'].toString();
    }
}

class CompEntry {
    public var name:String;
    public var type:CompType;

    public function new(name:String, type:CompType) { this.name = name; this.type = type; }
}

class CompType {
    public var str:String;
    public function new(str:String) { this.str = str; }
    public function toString() return str;
}