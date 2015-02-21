package haxe.languageservices;

import haxe.languageservices.completion.CallInfo;
import haxe.languageservices.grammar.GrammarResult;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.FunctionRetval;
import haxe.languageservices.type.FunctionArgument;
import haxe.languageservices.type.UsageType;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.type.FunctionHaxeType;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.HaxeLanguageServices.FunctionCompType;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.grammar.GrammarResult;
import haxe.languageservices.grammar.HaxeTypeChecker;
import haxe.languageservices.grammar.HaxeTypeBuilder;
import haxe.languageservices.error.HaxeErrors;
import haxe.languageservices.grammar.HaxeGrammar;
import haxe.languageservices.grammar.GrammarTerm;
import haxe.languageservices.node.Reader;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.util.Vfs;

class HaxeLanguageServices {
    private var vfs:Vfs;
    private var types = new HaxeTypes();
    private var conv:Conv;
    private var contexts = new Map<String, CompFileContext>();
    public var classPaths = ["."];

    public function new(vfs:Vfs) {
        this.vfs = vfs;
        this.conv = new Conv(types);
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
    
    public function getFileTypes(path:String):Array<HaxeType> {
        var context = getContext(path);
        return null;
    }

    public function getTypeMembers(fqName:String):Array<HaxeMember> {
        return types.getType(fqName).getAllMembers();
    }
    
    /**
     * Get a list of possible identifiers used in an offset with type information
     **/
    public function getCompletionAt(path:String, offset:Int):CompList {
        var context = getContext(path);
        
        var scope2 = context.rootNode.locateIndex(offset).getCompletion();
        if (scope2 == null) return new CompList([]);
        var locals = scope2.getEntries();
        return new CompList([for (l in locals) conv.toEntry(l.getName(), l.getResult())]);
    }

    public function getReferencesAt(path:String, offset:Int):CompReferences {
        var context = getContext(path);
        var id = getIdAt(path, offset);
        if (id == null) return null;
        var entry = context.rootNode.locateIndex(offset).getCompletion().getEntryByName(id.name);
        if (entry == null) return null;
        return new CompReferences(id.name, [for (usage in entry.getReferences().usages) new CompReference(conv.pos(usage.pos), conv.usageType(usage.type)) ]);
    }
    
    public function getIdAt(path:String, offset:Int):CompRange {
        var context = getContext(path);
        var id = context.rootNode.locateIndex(offset).getIdentifier();
        if (id == null) return null;
        return new CompRange(conv.pos(id.pos), id.name);
    }
    
    /**
     * Get information about a calling function, with parameters information and current parameter index
     **/
    public function getCallInfoAt(path:String, offset:Int):CompCall {
        var context:CompFileContext = getContext(path);
        var callInfo:CallInfo = context.rootNode.getCallInfoAt(offset);
        var call:CompCall = null;
        if (callInfo != null) {
            var f = callInfo.f;
            var argStartPos = callInfo.argPosStart;
            var startPos = callInfo.startPos;
            call = new CompCall(callInfo.argindex, startPos, argStartPos, conv.func(f));
        }
        return call;
    }

    public function getErrors(path:String):Array<CompError> {
        var context:CompFileContext = getContext(path);
        return [for (error in context.errors.errors) new CompError(conv.pos(error.pos), error.message)];
    }

    private function getContext(path:String):CompFileContext {
        var context:CompFileContext = contexts[path];
        if (context == null) throw 'Can\'t find context for file $path';
        return context;
    }
}

class Conv {
    private var types:HaxeTypes;

    public function new(types:HaxeTypes) {
        this.types = types;
    }
    
    public function func(f:FunctionHaxeType):CompFunction {
        return new CompFunction(f.optBaseType.fqName, f.name, [for (a in f.args) funcArg(a)], funcRet(f.getReturn()), '');
    }

    public function toEntry(name:String, result:ExpressionResult):CompEntry {
        return new CompEntry(name, toType(result.type), result.hasValue, result.value);
    }
    
    public function funcRet(f:ExpressionResult):CompReturn {
        return new CompReturn(toType(f.type), '');
    }

    public function funcArg(fa:FunctionArgument):CompArgument {
        return new CompArgument(fa.index, fa.name, toType(fa.getSpecType(types)), fa.opt, fa.doc);
    }
    
    public function usageType(type:UsageType):CompReferenceType {
        switch (type) {
            case UsageType.Declaration: return CompReferenceType.Declaration;
            case UsageType.Read: return CompReferenceType.Read;
            case UsageType.Write: return CompReferenceType.Update;
        }
    }

