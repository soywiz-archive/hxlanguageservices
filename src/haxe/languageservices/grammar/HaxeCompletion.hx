package haxe.languageservices.grammar;

import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.type.HaxeType.SpecificHaxeType;
import haxe.languageservices.node.ProcessNodeContext;
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

        switch (znode.node) {
            case Node.NFile(items) | Node.NBlock(items): for (item in items) process(item, scope.createChild(item));
            case Node.NList(items) | Node.NArray(items): for (item in items) process(item, scope);
            case Node.NVar(name, propertyInfo, type, value):
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
            case Node.NIf(condExpr, trueExpr, falseExpr):
                var condType = scope.getNodeType(condExpr, new ProcessNodeContext());
                if (condType.type.fqName != 'Bool') {
                    errors.add(new ParserError(condExpr.pos, 'If condition must be Bool but was ' + condType));
                }
                //trace(condType);
                process(condExpr, scope);
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
            case Node.NCall(_, _):
            case Node.NArrayAccess(left, index):
                process(left, scope);
                process(index, scope);
            case Node.NFieldAccess(left, id):
                process(left, scope);
                var lvalue = scope.getNodeResult(left);
            
                //if (id == null) {
                    var l:ZNode = left;
                    //trace('id:null');
                    var p = l.pos.reader.createPos(l.pos.max, l.pos.max + 2);
                    var cscope = scope.createChild(new ZNode(p, null));
                    cscope.unlinkFromParent();
                    for (m in lvalue.type.type.members) {
                        cscope.addLocal(new CompletionEntry(cscope, p, null, null, m.name));
                    }
                //}
                //process(id, scope);
                //left.
            case Node.NBinOp(left, op, right):
                process(left, scope);
                process(right, scope);
                var ltype = scope.getNodeType(left);
                var rtype = scope.getNodeType(right);
                /*
                switch (op) {
                    case '':
                }
                */
            case Node.NPackage(fqName):
            case Node.NImport(fqName):
            case Node.NUsing(fqName):
            case Node.NClass(name, typeParams, extendsImplementsList, decls):
                var classScope = scope.createChild(decls);
                var clazz = scope.types.getClass(NodeTools.getId(name));
                classScope.currentClass = clazz;
                process(decls, classScope);
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
                var funcScope =  scope.createChild(expr);
                var local = new CompletionEntryFunctionElement(scope, name.pos, ret, expr, NodeTools.getId(name));
                scope.addLocal(local);
                local.usages.push(new CompletionUsage(name, CompletionUsageType.Declaration));
                var bodyScope = funcScope.createChild(expr);

                //scope:CompletionScope, pos:Position, type:ZNode, expr:ZNode, name:String
                if (scope.currentClass != null) {
                    bodyScope.addLocal(new CompletionEntryThis(scope, scope.currentClass));
                } 

                processFunctionArgs(args, funcScope, funcScope);

                process(expr, bodyScope);
            case Node.NReturn(expr):
                process(expr, scope);
            //case Node.NPackage()
            default:
                errors.add(new ParserError(znode.pos, 'Unhandled completion (II) ${znode}'));
                //throw ;
        }
        return scope;
    }

    private function processFunctionArgs(znode:ZNode, scope:CompletionScope, scope2:CompletionScope):Void {
        if (znode == null || znode.node == null) return;
        switch (znode.node) {
            case Node.NList(items): for (item in items) processFunctionArgs(item, scope, scope2);
            case Node.NFunctionArg(opt, id, type, value):
                //trace(type);
                var e = new CompletionEntry(scope2, id.pos, type, value, NodeTools.getId(id));
                //trace(e.getType(new ProcessNodeContext()));
                scope.addLocal(e);
                e.usages.push(new CompletionUsage(id, CompletionUsageType.Declaration));
            default:
                throw 'Unhandled completion (I) $znode';
                errors.add(new ParserError(znode.pos, 'Unhandled completion (I) $znode'));
        }
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
    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(scope.types.getArrayElement(super.getResult().type));
    }
}

class CompletionEntryFunctionElement extends CompletionEntry {
    public function new(scope:CompletionScope, pos:Position, type:ZNode, expr:ZNode, name:String) {
        super(scope, pos, type, expr, name);
    }

    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        //return ExpressionResult.withoutValue(new SpecificHaxeType(scope.types, new FunctionHaxeType(scope.types.rootPackage, pos, name)));
        return ExpressionResult.withoutValue(scope.types.specTypeDynamic);
    }
}

class CompletionEntryThis extends CompletionEntry {
    public function new(scope:CompletionScope, type:HaxeType) {
        super(scope, new Position(0, 0, new Reader('')), null, null, 'this', type);
    
    }

    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(new SpecificHaxeType(scope.types, type2));
    }
}

class CompletionEntry {
    public var scope:CompletionScope;
    public var pos:Position;
    public var name:String;
    public var type:ZNode;
    public var type2:HaxeType;
    public var expr:ZNode;
    public var usages = new Array<CompletionUsage>();

    public function new(scope:CompletionScope, pos:Position, type:ZNode, expr:ZNode, name:String, ?type2:HaxeType) {
        this.scope = scope;
        this.pos = pos;
        this.type = type;
        this.type2 = type2;
        this.expr = expr;
        this.name = name;
    }

