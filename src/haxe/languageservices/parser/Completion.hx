package haxe.languageservices.parser;

import haxe.languageservices.parser.TypeContext.TypeClass;
import haxe.languageservices.parser.TypeContext.TypeType;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.util.ArrayUtils;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.util.ArrayUtils;
import haxe.languageservices.parser.Completion.CompletionScope;
import haxe.languageservices.util.StringUtils;
import haxe.languageservices.parser.Expr.CType;
import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.parser.Expr.ErrorDef;
import haxe.languageservices.parser.Expr.ExprDef;
import haxe.languageservices.parser.Errors.ErrorContext;
class Completion {

}

class CompletionVariable {
    public var name:String;
    public var type:CompletionType;
    public var references:Array<Reference> = [];

    public function new(name:String, type:CompletionType) {
        this.name = name;
        this.type = type;
    }

    public function addReference(ref:Reference):Void {
        references.push(ref);
//trace('reference $name $ref');
    }
}

enum Reference {
    Declaration(e:Expr);
    Write(e:Expr);
    Read(e:Expr);
}

typedef CompletionArgument = {
    name: String,
    type: CompletionType,
    ?optional: Bool,
    ?doc: String
};

enum CompletionType {
    Unknown;
    Keyword;
    Dynamic;
    Void;
    Bool;
    Int;
    Float;
    String;
    TypeParam;
    Object(items:Array<CompletionEntry>);
    Type2(fqName:String);
    Array(type:CompletionType);
    Function(type:String, name:String, args:Array<CompletionArgument>, ret:CompletionType);
}

typedef CallReturn = {
    type: CompletionType,
    ?doc: String,
};

enum CCompletion {
    CallCompletion(baseType:String, name:String, args:Array<CompletionArgument>, ret:CallReturn, argIndex:Int, ?doc:String);
}

class CompletionList {
    public var items:Array<CompletionEntry>;

    public function new(items:Array<CompletionEntry>) {
        this.items = items;
    }

    public function toString() {
        return [for (completion in items) completion.name + ':' + CompletionTypeUtils.toString(completion.type)].toString();
    }
}

typedef CompletionEntry = { name:String, type:CompletionType };

class Scope<TKey : String, TValue> {
    public var parent:Scope<TKey, TValue>;
    private var map:Map<String, TValue>;

    public function new(?parent:Scope<TKey, TValue>) {
        this.parent = parent;
        this.map = new Map<String, TValue>();
    }

    public function exists(key:TKey):Bool {
        if (map.exists(key)) return true;
        if (parent != null) return parent.exists(key);
        return false;
    }

    public function get(key:TKey):TValue {
        if (map.exists(key)) return map.get(key);
        if (parent != null) return parent.get(key);
//throw new Error2('Can\'t find "$key"');
        return null;
    }

    public function set(key:TKey, value:TValue) return map.set(key, value);

    public function keys(?out:Array<String>):Array<String> {
        if (out == null) out = [];
        for (key in map.keys()) {
            if (out.indexOf(key) < 0) out.push(key);
        }
        if (parent != null) parent.keys(out);
        return out;
    }

    public function toString() {
        return 'Scope(${[for (key in map.keys()) key]}, $parent)';
    }
}

class CompletionScope {
    public var start:Int;
    public var end:Int;
    private var parent:CompletionScope;
    public var children:Array<CompletionScope> = [];
    public var context:CompletionContext;
    private var scope:Scope<String, CompletionVariable>;
    private var keywords = new Array<String>();

    public function new(context:CompletionContext, ?parent:CompletionScope) {
        this.context = context;
        this.parent = parent;
        this.scope = new Scope<String, CompletionVariable>((parent != null) ? parent.scope : null);
        if (parent != null)parent.children.push(this);
    }
    
    public function setBounds(start:Int, end:Int):CompletionScope {
        this.start = start;
        this.end = end;
        return this;
    }
    
    public var callCompletion:CCompletion;
    
    public function setCallCompletion(c:CCompletion):CompletionScope {
        this.callCompletion = c;
        return this;
    }
    
    private var _completionType:CompletionType = null;
    public function setCompletionType(ct:CompletionType):CompletionScope {
        this._completionType = ct;
        return this;
    }
    
    public function createChild():CompletionScope return new CompletionScope(context, this);

    public function set(name:String, v:CompletionVariable) {
        this.scope.set(name, v);
    }
    
    public function getLocal(name:String) {
        return this.scope.get(name);
    }

    public function getElementType(e:Expr):CompletionType {
        var result = getType(e);
        switch (result) {
            case CompletionType.Array(type): return type;
            default:
        }
        return CompletionType.Unknown;
    }