    public function pos(pos:TextRange):CompPosition {
        return new CompPosition(pos.min, pos.max);
    }

    public function toType(type:SpecificHaxeType):CompType {
        if (type == null) return new BaseCompType('Dynamic');
        if (Std.is(type.type, FunctionHaxeType)) {
            var ftype = cast(type.type, FunctionHaxeType);
            return new FunctionCompType([for (a in ftype.args) new BaseCompType(a.fqName)], new BaseCompType(ftype.getRetvalFqName()));
        }
        return new BaseCompType(type.type.fqName, (type.parameters != null) ? [for (i in type.parameters) toType(i)] : null);
    }
}

class CompFileContext {
    static private var grammar = new HaxeGrammar();
    public var reader:Reader;
    public var term:GrammarTerm;
    public var types:HaxeTypes;
    public var typeBuilder:HaxeTypeBuilder;
    public var typeChecker:HaxeTypeChecker;
    public var grammarResult:GrammarResult;
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
        switch (grammarResult) {
            case GrammarResult.RUnmatched(_, _) | GrammarResult.RMatched: rootNode = null;
            case GrammarResult.RMatchedValue(value): rootNode = cast(value);
        }
        if (rootNode != null) {
            builtTypes = [];
            typeBuilder.process(rootNode, builtTypes);
            //trace('builtTypes:' + builtTypes);
            for (type in builtTypes) typeChecker.checkType(type);
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

class CompRange {
    public var pos:CompPosition;
    public var name:String;
    public function new(pos:CompPosition, name:String) {
        this.pos = pos;
        this.name = name;
    } 
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
    public var index:Int;
    public var name: String;
    public var type: CompType;
    public var optional: Bool;
    public var doc: String;

    public function new(index:Int, name:String, type: CompType, optional: Bool, doc:String) {
        this.index = index;
        this.name = name;
        this.type = type;
        this.optional = optional;
        this.doc = doc;
    }

    public function toString() {
        var out = '';
        if (optional) out += '?';
        out += name;
        if (type != null) out += ':$type';
        return out;
    }
}

class CompReturn {
    public var type: CompType;
    public var doc: String;
    
    public function new(type:CompType, doc:String) {
        this.type = type;
        this.doc = doc;
    } 

    public function toString() return '$type';
}

class CompFunction {
    public var baseType:String;
    public var name:String;
    public var args:Array<CompArgument>;
    public var ret:CompReturn;
    public var doc:String;

    public function new(baseType:String, name:String, args:Array<CompArgument>, ret:CompReturn, doc:String) {
        this.baseType = baseType;
        this.name = name;
        this.args = args;
        this.ret = ret;
        this.doc = doc;
    }

    public function toString() {
        return name + '(' + args.join(', ') + '):' + ret;
    }
}

class CompCall {
    public var argIndex:Int;
    public var startPos:Int;
    public var argPos:Int;
    public var func:CompFunction;
    
    public function new(argIndex:Int, startPos:Int, startIndex:Int, func:CompFunction) {
        this.argIndex = argIndex;
        this.startPos = startPos;
        this.argPos = startIndex;
        this.func = func;
    }

    public function toString() return '$argIndex:$func';
}

class HtmlTools {
    static public function escape(str:String) {
        str = new EReg('<', 'g').replace(str, '&lt;');
        str = new EReg('>', 'g').replace(str, '&gt;');
        str = new EReg('"', 'g').replace(str, '&quote;');
        return str;
    }

    static public function typeToHtml(f:CompType) {
        if (Std.is(f, FunctionCompType)) {
            return [for (a in cast(f, FunctionCompType).args) typeToHtml(a)].join(' -&gt; ');
        }
        if (Std.is(f, BaseCompType)) {
            return '<span class="type">' + escape(cast(f, BaseCompType).str) + '</span>';
        }
        return '$f';
    }

    static public function argumentToHtml(a:CompArgument, ?selectedIndex:Int) {
        if (a.index != null && a.index == selectedIndex) return '<strong>' + argumentToHtml(a, null) + '</strong>';
        return '<span class="id">${escape(a.name)}</span>:${typeToHtml(a.type)}';
    }

    static public function retvalToHtml(r:CompReturn) {
        return typeToHtml(r.type);
    }

    static public function callToHtml(f:CompCall) {
        var func = f.func;
        var currentIndex = f.argIndex;
        return escape(func.name) + '(' + [for (a in func.args) argumentToHtml(a, currentIndex)].join(', ') + '):' + retvalToHtml(func.ret);
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