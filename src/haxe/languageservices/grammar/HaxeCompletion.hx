package haxe.languageservices.grammar;

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
    public var types:HaxeTypes;

    public function new(types:HaxeTypes) {
        this.types = types;
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
        if (scope == null) scope = new CompletionScope(this, znode.pos);
        switch (znode.node) {
            case Node.NFile(decls):
                for (decl in decls) process(decl, scope.createChild(decl.pos));
            case Node.NBlock(items):
                for (item in items) process(item, scope.createChild(item.pos));
            case Node.NList(items):
                for (item in items) process(item, scope);
            case Node.NVar(name, type, value):
                scope.addLocal(new CompletionEntry(scope, name.pos, value, NodeTools.getId(name)));
            default:
                throw 'Unhandled ${znode}';
        }
        return scope;
    }
}

class CompletionEntry {
    public var scope:CompletionScope;
    public var pos:Position;
    public var name:String;
    public var expr:ZNode;
    public var references:Array<Position>;

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
    public var pos:Position;
    private var completion:HaxeCompletion;
    private var types:HaxeTypes;
    private var parent:CompletionScope;
    private var children = new Array<CompletionScope>();
    private var locals:Scope<String, CompletionEntry>;

    public function new(completion:HaxeCompletion, ?pos:Position, ?parent:CompletionScope) {
        if (pos == null) pos = new Position(0, 0);
        this.pos = pos;
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

    public function locateIndex(index:Int):CompletionScope {
        for (child in children) {
            if (child.pos.contains(index)) return child.locateIndex(index);
        }
        return this;
    }

    public function getNodeType(znode:ZNode):HaxeType {
        if (Std.is(znode.node, NNode)) return getNodeType(cast(znode.node));
        switch (znode.node) {
            case Node.NConst(Const.CInt(_)): return types.typeInt;
            case Node.NConst(Const.CFloat(_)): return types.typeFloat;
            default:
                throw 'Not implemented (I): ${znode}';
        }

        return completion.types.typeDynamic;
    }

    public function getLocals():Array<CompletionEntry> {
        return locals.values();
    }

    public function getLocal(name:String):CompletionEntry {
        return locals.get(name);
    }

    public function addLocal(entry:CompletionEntry):Void {
        locals.set(entry.name, entry);
    }

    public function createChild(?pos:Position):CompletionScope return new CompletionScope(this.completion, pos, this);
}

