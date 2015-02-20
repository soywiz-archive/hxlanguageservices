package haxe.languageservices.grammar;

import haxe.languageservices.completion.CallInfo;
import haxe.languageservices.completion.CompletionScope;
import haxe.languageservices.completion.CompletionEntryThis;
import haxe.languageservices.completion.CompletionEntryArrayElement;
import haxe.languageservices.completion.CompletionProvider;
import haxe.languageservices.completion.CompletionEntry;
import haxe.languageservices.completion.TypeMembersCompletionProvider;
import haxe.languageservices.error.ParserError;
import haxe.languageservices.error.HaxeErrors;
import haxe.languageservices.type.tool.NodeTypeTools;
import haxe.languageservices.type.HaxeCompilerReferences;
import haxe.languageservices.type.UsageType;
import haxe.languageservices.node.HaxeElement;
import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.type.FunctionArgument;
import haxe.languageservices.type.FunctionRetval;
import haxe.languageservices.type.FunctionHaxeType;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.node.ConstTools;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.Reader;
import haxe.languageservices.grammar.GrammarNode;
import haxe.languageservices.node.Const;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.TextRange;
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
        
        var types = scope.types;

        switch (znode.node) {
            case Node.NFile(items) | Node.NBlock(items): for (item in items) process(item, scope.createChild(item));
            case Node.NList(items) | Node.NArray(items): for (item in items) process(item, scope);
            case Node.NVar(name, propertyInfo, type, value, doc):
                var local = new CompletionEntry(scope, name.pos, type, value, NodeTools.getId(name));
                scope.addLocal(local);
                local.getReferences().addNode(UsageType.Declaration, name);
                process(value, scope);
            case Node.NId(value):
                switch (value) {
                    case 'true', 'false', 'null':
                    default:
                        var local = scope.getEntryByName(value);
                        if (local == null) {
                            errors.add(new ParserError(znode.pos, 'Can\'t find local "$value"'));
                        } else {
                            local.getReferences().addNode(UsageType.Read, znode);
                        }
                }
            case Node.NUnary(op, value):
                process(value, scope);
            case Node.NIf(condExpr, trueExpr, falseExpr):
                var condType = scope.getNodeType(condExpr, new ProcessNodeContext());
                if (!types.specTypeBool.canAssign(condType)) {
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
                local.getReferences().addNode(UsageType.Declaration, iteratorName);
                fullForScope.addLocal(local);
                process(body, fullForScope);
            case Node.NWhile(condExpr, body) | Node.NDoWhile(body, condExpr):
                var condType = scope.getNodeType(condExpr, new ProcessNodeContext());
                if (!types.specTypeBool.canAssign(condType)) {
                    errors.add(new ParserError(condExpr.pos, 'If condition must be Bool but was ' + condType));
                }

                process(condExpr, scope);
                process(body, scope);
            case Node.NConst(_):
            case Node.NCast(expr, type):
                process(expr, scope);
                //process(type, scope);
            case Node.NCall(left, args):
                var lvalue = scope.getNodeResult(left);
                var callPos = znode.pos;
                process(left, scope);

                var argnodes:Array<ZNode> = [];
                if (args != null) switch (args.node) {
                    case Node.NList(items): argnodes = items;
                    default: throw 'Invalid args: ' + args;
                }
                
                var argscopes = [];
                for (argnode in argnodes) {
                    var argscope = scope.createChild(argnode);
                    argscopes.push(argscope);
                    process(argnode, argscope);
                }

                if (!Std.is(lvalue.type.type, FunctionHaxeType)) {
                    //trace(Type.getClassName(Type.getClass(lvalue.type)));
                    errors.add(new ParserError(znode.pos, 'Trying to call a non function expression'));
                } else {
                    var f:FunctionHaxeType = Std.instance(lvalue.type.type, FunctionHaxeType);

                    if (argnodes.length != f.args.length) {
                        errors.add(new ParserError((args != null) ? args.pos : left.pos, 'Trying to call function with ' + argnodes.length + ' arguments but required ' + f.args.length));
                    }
                    
                    var start1 = left.pos.max + 1;
                    
                    var reader = znode.pos.reader;
                    if (argnodes.length == 0) {
                        var argnode2 = new ZNode(reader.createPos(left.pos.max + 1, callPos.max), null);
                        var argscope = scope.createChild(argnode2);
                        argscope.callInfo = new CallInfo(0, start1, argnode2.pos.min, argnode2, f);
                    } else {
                        var lastIndex = 0;
                        var lastNode:ZNode = null;
                        for (n in 0 ... argnodes.length) {
                            var argnode = argnodes[n];
                            var argscope = argscopes[n];
                            var arg = f.args[n];
                            if (argscope != null && argnode != null) {
                                argscope.callInfo = new CallInfo(n, start1, argnode.pos.min, argnode, f);
                                lastIndex = n;
                                lastNode = argnode;
                            }
                            if (argnode != null && arg != null) {
                                var argResult = scope.getNodeResult(argnode);
                                var expectedArgType = arg.getSpecType(types);
                                var callArgType = argResult.type;
                                if (!expectedArgType.canAssign(callArgType)) {
                                    errors.add(new ParserError(argnode.pos, 'Invalid argument ${arg.name} expected $expectedArgType but found $argResult'));
                                }
                            }
                        }
                        if (lastNode != null) {
                            var extraIndex = lastIndex + 1;
                            var extraPos = reader.createPos(lastNode.pos.max, callPos.max);
                            var extraNode = new ZNode(extraPos, null);
                            var extraScope = scope.createChild(extraNode);
                            extraScope.callInfo = new CallInfo(extraIndex, start1, extraPos.min, extraNode, f);
                        }
                    }
                }
            case Node.NArrayAccess(left, index):
                process(left, scope);
                process(index, scope);
            case Node.NFieldAccess(_left, _id):
                var left:ZNode = _left;
                var id:ZNode = _id; 
                var idName:String = (id != null) ? id.pos.text : null;
                process(left, scope);
                var lvalue = scope.getNodeResult(left);
                
                var l:ZNode = left;

                var tidnode = new ZNode(l.pos.reader.createPos(l.pos.max, (id != null) ? id.pos.max : l.pos.max + 1), null);
                var cscope = scope.createChild(tidnode);
                cscope.unlinkFromParent();

                if (idName != null) {
                    var member = lvalue.type.type.getInheritedMemberByName(idName);
                    if (member != null) {
                        member.getReferences().addNode(UsageType.Read, id);
                        //cscope.addLocal(member);
                        //trace(member);
                    }
                }
                
                cscope.addProvider(new TypeMembersCompletionProvider(lvalue.type.type, HaxeMember.staticIsNotStatic));
            case Node.NBinOp(left, op, right):
                process(left, scope);
                process(right, scope);
                var ltype = scope.getNodeType(left);
                var rtype = scope.getNodeType(right);
            case Node.NPackage(fqName):
            case Node.NImport(fqName):
            case Node.NUsing(fqName):
            case Node.NClass(name, typeParams, extendsImplementsList, decls):
                var classScope = scope.createChild(decls);
                var clazz = types.getClass(NodeTools.getId(name));
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
                processMember(decl, modifiers, scope);
            case Node.NReturn(expr):
                process(expr, scope);
            case Node.NNew(id, call):
                //process(call, scope);
            //case Node.NPackage()
            case Node.NStringSq(parts):
                process(parts, scope);
            case Node.NStringParts(parts):
                for (part in parts) process(part, scope);
            case Node.NStringSqDollarPart(expr):
                if (expr != null) {
                    process(expr, scope);
                } else {
                }
            case Node.NArrayComprehension(expr):
                process(expr, scope);
            default:
                trace('Unhandled completion (II) ${znode}');
                //throw 'Unhandled completion (II) ${znode}';
                errors.add(new ParserError(znode.pos, 'Unhandled completion (II) ${znode}'));
                //throw ;
        }
        return scope;
    }

    private function processMember(znode:ZNode, modifiers:ZNode, scope:CompletionScope):CompletionScope {
        switch (znode.node) {
            case Node.NVar(name, propertyInfo, type, value, doc):
                var local = new CompletionEntry(scope, name.pos, type, value, NodeTools.getId(name));
                scope.addLocal(local);
                local.getReferences().addNode(UsageType.Declaration, name);
                process(value, scope);
            
            case Node.NFunction(name, typeParams, args, ret, expr, doc):
                var funcScope = scope.createChild(znode);
                var nameScope = scope.createChild(name);
                //nameScope.addLocal();
                var bodyScope = funcScope.createChild(expr);

                if (scope.currentClass != null) {
                    funcScope.addProvider(new TypeMembersCompletionProvider(scope.currentClass));
                    bodyScope.addLocal(new CompletionEntryThis(scope, scope.currentClass));
                    nameScope.addLocal(scope.currentClass.getInheritedMemberByName(NodeTools.getId(name)));
                }

                processFunctionArgs(args, funcScope, funcScope);

                process(expr, bodyScope);
            default:
                errors.add(new ParserError(znode.pos, 'Unhandled completion (III) ${znode}'));
        }
        return scope;
    }
    
    private function processFunctionArgs(znode:ZNode, scope:CompletionScope, scope2:CompletionScope):Void {
        if (znode == null || znode.node == null) return;
        switch (znode.node) {
            case Node.NList(items): for (item in items) processFunctionArgs(item, scope, scope2);
            case Node.NFunctionArg(opt, name, type, value, doc):
                //trace(type);
                var e = new CompletionEntry(scope2, name.pos, type, value, NodeTools.getId(name));
                //trace(e.getType(new ProcessNodeContext()));
                scope.addLocal(e);
                e.getReferences().addNode(UsageType.Declaration, name);
            default:
                throw 'Unhandled completion (I) $znode';
                errors.add(new ParserError(znode.pos, 'Unhandled completion (I) $znode'));
        }
    }
}