    public function getType(e:Expr):CompletionType {
        switch (e.e) {
            case ExprDef.EIdent(v):
                var local = scope.get(v);
                return (local != null) ? local.type : CompletionType.Dynamic;
            case ExprDef.EConst(CInt(_)): return CompletionType.Int;
            case ExprDef.EConst(CFloat(_)): return CompletionType.Float;
            case ExprDef.EConst(CString(_)): return CompletionType.String;
            case ExprDef.EField(expr, field):
                return CompletionTypeUtils.getFieldType(getType(expr), field);
            case ExprDef.EBlock(exprs):
//trace('Block:' + exprs);
                return getType(exprs[exprs.length - 1]);
            case ExprDef.EReturn(e): return getType(e);
            case ExprDef.EIf(cond, e1, e2):
                return CompletionTypeUtils.unificateTypes([getType(e1), getType(e2)]);
            case ExprDef.EParent(expr):
                return getType(expr);
            case ExprDef.EUnop(op, prefix, expr):
                var type = getType(expr);
                switch (op) {
                    case '-':
                        switch (type) {
                            case CompletionType.Int, CompletionType.Float, CompletionType.Dynamic: return type;
                            default:
                        }
                    default:
                }
                throw 'Unhandled unary op $op';

            case ExprDef.EBinop(op, left, right):
                var ltype = getType(left);
                var rtype = getType(right);
                switch (op) {
                    case '==':
                        if (ltype != rtype) context.errors.add(new Error(ErrorDef.EInvalidOp("Disctinct types"), e.pmin, e.pmax));
                        return CompletionType.Bool;
                    case '...':
                        return CompletionType.Array(CompletionType.Int);
                    case '+':
                        if (Std.is(ltype, CompletionType.Bool) || Std.is(rtype, CompletionType.Bool)) {
                            context.errors.add(new Error(ErrorDef.EInvalidOp("Cannot add bool"), e.pmin, e.pmax));
                        }
                        switch ([ltype, rtype]) {
                            case [CompletionType.Int, CompletionType.Int]: return CompletionType.Int;
                            case [CompletionType.Int, CompletionType.Float]: return CompletionType.Float;
                            case [CompletionType.Int, CompletionType.String]: return CompletionType.String;
                            case [CompletionType.Float, CompletionType.Int]: return CompletionType.Float;
                            case [CompletionType.Float, CompletionType.Float]: return CompletionType.Float;
                            case [CompletionType.Float, CompletionType.String]: return CompletionType.String;
                            case [CompletionType.String, CompletionType.Int]: return CompletionType.String;
                            case [CompletionType.String, CompletionType.Float]: return CompletionType.String;
                            case [CompletionType.String, CompletionType.String]: return CompletionType.String;
                            case [_, CompletionType.Dynamic]: return CompletionType.Dynamic;
                            case [CompletionType.Dynamic, _]: return CompletionType.Dynamic;
                            default:
                                context.errors.add(new Error(ErrorDef.EInvalidOp('Unsupported op2 $ltype $op $rtype'), e.pmin, e.pmax));
                                return CompletionType.Dynamic;
                        }
                        ltype;
                    default:
                        throw 'Unsupported operator $op';
                }
                throw 'Unsupported type with $op';
                return ltype;
            case ExprDef.EFunction(args, e, name, ret):
                var rtype = switch (e.e) {
                    case ExprDef.EObject(fl) if (fl.length == 0):
                        CompletionType.Void;
                    default:
                        getType(e);
                }
                //trace('FUNCTION!!!!' + e);
                //trace('type:' + rtype);
                var f = CompletionType.Function(
                    '<anonymous>', name,
                    [for (arg in args) { name: arg.name, type: CompletionTypeUtils.fromCType(arg.t), optional: arg.opt }],
                    rtype
                );
                return f;
            case ExprDef.ECall(e, params):
                switch (getType(e)) {
                    case CompletionType.Function(type, name, args, ret): return ret;
                    case CompletionType.Dynamic: return CompletionType.Dynamic;
                    default:
                }
                return CompletionType.Unknown;
            case ExprDef.EArrayDecl(exprs):
//trace(exprs);
                return CompletionType.Array(CompletionTypeUtils.unificateTypes([for (expr in exprs) getType(expr)]));
            case ExprDef.EObject(parts):
                return CompletionType.Object([for (part in parts) { name: part.name, type: getType(part.e) } ]);
            default:
                throw 'Unhandled expression ${e.e}';
        }
        trace(e);
        return CompletionType.Unknown;
    }
    
    public function containsIndex(index:Int) return index >= start && index <= end;
    
    public function addKeyword(name:String) {
        ArrayUtils.pushOnce(keywords, name);
    }

