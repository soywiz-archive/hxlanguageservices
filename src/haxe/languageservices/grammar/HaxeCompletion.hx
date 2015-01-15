package haxe.languageservices.grammar;

import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.node.Reader;
import haxe.languageservices.grammar.Grammar.NNode;
import haxe.languageservices.node.Const;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.Position;
import haxe.languageservices.util.Scope;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.node.ZNode;

class HaxeCompletion {
    public var errors:HaxeErrors;
    public var types:HaxeTypes;

    public function new(types:HaxeTypes, ?errors:HaxeErrors) {
        this.types = types;
        this.errors = (errors != null) ? errors : new HaxeErrors();
    }

    /*
    public function pushScope(callback: HaxeCompletionScope -> Void) {
        var old = scope;
        scope = scope.createChild();
        callback(scope);
        scope = old;
    }
    */

    public function processCompletion(znode:ZNode):CompletionScope {
        return process(znode, new CompletionScope(this, znode));
    }

    private function process(znode:ZNode, scope:CompletionScope):CompletionScope {
        if (znode == null || znode.node == null) return scope;
        // @TODO: Ugly hack!
        if (Std.is(znode.node, NNode)) return process(cast(znode.node), scope);

        switch (znode.node) {
            case Node.NFile(items) | Node.NBlock(items): for (item in items) process(item, scope.createChild(item));
            case Node.NList(items) | Node.NArray(items): for (item in items) process(item, scope);
            case Node.NVar(name, type, value):
                var local = new CompletionEntry(scope, name.pos, type, value, NodeTools.getId(name));
                scope.addLocal(local);
                local.usages.push(new CompletionUsage(name, CompletionUsageType.Declaration));
                //trace(scope);
                process(value, scope);
            case Node.NId(value):
                switch (value) {
                    case 'true', 'false', 'null':
                    default:
                        var local = scope.getLocal(value);
                        if (local == null) {
                            errors.add(new ParserError(znode.pos, 'Can\'t find local "$value"'));
                        } else {
                            local.usages.push(new CompletionUsage(znode, CompletionUsageType.Read));
                        }
                }
            case Node.NUnary(op, value):
                process(value, scope);
            case Node.NIf(code, trueExpr, falseExpr):
                process(code, scope);
                process(trueExpr, scope);
                process(falseExpr, scope);
            case Node.NFor(iteratorName, iteratorExpr, body):
                var fullForScope = scope.createChild(znode);
                var forScope = fullForScope.createChild(body);
                process(iteratorExpr, fullForScope);
                var local = new CompletionEntryArrayElement(fullForScope, iteratorName.pos, null, iteratorExpr, NodeTools.getId(iteratorName));
                local.usages.push(new CompletionUsage(iteratorName, CompletionUsageType.Declaration));
                fullForScope.addLocal(local);
                process(body, fullForScope);
            case Node.NWhile(cond, body) | Node.NDoWhile(body, cond):
                process(cond, scope);
                process(body, scope);
            case Node.NConst(_):
            case Node.NPackage(fqName):
            case Node.NImport(fqName):
            case Node.NUsing(fqName):
            case Node.NClass(name, typeParams, extendsImplementsList, decls):
                process(decls, scope.createChild(decls));
            case Node.NInterface(name, typeParams, extendsImplementsList, decls):
                process(decls, scope.createChild(decls));
            case Node.NSwitch(subject, cases):
                process(subject, scope);
                process(cases, scope);
            case Node.NEnum(name):
            case Node.NAbstract(name):
            case Node.NMember(modifiers, decl):
                process(decl, scope);
            case Node.NFunction(name, args, ret, expr):
                process(expr, scope.createChild(expr));
            case Node.NReturn(expr):
                process(expr, scope);
            //case Node.NPackage()
            default:
                errors.add(new ParserError(znode.pos, 'Unhandled completion ${znode}'));
                //throw ;
        }
        return scope;
    }
}

enum CompletionUsageType {
    Declaration;
    Write;
    Read;
}

class CompletionUsage {
    public var node:ZNode;
    public var type:CompletionUsageType;

    public function new(node:ZNode, type:CompletionUsageType) {
        this.node = node;
        this.type = type;
    }

    public function toString() return '$node:$type';
}

class CompletionEntryArrayElement extends CompletionEntry {
    override public function getType():SpecificHaxeType {
        return scope.types.getArrayElement(super.getType());
    }
}

class CompletionEntry {
    public var scope:CompletionScope;
    public var pos:Position;
    public var name:String;
    public var type:ZNode;
    public var expr:ZNode;
    public var usages = new Array<CompletionUsage>();

