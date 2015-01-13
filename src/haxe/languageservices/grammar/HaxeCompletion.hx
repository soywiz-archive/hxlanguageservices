package haxe.languageservices.grammar;

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

    public function new(types:HaxeTypes, errors:HaxeErrors) {
        this.types = types;
        this.errors = errors;
    }

    /*
    public function pushScope(callback: HaxeCompletionScope -> Void) {
        var old = scope;
        scope = scope.createChild();
        callback(scope);
        scope = old;
    }
    */

    public function process(znode:ZNode, ?scope:CompletionScope):CompletionScope {
        if (scope == null) {
            scope = new CompletionScope(this, znode);
            var pos = new Position(0, 0, new Reader('', 'dummy.hx'));
            //scope.addLocal(new CompletionEntry(scope, pos, Node.NConst({ pos: pos, node: Const.CBool(true) }), 'true'));
        }

        if (znode == null || znode.node == null) return scope;
        // @TODO: Ugly hack!
        if (Std.is(znode.node, NNode)) return process(cast(znode.node), scope);

        switch (znode.node) {
            case Node.NFile(items) | Node.NBlock(items): for (item in items) process(item, scope.createChild(item));
            case Node.NList(items) | Node.NArray(items): for (item in items) process(item, scope);
            case Node.NVar(name, type, value):
                scope.addLocal(new CompletionEntry(scope, name.pos, value, NodeTools.getId(name)));
                process(value, scope);
            case Node.NId(value):
                switch (value) {
                    case 'true', 'false', 'null':
                    default:
                        var local = scope.getLocal(value);
                        if (local == null) {
                            errors.add(new ParserError(znode.pos, 'Can\'t find local "$value"'));
                        } else {
                            local.usages.push(znode);
                        }
                }
            case Node.NUnary(op, value):
                process(value, scope);
            case Node.NIf(code, trueExpr, falseExpr):
                process(code, scope);
                process(trueExpr, scope);
                process(falseExpr, scope);
            case Node.NFor(iteratorName, iteratorExpr, body):
                process(iteratorExpr, scope);
                var forScope = scope.createChild(body);
                forScope.addLocal(new CompletionEntry(scope, iteratorName.pos, iteratorExpr, NodeTools.getId(iteratorName)));
                process(body, forScope);
            case Node.NConst(_):
            case Node.NPackage(fqName):
            case Node.NImport(fqName):
            case Node.NClass(name, typeParams, extendsImplementsList, decls):
                process(decls, scope.createChild(decls));
            case Node.NMember(modifiers, decl):
                process(decl);
            case Node.NFunction(name, expr):
                process(expr);
            case Node.NReturn(expr):
                process(expr);
            //case Node.NPackage()
            default:
                errors.add(new ParserError(znode.pos, 'Unhandled completion ${znode}'));
                //throw ;
        }
        return scope;
    }
}

class CompletionEntry {
    public var scope:CompletionScope;
    public var pos:Position;
    public var name:String;
    public var expr:ZNode;
    public var usages = new Array<ZNode>();

    public function new(scope:CompletionScope, pos:Position, expr:ZNode, name:String) {
        this.scope = scope;
        this.pos = pos;
        this.expr = expr;
        this.name = name;
    }

    public function getType():HaxeType {
        return scope.getNodeType(expr);
    }

    public function toString() return '$name@$pos';
}

class CompletionScope {
    static private var lastUid = 0;
    public var uid:Int = lastUid++;
    public var node:ZNode;
    private var completion:HaxeCompletion;
    private var types:HaxeTypes;
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
        var znode = getNodeAt(index);
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

    public function getNodeType(znode:ZNode):HaxeType {
        if (Std.is(znode.node, NNode)) return getNodeType(cast(znode.node));
        switch (znode.node) {
            case Node.NConst(Const.CInt(_)): return types.typeInt;
            case Node.NConst(Const.CFloat(_)): return types.typeFloat;
            case Node.NIf(code, trueExpr, falseExpr):
                return types.unify([getNodeType(trueExpr), getNodeType(falseExpr)]);
            case Node.NId(str):
                switch (str) {
                    case 'true', 'false': return types.typeBool;
                    case 'null': return types.typeDynamic;
                    default:
                        var local = getLocal(str);
                        if (local != null) return local.getType();
                        return types.typeDynamic;
                }
            default:
                throw 'Not implemented (I): ${znode}';
        }

        return completion.types.typeDynamic;
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

