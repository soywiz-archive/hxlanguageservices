package haxe.languageservices;

import haxe.languageservices.type.UsageType;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.type.FunctionHaxeType;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.HaxeLanguageServices.FunctionCompType;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.grammar.Grammar.Result;
import haxe.languageservices.grammar.HaxeTypeChecker;
import haxe.languageservices.grammar.HaxeTypeBuilder;
import haxe.languageservices.grammar.HaxeCompletion;
import haxe.languageservices.grammar.HaxeErrors;
import haxe.languageservices.grammar.HaxeGrammar;
import haxe.languageservices.grammar.Grammar.Term;
import haxe.languageservices.node.Reader;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.node.Position;
import haxe.languageservices.util.Vfs;

class HaxeLanguageServices {
    private var vfs:Vfs;
    private var types = new HaxeTypes();
    private var contexts = new Map<String, CompFileContext>();
    public var classPaths = ["."];

    public function new(vfs:Vfs) {
        this.vfs = vfs;
    }
    
    public function updateHaxeFile(path:String):Void {
        try {
            var context:CompFileContext;
            if (!contexts.exists(path)) contexts[path] = new CompFileContext(types);
            context = contexts[path];
            var fileContent = vfs.readString(path);
            context.setFile(fileContent, path);
            context.update();
        } catch (e:Dynamic) {
            #if js
            try { js.Browser.window.console.error(e.stack); } catch (e2:Dynamic) {}
            js.Browser.window.console.error(e);
            #end
            //trace(e);
            throw new CompError(new CompPosition(0, 0), 'unexpected error: $e');
        }
    }
    
    public function getFileTypes(path:String):Array<CompType> {
        var context = getContext(path);
        return null;
    }

    public function getTypeMembers(path:String):Array<String> {
        return null;
    }
    
    public function getCompletionAt(path:String, offset:Int):CompList {
        var context = getContext(path);
        if (context.completionScope == null) return new CompList([]);
        var scope2 = context.completionScope.locateIndex(offset);
        if (scope2 == null) return new CompList([]);
        var locals = scope2.getEntries();
        return new CompList([for (l in locals) Conv.toEntry(l.getName(), l.getResult())]);
    }

    public function getReferencesAt(path:String, offset:Int):CompReferences {
        var context = getContext(path);
        var id = getIdAt(path, offset);
        if (id == null) return null;
        var entry = context.completionScope.locateIndex(offset).getEntryByName(id.name);
        if (entry == null) return null;
        return new CompReferences(id.name, [for (usage in entry.getReferences().usages) new CompReference(Conv.pos(usage.pos), Conv.usageType(usage.type)) ]);
    }
    
    public function getIdAt(path:String, offset:Int):{ pos: CompPosition, name: String } {
        var context = getContext(path);
        if (context.completionScope == null) return null;
        var id = context.completionScope.getIdentifierAt(offset);
        if (id == null) return null;
        return {
            pos: Conv.pos(id.pos),
            name: id.name
        };
    }
    
    public function getCallInfoAt(path:String, offset:Int):CompCall {
        /*
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
        */
        return null;
    }

    public function getErrors(path:String):Array<CompError> {
        var context:CompFileContext = getContext(path);
        return [for (error in context.errors.errors) new CompError(Conv.pos(error.pos), error.message)];
    }

    private function getContext(path:String):CompFileContext {
        var context:CompFileContext = contexts[path];
        if (context == null) throw 'Can\'t find context for file $path';
        return context;
    }
    
    //static private function convertType(type:CompletionType):CompType {
    //    return new CompType(CompletionTypeUtils.toString(type));
    //}
}

class Conv {
    static public function toEntry(name:String, result:ExpressionResult):CompEntry {
        return new CompEntry(name, Conv.toType(result.type), result.hasValue, result.value);
    }

    static public function usageType(type:UsageType):CompReferenceType {
        switch (type) {
            case UsageType.Declaration: return CompReferenceType.Declaration;
            case UsageType.Read: return CompReferenceType.Read;
            case UsageType.Write: return CompReferenceType.Update;
        }
    }

    static public function pos(pos:Position):CompPosition {
        return new CompPosition(pos.min, pos.max);
    }

