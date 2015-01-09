package haxe.languageservices.parser;

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

enum CompletionType {
    Unknown;
    Dynamic;
    Bool;
    Int;
    Float;
    String;
    Object(items:Array<CompletionEntry>);
    Array(type:CompletionType);
    Function(args:Array<CompletionType>, ret:CompletionType);
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

class CompletionSegment {
    public var start:Int;
    public var end:Int;
    public var gettype:Void -> CompletionType;

    public function new(start:Int, end:Int, gettype:Void -> CompletionType) {
        this.start = start;
        this.end = end;
        this.gettype = gettype;
    }

    public function toString() return 'CompletionSegment($start-$end, ${gettype()})';
}

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

class Scope2<TKey : String, TValue> {
    public var scope = new Scope<TKey, TValue>();

    public function new() {
    }

//public function exists(key:TKey) return scope.exists(key);
//public function get(key:TKey) return scope.get(key);
//public function set(key:TKey, value:TValue) return scope.set(key, value);
    public function push(callback: Void -> Void) {
        var oldscope = scope = new Scope<TKey, TValue>(scope);
        callback();
        scope = scope.parent;
        return oldscope;
    }
}

typedef CompletionScope = Scope<String, CompletionVariable>;


class CompletionContext {
    public var scope = new CompletionScope();
    private var tokenizer:Tokenizer;
    private var errors:ErrorContext;
    public var segments:Array<CompletionSegment> = [];

    public function new(tokenizer:Tokenizer, errors:ErrorContext) {
        this.tokenizer = tokenizer;
        this.errors = errors;
        scope.set("true", new CompletionVariable("true", CompletionType.Bool));
        scope.set("false", new CompletionVariable("false", CompletionType.Bool));
        scope.set("null", new CompletionVariable("null", CompletionType.Dynamic));
    }

    public function hasField(type:CompletionType, field:String):Bool {
        switch (type) {
            case CompletionType.Dynamic: return true;
            case CompletionType.Object(items):
                for (item in items) if (item.name == field) return true;
            default:

        }
        return false;
    }

    public function getFieldType(type:CompletionType, field:String):CompletionType {
        switch (type) {
            case CompletionType.Dynamic: return CompletionType.Dynamic;
            case CompletionType.Object(items):
                for (item in items) if (item.name == field) return item.type;
            default:

        }
        return CompletionType.Unknown;
    }

    public function ctypeToCompletionType(type:CType):CompletionType {
        if (type == null) return CompletionType.Dynamic;
        switch (type) {
            case CType.CTPath(["Int"], null): return CompletionType.Int;
            case CType.CTPath(["Float"], null): return CompletionType.Float;
            case CType.CTPath(["Bool"], null): return CompletionType.Bool;
            case CType.CTPath(["String"], null): return CompletionType.String;
            default:
        }
        throw 'Not implemented $type';
        return null;
    }

/*
    public function getLocal(name:String):CompletionVariable {
        if (!scope.exists(name)) {
            trace(scope);
            throw 'Can\'t find local "$name"';
        }
        return scope.get(name);
    }
    */


    public function pushContext(callback: Void -> Void) {
//trace('push scope');
        var startPos = tokenizer.tokenMax;
        scope = new CompletionScope(scope);
        var output = scope;
        callback();
        scope = scope.parent;

        var endPos = tokenizer.tokenMin;

        segments.push(new CompletionSegment(startPos, endPos, function() {
            var keys = output.keys();
            keys.sort(StringUtils.compare);
            return CompletionType.Object([for (key in keys) { name: key, type: output.get(key).type }]);
        }));

//trace('pop scope');
        return output;
    }

    public function unificateTypes(types:Array<CompletionType>):CompletionType {
        if (types.length == 0) return CompletionType.Dynamic;
        return types[0];
    }

    public function getElementType(e:Expr, scope:CompletionScope):CompletionType {
        var result = getType(e, scope);
        switch (result) {
            case CompletionType.Array(type): return type;
            default:
        }
        return CompletionType.Unknown;
    }