    //public function getNodeResult(?context:ProcessNodeContext):Noderesult {
    //}

    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        var ctype:ExpressionResult = null;
        if (type2 != null) return ExpressionResult.withoutValue(new SpecificHaxeType(scope.types, type2));
        if (type != null) ctype = ExpressionResult.withoutValue(new SpecificHaxeType(scope.types, scope.types.getType(type.pos.text)));
        if (expr != null) ctype = scope.getNodeResult(expr, context);
        if (ctype == null) ctype = ExpressionResult.withoutValue(scope.types.specTypeDynamic);
        return ctype;
    }

    public function toString() return '$name@$pos';
}

class ExpressionResult {
    public var type:SpecificHaxeType;
    public var hasValue:Bool;
    public var value:Dynamic;

    private function new(type:SpecificHaxeType, hasValue:Bool, value:Dynamic) {
        this.type = type;
        this.hasValue = hasValue;
        this.value = value;
    }
    
    public function toString() {
        if (hasValue) return '$type = $value';
        return '$type';
    }

    static public function withoutValue(type:SpecificHaxeType):ExpressionResult return new ExpressionResult(type, false, null);
    static public function withValue(type:SpecificHaxeType, value:Dynamic):ExpressionResult return new ExpressionResult(type, true, value);
}

typedef CScope = Scope<CompletionEntry>;

class CompletionScope {
    static private var lastUid = 0;
    public var uid:Int = lastUid++;
    public var node:ZNode;
    private var completion:HaxeCompletion;
    public var types:HaxeTypes;
    public var currentClass:HaxeType;
    private var parent:CompletionScope;
    private var children = new Array<CompletionScope>();
    private var locals:CScope;
    
    public function unlinkFromParent() {
        this.parent = null;
        this.locals.parent = null;
    }

    public function new(completion:HaxeCompletion, node:ZNode, ?parent:CompletionScope) {
        this.node = node;
        this.completion = completion;
        this.types = completion.types;
        if (parent != null) {
            this.parent = parent;
            this.parent.children.push(this);
            this.currentClass = parent.currentClass;
            this.locals = parent.locals.createChild();
        } else {
            this.parent = null;
            this.locals = new CScope();
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

    public function getNodeType(znode:ZNode, ?context:ProcessNodeContext):SpecificHaxeType {
        return getNodeResult(znode, context).type;
    }

    public function getNodeResult(znode:ZNode, ?context:ProcessNodeContext):ExpressionResult {
        if (context == null) context = new ProcessNodeContext();
        return _getNodeResult(znode, context);
    }

    private function _getNodeResult(znode:ZNode, context:ProcessNodeContext):ExpressionResult {
        //trace(znode);
        if (context.isExplored(znode)) {
            context.recursionDetected();
            return ExpressionResult.withoutValue(types.specTypeDynamic);
        }
        context.markExplored(znode);
        switch (znode.node) {
            case Node.NBlock(values):
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NBinOp(left, op, right):
                var lv = _getNodeResult(left, context);
                var rv = _getNodeResult(right, context);
                
                function operator(doOp: Dynamic -> Dynamic -> Dynamic) {
                    if (lv.hasValue && rv.hasValue) {
                        return ExpressionResult.withValue(lv.type, doOp(lv.value, rv.value));
                    }
                    return ExpressionResult.withoutValue(types.specTypeInt);
                }
                
                switch (op) {
                    case '==', '!=':
                        return ExpressionResult.withoutValue(types.specTypeBool);
                    case '+': return operator(function(a, b) return a + b);
                    case '-': return operator(function(a, b) return a - b);
                    case '%': return operator(function(a, b) return a % b);
                    case '/': return operator(function(a, b) return a / b);
                    case '*': return operator(function(a, b) return a * b);
                    default:
                        throw 'Unknown operator $op';
                }
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NArrayAccess(left, index):
                var lresult = _getNodeResult(left, context);
                var iresult = _getNodeResult(left, context);
                if (lresult.type.type.fqName == 'Array') {
                    return ExpressionResult.withoutValue(types.getArrayElement(lresult.type));
                }
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NList(values):
                return ExpressionResult.withoutValue(types.unify([for (value in values) _getNodeResult(value, context).type]));
            case Node.NArray(values):
                var elementType = types.unify([for (value in values) _getNodeResult(value, context).type]);
                return ExpressionResult.withoutValue(types.createArray(elementType));
            case Node.NConst(Const.CInt(value)): return ExpressionResult.withValue(types.specTypeInt, value);
            case Node.NConst(Const.CFloat(value)): return ExpressionResult.withValue(types.specTypeFloat, value);
            case Node.NIf(code, trueExpr, falseExpr):
                return ExpressionResult.withoutValue(types.unify([_getNodeResult(trueExpr, context).type, _getNodeResult(falseExpr, context).type]));
            case Node.NCall(left, args):
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NFieldAccess(left, id):
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NId(str):
                switch (str) {
                    case 'true': return ExpressionResult.withValue(types.specTypeBool, true);
                    case 'false': return ExpressionResult.withValue(types.specTypeBool, false);
                    case 'null': return ExpressionResult.withValue(types.specTypeDynamic, null);
                    default:
                        var local = getLocal(str);
                        if (local != null) return local.getResult(context);
                        return ExpressionResult.withoutValue(types.specTypeDynamic);
                }
            default:
                throw new js.Error('Not implemented getNodeResult() $znode');
                //completion.errors.add(new ParserError(znode.pos, 'Not implemented getNodeType() $znode'));
        }

        return ExpressionResult.withoutValue(types.specTypeDynamic);
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