    static public function toType(type:SpecificHaxeType):CompType {
        if (Std.is(type.type, FunctionHaxeType)) {
            var ftype = cast(type.type, FunctionHaxeType);
            return new FunctionCompType([for (a in ftype.args) new BaseCompType(a.fqName)], new BaseCompType(ftype.retval.fqName));
        }
        return new BaseCompType(type.type.fqName, (type.parameters != null) ? [for (i in type.parameters) Conv.toType(i)] : null);
    }
}

class CompFileContext {
    static private var grammar = new HaxeGrammar();
    public var reader:Reader;
    public var term:Term;
    public var types:HaxeTypes;
    public var typeBuilder:HaxeTypeBuilder;
    public var typeChecker:HaxeTypeChecker;
    public var completion:HaxeCompletion;
    public var completionScope:CompletionScope;
    public var grammarResult:Result;
    public var rootNode:ZNode;
    public var errors:HaxeErrors = new HaxeErrors();
    public var builtTypes:Array<HaxeType> = [];
    public function new(types:HaxeTypes) { this.types = types; }

    private function removeOldTypes() {
        //trace('before:' + types.getAllTypes());
        for (type in builtTypes) {
            //trace('remove:' + type);
            type.remove();
        }
        builtTypes = [];
        //trace('after:' + types.getAllTypes());
    }

    public function setFile(str:String, file:String) {
        this.reader = new Reader(str, file);
        this.term = grammar.program;
    }

    public function update():Void {
        removeOldTypes();
        reader.reset();
        errors.reset();
        grammarResult = grammar.parse(term, reader, errors);
        typeBuilder = new HaxeTypeBuilder(types, errors);
        typeChecker = new HaxeTypeChecker(types, errors);
        completion = new HaxeCompletion(types, errors);
        completionScope = null;
        switch (grammarResult) {
            case Result.RUnmatched(_, _) | Result.RMatched: rootNode = null;
            case Result.RMatchedValue(value): rootNode = cast(value);
        }
        if (rootNode != null) {
            builtTypes = [];
            typeBuilder.process(rootNode, builtTypes);
            //trace('builtTypes:' + builtTypes);
            for (type in builtTypes) typeChecker.checkType(type);
            completionScope = completion.processCompletion(rootNode);
        }
        //typeBuilder.
    } 
}

enum CompReferenceType {
    Declaration;
    Update;
    Read;
}

class CompReferences {
    public var name:String;
    public var list:Array<CompReference>;
    public function new(name:String, list:Array<CompReference>) {
        this.name = name;
        this.list = list;
    }
    public function toString() return '$name:$list';
}

class CompReference {
    public var pos:CompPosition;
    public var type:CompReferenceType;
    public function new(pos:CompPosition, type:CompReferenceType) {
        this.pos = pos;
        this.type = type;
    }
    public function toString() return '$pos:$type';
}

class CompPosition {
    public var min:Int;
    public var max:Int;
    public function new(min:Int, max:Int) { this.min = min; this.max = max; }
    public function toString() return '$min:$max';
}

class CompError {
    public var pos:CompPosition;
    public var text:String;
    public function new(pos:CompPosition, text:String) { this.pos = pos; this.text = text; }
    public function toString() return '$pos:$text';
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
    public var hasValue:Bool;
    public var value:Dynamic;

    public function new(name:String, type:CompType, hasValue:Bool, value:Dynamic) {
        this.name = name;
        this.type = type;
        this.hasValue = hasValue;
        this.value = value;
    }
    public function toString() {
        if (hasValue) {
            if (Std.is(value, String)) return '$name:$type = "$value"';
            return '$name:$type = $value';
        }
        return '$name:$type';
    }
}

interface CompType {
    function toString():String;
}

class BaseCompType implements CompType {
    public var str:String;
    public var types:Array<CompType>;
    public function new(str:String, ?types:Array<CompType>) {
        if (types == null) types = [];
        this.str = str;
        this.types = types;
    }
    public function toString() {
        if (types != null && types.length > 0) return str + '<' + types.join(',') + '>';
        return str;
    }
}

class FunctionCompType implements CompType {
    public var args:Array<CompType>;
    public var retval:CompType;
    public function new(args:Array<CompType>, retval:CompType) {
        this.args = args;
        this.retval = retval;
    }
    public function toString() {
        if (args.length == 0) return 'Void -> ' + retval;
        return args.concat([retval]).join(' -> ');
    }
}