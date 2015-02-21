package haxe.languageservices.completion;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.type.FunctionHaxeType;
import haxe.languageservices.node.Const;
import haxe.languageservices.type.tool.NodeTypeTools;
import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.node.ConstTools;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.grammar.HaxeCompletion;
import haxe.languageservices.node.ZNode;

class CompletionScope implements CompletionProvider {
    static private var lastUid = 0;
    public var uid:Int = lastUid++;
    public var node:ZNode;
    private var completion:HaxeCompletion;
    public var types:HaxeTypes;
    public var currentClass:HaxeType;
    private var parent:CompletionScope;
    private var children = new Array<CompletionScope>();
    private var locals:CScope;
    private var providers = new Array<CompletionProvider>();
    public var callInfo:CallInfo;

    public function unlinkFromParent() {
        this.parent = null;
        this.locals.parent = null;
    }

    public function addProvider(provider:CompletionProvider) {
        this.providers.push(provider);
    }

    public function new(completion:HaxeCompletion, node:ZNode, ?parent:CompletionScope) {
        this.node = node;
        this.completion = completion;
        this.types = completion.types;
        if (parent != null) {
            this.parent = parent;
            this.parent.children.push(this);
            this.currentClass = parent.currentClass;
            this.callInfo = parent.callInfo;
            this.locals = parent.locals.createChild();
        } else {
            this.parent = null;
            this.locals = new CScope();
        }
    }

    public function getIdentifierAt(index:Int):{ pos: TextRange, name: String } {
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
            if (child == null || child.node == null) continue;
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
                    case '...':
                        return ExpressionResult.withoutValue(types.createArray(types.specTypeInt));
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
            case Node.NConst(Const.CString(value)): return ExpressionResult.withValue(types.specTypeString, value);
            case Node.NIf(code, trueExpr, falseExpr):
                return ExpressionResult.withoutValue(types.unify([_getNodeResult(trueExpr, context).type, _getNodeResult(falseExpr, context).type]));
            case Node.NFor(iteratorName, iteratorExpr, body):
                return _getNodeResult(body, context);
            case Node.NWhile(cond, body):
                return _getNodeResult(body, context);
            case Node.NArrayComprehension(iterator):
                var itResult = _getNodeResult(iterator, context);
                return ExpressionResult.withoutValue(types.createArray(itResult.type));
            case Node.NNew(id, call):
                var type = NodeTypeTools.getTypeDeclType(types, id);
                return ExpressionResult.withoutValue(type);
            case Node.NCast(expr, type):
                var evalue = _getNodeResult(expr, context);
                var type2 = NodeTypeTools.getTypeDeclType(types, type);
                return ExpressionResult.withoutValue(type2);
            case Node.NCall(left, args):
                var value = _getNodeResult(left, context);
                if (Std.is(value.type.type, FunctionHaxeType)) {
                    return cast(value.type.type, FunctionHaxeType).getReturn();
                }
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NFieldAccess(left, id):
                if (left != null && id != null) {
                    var lvalue = _getNodeResult(left, context);
                    var sid = NodeTools.getId(id);
                    var member = lvalue.type.type.getInheritedMemberByName(sid);
                    if (member == null) return ExpressionResult.withoutValue(types.specTypeDynamic);
                    return ExpressionResult.withoutValue(member.getType());
                }
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            case Node.NId(str):
                if (ConstTools.isPredefinedConstant(str)) {
                    switch (str) {
                        case 'true': return ExpressionResult.withValue(types.specTypeBool, true);
                        case 'false': return ExpressionResult.withValue(types.specTypeBool, false);
                        case 'null': return ExpressionResult.withValue(types.specTypeDynamic, null);
                        default: throw 'Invalid HaxeCompletion predefined constant';
                    }
                } else {
                    var local = getEntryByName(str);
                    if (local != null) return local.getResult(context);
                    return ExpressionResult.withoutValue(types.specTypeDynamic);
                }
            case Node.NStringSqDollarPart(expr):
                return _getNodeResult(expr, context);
            case Node.NStringParts(parts):
                var value = '';
                var hasValue = true;
                for (part in parts) {
                    var result = _getNodeResult(part, context);
                    //trace(part + ' :: ' + result);
                    if (result.hasValue) {
                        value += result.value;
                    } else {
                        hasValue = false;
                    }
                }
                return hasValue ? ExpressionResult.withValue(types.specTypeString, value) : ExpressionResult.withoutValue(types.specTypeString);
            case Node.NStringSq(parts):
                return _getNodeResult(parts, context);
            default:
                throw new js.Error('Not implemented getNodeResult() $znode');
            //completion.errors.add(new ParserError(znode.pos, 'Not implemented getNodeType() $znode'));
        }

        return ExpressionResult.withoutValue(types.specTypeDynamic);
    }

    public function getLocals():Array<HaxeCompilerElement> {
        return locals.values();
    }

    public function getEntries(?out:Array<HaxeCompilerElement>):Array<HaxeCompilerElement> {
        if (out == null) out = [];
        locals.localValues(out);
        for (provider in providers) {
            provider.getEntries(out);
        }
        if (parent != null) parent.getEntries(out);
        return out;
    }

    public function getEntryByName(name:String):HaxeCompilerElement {
        if (locals.existsLocal(name)) return locals.getLocal(name);
        for (provider in providers) {
            var result = provider.getEntryByName(name);
            if (result != null) return result;
        }
        if (parent != null) {
            var result = parent.getEntryByName(name);
            if (result != null) return result;
        }
        return null;
    }

    private function getLocal(name:String):HaxeCompilerElement {
        return locals.get(name);
    }

    public function getLocalAt(index:Int):HaxeCompilerElement {
        var id = getIdentifierAt(index);
        if (id == null) return null;
        return locals.get(id.name);
    }

    public function addLocal(entry:HaxeCompilerElement):Void {
        locals.set(entry.getName(), entry);
    }

    public function createChild(node:ZNode):CompletionScope return new CompletionScope(this.completion, node, this);
}