    public function addLocal(ident:String, t:CType, e:Expr, ?type:CompletionType, ?exprScope:CompletionScope):CompletionVariable {
        if (exprScope == null) exprScope = this;
        if (type == null) {
            if (e != null) {
                type = try {
                    exprScope.getType(e);
                } catch (e:Dynamic) {
                    context.errors.add(new Error(ErrorDef.EUnknown('Error:$e'), e.pmin, e.pmax));
                    CompletionType.Unknown;
                }
            } else {
                type = CompletionTypeUtils.fromCType(t);
            }
        }
        var v = new CompletionVariable(ident, type);
        if (e != null) v.addReference(Reference.Declaration(e));
        set(ident, v);
        return v;
    }
    
    public function locateIndex(index:Int):CompletionScope {
        for (child in children) if (child.containsIndex(index)) return child.locateIndex(index);
        return this;
    }

    public function getCompletionType():CompletionType {
        if (_completionType != null) return _completionType;
        var keys = ArrayUtils.sorted(scope.keys());
        var locals = [for (key in keys) { name: key, type: getLocal(key).type }];
        var keywords = [for (key in this.keywords) { name: key, type: CompletionType.Keyword }];
        return CompletionType.Object(locals.concat(keywords));
    }
}

class CompletionContext {
    public var root(default, null):CompletionScope;
    public var scope:CompletionScope;
    public var tokenizer:Tokenizer;
    public var errors:ErrorContext;

    public function new(tokenizer:Tokenizer, errors:ErrorContext) {
        this.tokenizer = tokenizer;
        this.errors = errors;
        this.scope = this.root = new CompletionScope(this);
        scope.set("true", new CompletionVariable("true", CompletionType.Bool));
        scope.set("false", new CompletionVariable("false", CompletionType.Bool));
        scope.set("null", new CompletionVariable("null", CompletionType.Dynamic));
    }
    
    public function pushScope(callback: CompletionScope -> Void):CompletionScope {
//trace('push scope');
        var old = this.scope;
        var output = this.scope = scope.createChild();
        {
            scope.start = tokenizer.tokenMax;
            callback(scope);
            scope.end = tokenizer.tokenMin;
        }
        this.scope = old;
        
//trace('pop scope');
        return output;
    }

}

class CompletionTypeUtils {
    static public function hasField(type:CompletionType, field:String):Bool {
        switch (type) {
            case CompletionType.Dynamic: return true;
            case CompletionType.Object(items):
                for (item in items) if (item.name == field) return true;
            default:

        }
        return false;
    }

    static public function canAssign(dst:CompletionType, src:CompletionType) {
        return Type.enumEq(dst, src);
    }

    static public function unificateTypes(types:Array<CompletionType>):CompletionType {
        if (types.length == 0) return CompletionType.Dynamic;
        return types[0];
    }

    static public function getFieldType(type:CompletionType, field:String):CompletionType {
        switch (type) {
            case CompletionType.Dynamic: return CompletionType.Dynamic;
            case CompletionType.Object(items):
                for (item in items) if (item.name == field) return item.type;
            default:

        }
        return CompletionType.Unknown;
    }

    static public function fromCType(type:CType):CompletionType {
        if (type == null) return CompletionType.Dynamic;
        switch (type) {
            case CType.CTPath(["Int"], null): return CompletionType.Int;
            case CType.CTPath(["Float"], null): return CompletionType.Float;
            case CType.CTPath(["Bool"], null): return CompletionType.Bool;
            case CType.CTPath(["String"], null): return CompletionType.String;
            case CType.CTPath(path, params): return CompletionType.Type2(path.join('.'));
            case CType.CTTypeParam: return CompletionType.TypeParam;
            default:
        }
        throw 'Not implemented $type';
        return null;
    }

    static public function toString(ct:CompletionType) {
        switch (ct) {
            case CompletionType.Array(ct): return 'Array<' + toString(ct) + '>';
            case CompletionType.Bool: return 'Bool';
            case CompletionType.Void: return 'Void';
            case CompletionType.Keyword: return 'Keyword';
            case CompletionType.TypeParam: return 'TypeParam';
            case CompletionType.Float: return 'Float';
            case CompletionType.Int: return 'Int';
            case CompletionType.String: return 'String';
            case CompletionType.Type2(fqName): return '$fqName';
            case CompletionType.Dynamic: return 'Dynamic';
            case CompletionType.Object(items):
                return '{' + [for (item in items) item.name + ':' + toString(item.type)].join(',') + '}';
            case CompletionType.Function(type, name, args, ret):
                return [for (arg in args) toString(arg.type)].concat([toString(ret)]).join(' -> ');
            default:
        }
        return '???$ct';
    }
}