    public function getType(e:Expr, scope:CompletionScope):CompletionType {
        switch (e.e) {
            case ExprDef.EIdent(v):
                var local = scope.get(v);
                return (local != null) ? local.type : CompletionType.Dynamic;
            case ExprDef.EConst(CInt(_)): return CompletionType.Int;
            case ExprDef.EConst(CFloat(_)): return CompletionType.Float;
            case ExprDef.EConst(CString(_)): return CompletionType.String;
            case ExprDef.EField(expr, field):
                return getFieldType(getType(expr, scope), field);
            case ExprDef.EBlock(exprs):
//trace('Block:' + exprs);
                return getType(exprs[exprs.length - 1], scope);
            case ExprDef.EReturn(e): return getType(e, scope);
            case ExprDef.EIf(cond, e1, e2):
                return unificateTypes([getType(e1, scope), getType(e2, scope)]);
            case ExprDef.EParent(expr):
                return getType(expr, scope);
            case ExprDef.EUnop(op, prefix, expr):
                var type = getType(expr, scope);
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
                var ltype = getType(left, scope);
                var rtype = getType(right, scope);
                switch (op) {
                    case '==':
                        if (ltype != rtype) errors.errors.push(new Error(ErrorDef.EInvalidOp("Disctinct types"), e.pmin, e.pmax));
                        return CompletionType.Bool;
                    case '...':
                        return CompletionType.Array(CompletionType.Int);
                    case '+':
                        if (Std.is(ltype, CompletionType.Bool) || Std.is(rtype, CompletionType.Bool)) {
                            errors.errors.push(new Error(ErrorDef.EInvalidOp("Cannot add bool"), e.pmin, e.pmax));
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
                                errors.errors.push(new Error(ErrorDef.EInvalidOp('Unsupported op2 $ltype $op $rtype'), e.pmin, e.pmax));
                                return CompletionType.Dynamic;
                        }
                        ltype;
                    default:
                        throw 'Unsupported operator $op';
                }
                throw 'Unsupported type with $op';
                return ltype;
            case ExprDef.EFunction(args, e, name, ret):
                return CompletionType.Function(
                    [for (arg in args) CompletionType.Unknown],
                    getType(e, scope)
                );
            case ExprDef.ECall(e, params):
                switch (getType(e, scope)) {
                    case CompletionType.Function(args, ret): return ret;
                    case CompletionType.Dynamic: return CompletionType.Dynamic;
                    default:
                }
                return CompletionType.Unknown;
            case ExprDef.EArrayDecl(exprs):
//trace(exprs);
                return CompletionType.Array(unificateTypes([for (expr in exprs) getType(expr, scope)]));
            case ExprDef.EObject(parts):
                return CompletionType.Object([for (part in parts) { name: part.name, type: getType(part.e, scope) } ]);
            default:
                throw 'Unhandled expression ${e.e}';
        }
        trace(e);
        return CompletionType.Unknown;
    }

    public function addLocal(ident:String, t:CType, e:Expr, ?type:CompletionType, ?exprScope:CompletionScope):CompletionVariable {
        if (exprScope == null) exprScope = this.scope;
        if (type == null) {
            if (e != null) {
                type = try {
                    getType(e, exprScope);
                } catch (e:Dynamic) {
                    errors.errors.push(new Error(ErrorDef.EUnknown('Error:$e'), e.pmin, e.pmax));
                    CompletionType.Unknown;
                }
            }
        }
        var v = new CompletionVariable(ident, type);
        if (e != null) v.addReference(Reference.Declaration(e));
        scope.set(ident, v);
        return v;
    }
}

class CompletionTypeUtils {
    static public function toString(ct:CompletionType) {
        switch (ct) {
            case CompletionType.Array(ct): return 'Array<' + toString(ct) + '>';
            case CompletionType.Bool: return 'Bool';
            case CompletionType.Float: return 'Float';
            case CompletionType.Int: return 'Int';
            case CompletionType.String: return 'String';
            case CompletionType.Dynamic: return 'Dynamic';
            case CompletionType.Object(items):
                return '{' + [for (item in items) item.name + ':' + toString(item.type)].join(',') + '}';
            case CompletionType.Function(args, ret):
                return [for (arg in args) toString(arg)].concat([toString(ret)]).join(' -> ');
            default:
        }
        return '$ct';
    }
}