    public function new(scope:CompletionScope, pos:Position, type:ZNode, expr:ZNode, name:String) {
        this.scope = scope;
        this.pos = pos;
        this.type = type;
        this.expr = expr;
        this.name = name;
    }

    public function getType():SpecificHaxeType {
        var ctype:SpecificHaxeType = null;
        if (type != null) ctype = new SpecificHaxeType(scope.types.getType(type.pos.text));
        if (expr != null) ctype = scope.getNodeType(expr);
        if (ctype == null) ctype = scope.types.specTypeDynamic;
        return ctype;
    }

    public function toString() return '$name@$pos';
}

class ExpressionResult {
    public var type:SpecificHaxeType;
    public var hasValue:Bool;
    public var value:Dynamic;

    public function new(type:SpecificHaxeType, hasValue:Bool, value:Dynamic) {
        this.type = type;
        this.hasValue = hasValue;
        this.value = value;
    }
}

class CompletionScope {
    static private var lastUid = 0;
    public var uid:Int = lastUid++;
    public var node:ZNode;
    private var completion:HaxeCompletion;
    public var types:HaxeTypes;
    private var parent:CompletionScope;
    private var children = new Array<CompletionScope>();
    private var locals:Scope<String, CompletionEntry>;

    public function new(completion:HaxeCompletion, node:ZNode, ?parent:CompletionScope) {
        this.node = node;
        this.completion = completion;
        this.types = completion.types;
        if (parent != null) {
            this.parent = parent;
            this.parent.children.push(this);
            this.locals = parent.locals.createChild();
        } else {
            this.parent = null;
            this.locals = new Scope();
        }
    }

    public function getIdentifierAt(index:Int):{ pos: Position, name: String } {
        var znode = node.locateIndex(index);
        if (znode != null) {
            switch (znode.node) {
                case Node.NId(v): return { pos : znode.pos, name : v };
                default:
            }
        }
        return null;
    }
    
    public function getNodeAt(index:Int):ZNode {
        return locateIndex(index).node.locateIndex(index);
    }

    public function locateIndex(index:Int):CompletionScope {
        for (child in children) {
            if (child.node.pos.contains(index)) return child.locateIndex(index);
        }
        return this;
    }

    public function getNodeType(znode:ZNode):SpecificHaxeType {
        return getNodeResult(znode).type;
    }

    public function getNodeResult(znode:ZNode):ExpressionResult {
        if (Std.is(znode.node, NNode)) return getNodeResult(cast(znode.node));
        switch (znode.node) {
            case Node.NList(values):
                return new ExpressionResult(types.unify([for (value in values) getNodeResult(value).type]), false, null);
            case Node.NArray(values):
                var elementType = types.unify([for (value in values) getNodeResult(value).type]);
                return new ExpressionResult(types.createArray(elementType), false, null);
            case Node.NConst(Const.CInt(value)): return new ExpressionResult(types.specTypeInt, true, value);
            case Node.NConst(Const.CFloat(value)): return new ExpressionResult(types.specTypeFloat, true, value);
            case Node.NIf(code, trueExpr, falseExpr):
                return new ExpressionResult(types.unify([getNodeResult(trueExpr).type, getNodeResult(falseExpr).type]), false, null);
            case Node.NId(str):
                switch (str) {
                    case 'true': return new ExpressionResult(types.specTypeBool, true, true);
                    case 'false': return new ExpressionResult(types.specTypeBool, true, false);
                    case 'null': return new ExpressionResult(types.specTypeDynamic, true, null);
                    default:
                        var local = getLocal(str);
                        if (local != null) return new ExpressionResult(local.getType(), false, null);
                        return new ExpressionResult(types.specTypeDynamic, false, null);
                }
            default:
                throw new js.Error('Not implemented getNodeType() $znode');
                //completion.errors.add(new ParserError(znode.pos, 'Not implemented getNodeType() $znode'));
        }

        return new ExpressionResult(types.specTypeDynamic, false, null);
    }

    public function getLocals():Array<CompletionEntry> {
        return locals.values();
    }

    public function getLocalAt(index:Int):CompletionEntry {
        var id = getIdentifierAt(index);
        if (id == null) return null;
        return locals.get(id.name);
    }

    public function getLocal(name:String):CompletionEntry {
        return locals.get(name);
    }

    public function addLocal(entry:CompletionEntry):Void {
        locals.set(entry.name, entry);
    }

    public function createChild(node:ZNode):CompletionScope return new CompletionScope(this.completion, node, this);
}



