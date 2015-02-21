package haxe.languageservices.grammar;
import haxe.languageservices.completion.CallInfo;
import haxe.languageservices.type.HaxeThisElement;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.node.Const;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.ConstTools;
import haxe.languageservices.type.UsageType;
import haxe.languageservices.type.HaxeLocalVariable;
import haxe.languageservices.completion.TypeMembersCompletionProvider;
import haxe.languageservices.completion.LocalScope;
import haxe.languageservices.completion.CompletionProvider;
import haxe.languageservices.type.HaxeModifiers;
import haxe.languageservices.type.HaxePackage;
import haxe.languageservices.type.FieldHaxeMember;
import haxe.languageservices.type.MethodHaxeMember;
import haxe.languageservices.error.ParserError;
import haxe.languageservices.error.HaxeErrors;
import haxe.languageservices.type.HaxeDoc;
import haxe.languageservices.type.tool.NodeTypeTools;
import haxe.languageservices.type.FunctionArgument;
import haxe.languageservices.type.FunctionHaxeType;
import haxe.languageservices.type.EnumHaxeType;
import haxe.languageservices.type.AbstractHaxeType;
import haxe.languageservices.type.InterfaceHaxeType;
import haxe.languageservices.type.TypedefHaxeType;
import haxe.languageservices.type.TypeReference;
import haxe.languageservices.type.ClassHaxeType;
import haxe.languageservices.type.HaxeModifiers;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.util.StringUtils;
import haxe.languageservices.grammar.GrammarResult;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Node;

using StringTools;

class HaxeTypeBuilder {
    public var errors:HaxeErrors;
    public var types:HaxeTypes;

    public function new(types:HaxeTypes, errors:HaxeErrors) {
        this.types = types;
        this.errors = errors;
    }

    public function processResult(result:GrammarResult) {
        switch (result) {
            case GrammarResult.RMatchedValue(v): return process(cast(v));
            default: throw "Can't process";
        }
        return null;
    }
    
    private function error(pos:TextRange, text:String) {
        errors.add(new ParserError(pos, text));
    }
    
    private function checkPackage(nidList2:ZNode):Array<String> {
        var parts = [];
        switch (nidList2.node) {
            case Node.NIdList(nidList): for (nid in nidList) switch (nid.node) {
                case Node.NId(c):
                    if (!StringUtils.isLowerCase(c)) {
                        error(nidList2.pos, 'package should be lowercase');
                    }
                    parts.push(c);
                default: throw 'Invalid';
            }
            default: throw 'Invalid';
        }
        return parts;
    }
    
    private function getId(znode:ZNode):String return NodeTools.getId(znode);

    public function process(znode:ZNode, ?builtTypes:Array<HaxeType>):Array<HaxeType> {
        if (builtTypes == null) builtTypes = [];
        if (!ZNode.isValid(znode)) return builtTypes;
        switch (znode.node) {
            case Node.NFile(items):
                var info = { index: 0, packag: types.rootPackage, types: builtTypes };
                for (item in items) {
                    processTopLevel(item, info, builtTypes);
                    info.index++;
                }
                for (type in builtTypes) {
                    for (member in type.members) {
                        if (Std.is(member, MethodHaxeMember)) {
                            var method:MethodHaxeMember = cast(member, MethodHaxeMember);
                            //trace(method);
                            _processMethodBody(method.func.body, new LocalScope(method.scope), method.func);
                        }
                    }
                }
            default:
                throw 'Expected haxe file but found $znode';
        }
        return builtTypes;
    }

    public function processTopLevel(item:ZNode, info: { index: Int, packag: HaxePackage, types: Array<HaxeType> }, builtTypes:Array<HaxeType>) {
        switch (item.node) {
            case Node.NPackage(name):
                if (info.index != 0) {
                    error(item.pos, 'Package should be first element in the file');
                } else {
                    var pathParts = checkPackage(name);
                    info.packag = types.rootPackage.access(pathParts.join('.'), true);
                }
            case Node.NImport(name) | Node.NUsing(name):
                if (builtTypes.length > 0) error(item.pos, 'Import should appear before any type decl');
            case Node.NClass(name, typeParams, extendsImplementsList, decls):
                var typeName = getId(name);

                checkClassName(name.pos, typeName);

                if (info.packag.accessType(typeName) != null) {
                    error(item.pos, 'Type name $typeName is already defined in this module');
                }
                var type:ClassHaxeType = info.packag.accessTypeCreate(typeName, item.pos, ClassHaxeType);
                builtTypes.push(type);
                if (ZNode.isValid(extendsImplementsList)) {
                    switch (extendsImplementsList.node) {
                        case Node.NList(items): for (item in items) { switch (item.node) {
                            case Node.NExtends(type2, params2):
                                if (type.extending != null) {
                                    error(item.pos, 'multiple inheritance not supported in haxe');
                                }
                                var className2 = type2.pos.text.trim();
                                type.extending = new TypeReference(types, className2, item);
                            case Node.NImplements(type2, params2):
                                var className2 = type2.pos.text.trim();
                                type.implementing.push(new TypeReference(types, className2, item));
                            default: throw 'Invalid';
                        } }
                        default: throw 'Invalid';
                    }
                }
                item.completion = new TypeMembersCompletionProvider(type);

//trace(extendsImplementsList);
                type.node = item;
                processClass(type, decls);
            case Node.NInterface(name, typeParams, extendsImplementsList, decls):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:InterfaceHaxeType = info.packag.accessTypeCreate(typeName, item.pos, InterfaceHaxeType);
                item.completion = new TypeMembersCompletionProvider(type);
                builtTypes.push(type);
                processClass(type, decls);
            case Node.NTypedef(name):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:TypedefHaxeType = info.packag.accessTypeCreate(typeName, item.pos, TypedefHaxeType);
                item.completion = new TypeMembersCompletionProvider(type);
                builtTypes.push(type);
            case Node.NAbstract(name):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:AbstractHaxeType = info.packag.accessTypeCreate(typeName, item.pos, AbstractHaxeType);
                item.completion = new TypeMembersCompletionProvider(type);
                builtTypes.push(type);
            case Node.NEnum(name):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:EnumHaxeType = info.packag.accessTypeCreate(typeName, item.pos, EnumHaxeType);
                item.completion = new TypeMembersCompletionProvider(type);
                builtTypes.push(type);
            default:
                error(item.pos, 'invalid node');
        }
    }
    
    private function processMemberModifiers(modifiers:ZNode) {
        var mods = new HaxeModifiers();
        if (ZNode.isValid(modifiers)) switch (modifiers.node) {
            case Node.NList(parts):
                for (part in parts) {
                    if (ZNode.isValid(part)) {
                        switch (part.node) {
                            case Node.NKeyword(z): mods.add(z);
                            default: throw 'Invalid (I) $part';
                        }
                    }
                }
            default: throw 'Invalid (II) $modifiers';
        }
        return mods;
    }

    private function processClass(type:HaxeType, decls:ZNode) {
        switch (decls.node) {
            case Node.NList(members):
                for (member in members) {
                    switch (member.node) {
                        case Node.NMember(modifiers, decl):
                            var mods = processMemberModifiers(modifiers);
                            processMember(type, member, mods, decl);
                        default: throw 'Invalid (IV) $member';
                    }
                }
            default:
                throw 'Invalid (V) $decls';
        }
    }
    
    private function processMember(type:HaxeType, member:ZNode, mods:HaxeModifiers, decl:ZNode) {
        if (ZNode.isValid(decl)) switch (decl.node) {
            case Node.NVar(vname, propInfo, vtype, vvalue, doc):
                checkType(vtype);
                var field = new FieldHaxeMember(type, member.pos, vname);
                field.modifiers = mods;
                field.fieldtype = getTypeNodeType(vtype);
                //field.value = _processExprValue();
                
                if (type.existsMember(field.name)) {
                    error(vname.pos, 'Duplicate class field declaration : ${field.name}');
                }
                type.addMember(field);
            case Node.NFunction(vname, vtypeParams, vargs, vret, vexpr, doc):
                checkFunctionDeclArgs(vargs);
                checkType(vret);
                var fretval = getTypeNodeType(vret);
                var func = new FunctionHaxeType(types, type, member.pos, vname, [], fretval, vexpr);

                var scope = new LocalScope(TypeMembersCompletionProvider.forType(type, !mods.isStatic, true));
                if (!mods.isStatic) {
                    scope.add(new HaxeThisElement(type));
                }

                if (ZNode.isValid(vargs)) switch (vargs.node) {
                    case Node.NList(_vargs): for (arg in _vargs) {
                        if (ZNode.isValid(arg)) switch (arg.node) {
                            case Node.NFunctionArg(opt, name, type, value, doc):
                                var vexpr = _processExprValue(value, scope, func);
                                var arg = new FunctionArgument(types, func.args.length, name);
                                arg.result = vexpr;
                                arg.type = getTypeNodeType2(type);
                                func.args.push(arg);
                                name.completion = scope;
                                arg.getReferences().addNode(UsageType.Declaration, name);
                                scope.add(arg);
                            default:
                                throw 'Invalid (VII) $arg';
                        }
                    }
                    default: throw 'Invalid (VI) $vargs';
                }


                var method = new MethodHaxeMember(func);
                method.doc = new HaxeDoc(NodeTools.getId(doc));
                method.modifiers = mods;
                method.scope = scope;

                if (type.existsMember(method.name)) {
                    error(vname.pos, 'Duplicate class field declaration : ${method.name}');
                }
                type.addMember(method);
            default:
                throw 'Invalid (III) $decl';
        }
    }
    
    private function getTypeNodeType(vret:ZNode):TypeReference {
        if (vret == null) return new TypeReference(types, 'Dynamic', null);
        return new TypeReference(types, vret.pos.text.trim(), vret);
    }

    private function getTypeNodeType2(vret:ZNode):SpecificHaxeType {
        if (vret == null) return types.specTypeDynamic;
        return types.createSpecific(types.getType(vret.pos.text.trim()));
    }

    private function checkFunctionDeclArgs(znode:ZNode):Void {
        if (!ZNode.isValid(znode)) return;
        switch (znode.node) {
            case Node.NList(items): for (item in items) checkFunctionDeclArgs(item);
            case Node.NFunctionArg(opt, id, type, value, doc): checkType(type);
            default: throw 'Invalid (VI) $znode';
        }
    }
    
    private function checkType(znode:ZNode):Void {
        if (!ZNode.isValid(znode)) return;
        switch (znode.node) {
            case Node.NId(name):
                checkClassName(znode.pos, name);
            case Node.NWrapper(item): checkType(item);
            case Node.NTypeParams(items):
            case Node.NList(items): for (item in items) checkType(item);
            default: throw 'Invalid (VII) $znode';
        }
        //checkClassName(znode.pos, znode.pos.text);
    }
    
    private function checkClassName(pos:TextRange, typeName:String):Void {
        if (!StringUtils.isFirstUpper(typeName)) {
            error(pos, 'Type name should start with an uppercase letter');
        }
    }
    
    public var debug = false;

    public function processMethodBody(expr:ZNode, scope:LocalScope, ?func:FunctionHaxeType):LocalScope {
        //new FunctionHaxeType(types, );
        return _processMethodBody(expr, scope, func);
    }
    
    private function _processMethodBody(expr:ZNode, scope:LocalScope, func:FunctionHaxeType):LocalScope {
        if (!ZNode.isValid(expr)) return scope;
        expr.completion = scope;
        //if (debug) trace(expr.node);
        switch (expr.node) {
            case Node.NList(items): for (item in items) _processMethodBody(item, scope, func);
            case Node.NBlock(items):
                var blockScope = new LocalScope(scope);
                for (item in items) _processMethodBody(item, blockScope, func);
            case Node.NVar(vname, propertyInfo, vtype, vvalue, doc):
                var localVariable = new HaxeLocalVariable(vname);
            
                localVariable.getReferences().addNode(UsageType.Declaration, vname);
                expr.element = localVariable;
                //trace('declared var: ' + vname);
                scope.add(localVariable);
                checkType(vtype);
                localVariable.resultResolver = function(context) {
                    return _processExprValue(vvalue, scope, func);
                }
                return _processMethodBody(vvalue, scope, func);
            case Node.NId(name):
                //trace('field: ' + name);
                if (!ConstTools.isPredefinedConstant(name)) {
                    var id = scope.getEntryByName(name);
                    expr.element = id;
                    //trace(id);
                    if (id == null) {
                        trace('Not found id: ' + name + ' in ' + expr.pos.reader.str);
                        trace(scope.getEntries());
                    } else {
                        id.getReferences().addNode(UsageType.Read, expr);
                    }
                }
            case Node.NBinOp(left, op, right):
                _processMethodBody(left, scope, func);
                _processMethodBody(right, scope, func);
            case Node.NConst(value):
            case Node.NCall(left, args):
                _processMethodBody(left, scope, func);

                var znode = expr;
                var lvalue = _processExprValue(left, scope, func);
                var callPos = znode.pos;

                var argnodes:Array<ZNode> = [];
                if (args != null) switch (args.node) {
                    case Node.NList(items): argnodes = items;
                    default: throw 'Invalid args: ' + args;
                }

                for (argnode in argnodes) {
                    _processMethodBody(argnode, scope, func);
                }

                if (!Std.is(lvalue.type.type, FunctionHaxeType)) {
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
                        argnode2.callInfo = new CallInfo(0, start1, argnode2.pos.min, argnode2, f);
                        znode.children.unshift(argnode2);
                    } else {
                        var lastIndex = 0;
                        var lastNode:ZNode = null;
                        for (n in 0 ... argnodes.length) {
                            var argnode = argnodes[n];
                            var arg = f.args[n];
                            if (argnode != null) {
                                argnode.callInfo = new CallInfo(n, start1, argnode.pos.min, argnode, f);
                                lastIndex = n;
                                lastNode = argnode;
                            }
                            if (argnode != null && arg != null) {
                                //var argResult = scope.getNodeResult(argnode);
                                var argName = arg.getName();
                                var argResult = _processExprValue(argnode, scope, func);
                                var expectedArgType = arg.getResult().type;
                                var callArgType = argResult.type;
                                if (!expectedArgType.canAssign(callArgType)) {
                                    errors.add(new ParserError(argnode.pos, 'Invalid argument $argName expected $expectedArgType but found $argResult'));
                                }
                            }
                        }
                        if (lastNode != null) {
                            var extraIndex = lastIndex + 1;
                            var extraPos = reader.createPos(lastNode.pos.max, callPos.max);
                            var extraNode = new ZNode(extraPos, null);
                            extraNode.callInfo = new CallInfo(extraIndex, start1, extraPos.min, extraNode, f);
                            znode.children.unshift(extraNode);
                        }
                    }
                }
            case Node.NIf(condExpr, trueExpr, falseExpr):
                _processMethodBody(condExpr, scope, func);
                _processMethodBody(trueExpr, scope, func);
                _processMethodBody(falseExpr, scope, func);
                var econd = _processExprValue(condExpr, scope, func);
                if (!types.specTypeBool.canAssign(econd.type)) {
                    errors.add(new ParserError(condExpr.pos, 'If condition must be Bool but was ' + econd.type));
                }
            case Node.NUnary(op, value):
                _processMethodBody(value, scope, func);
            /*
            case Node.NFieldAccess(left, id):
                _processMethodBody(left, scope, func);
                var expr2 = _processExprValue(left, scope, func);
                //expr2.type.type.membersByName
                //trace(expr2);
                //trace(left);
            */
            case Node.NFieldAccess(_left, _id):
                var left:ZNode = _left;
                var id:ZNode = _id;
                var idName:String = (id != null) ? id.pos.text : null;
                _processMethodBody(left, scope, func);
                var lvalue = _processExprValue(left, scope, func);
                id.completion = new TypeMembersCompletionProvider(lvalue.type.type);
                lvalue.type.type.getMember(idName).getReferences().addNode(UsageType.Read, id);

                /*
                var tidnode = new ZNode(l.pos.reader.createPos(l.pos.max, (id != null) ? id.pos.max : l.pos.max + 1), null);
                var cscope = scope.createChild(tidnode);
                cscope.unlinkFromParent();

                if (idName != null) {
                    var member = lvalue.type.type.getInheritedMemberByName(idName);
                    if (member != null) {
                        member.getReferences().addNode(UsageType.Read, id);
                    }
                }

                cscope.addProvider(new TypeMembersCompletionProvider(lvalue.type.type, HaxeMember.staticIsNotStatic));
                */

            case Node.NReturn(expr):
                _processMethodBody(expr, scope, func);
                if (func != null) func.returns.push(_processExprValue(expr, scope, func));
            case Node.NArray(items) | Node.NList(items):
                for (item in items) _processMethodBody(item, scope, func);
            default:
                trace('TypeBuilder: Unimplemented body $expr');
                errors.add(new ParserError(expr.pos, 'TypeBuilder: Unimplemented body $expr'));
                throw 'TypeBuilder: Unimplemented body $expr';
        }
        return scope;
    }

    public function processExprValue(expr:ZNode, ?scope:LocalScope, ?func:FunctionHaxeType):ExpressionResult {
        if (scope == null) scope = new LocalScope();
        return _processExprValue(expr, scope, func);
    }

    private function _processExprValue(expr:ZNode, scope:LocalScope, func:FunctionHaxeType):ExpressionResult {
        if (!ZNode.isValid(expr)) return ExpressionResult.withoutValue(types.specTypeDynamic);
        expr.completion = scope;
        switch (expr.node) {
            case Node.NId(name):
                if (ConstTools.isPredefinedConstant(name)) {
                    switch (name) {
                        case "true": return ExpressionResult.withValue(types.specTypeBool, true);
                        case "false": return ExpressionResult.withValue(types.specTypeBool, false);
                        case "null": return ExpressionResult.withValue(types.specTypeDynamic, null);
                        default:
                    }
                } else {
                    var id = scope.getEntryByName(name);
                    if (id != null) return id.getResult();
                }
            case Node.NArray(pp):
                switch (pp[0].node) {
                    case Node.NList(items):
                        return ExpressionResult.withoutValue(types.createArray(types.unify([for (item in items) _processExprValue(item, scope, func).type ])));
                    default:
                        trace('TypeBuilder: Unimplemented body array.list $expr');
                }
            case Node.NArrayAccess(left, index):
                var lresult = _processExprValue(left, scope, func);
                var iresult = _processExprValue(index, scope, func);
                return ExpressionResult.withoutValue(types.getArrayElement(lresult.type));
            case Node.NIf(cond, trueExpr, falseExpr):
                var texp = _processExprValue(trueExpr, scope, func);
                var fexp = _processExprValue(falseExpr, scope, func);
                return ExpressionResult.unify2(types, texp, fexp);
            case Node.NUnary(op, value):
                return _processExprValue(value, scope, func);
            case Node.NConst(Const.CInt(value)): return ExpressionResult.withValue(types.specTypeInt, value);
            case Node.NConst(Const.CFloat(value)): return ExpressionResult.withValue(types.specTypeFloat, value);
            case Node.NConst(Const.CString(value)): return ExpressionResult.withValue(types.specTypeString, value);
            case Node.NFieldAccess(left, id):
                var expr2 = _processExprValue(left, scope, func);
                return ExpressionResult.withoutValue(expr2.type.access(NodeTools.getId(id)));
            case Node.NBinOp(left, op, right):
                var lv = _processExprValue(left, scope, func);
                var rv = _processExprValue(right, scope, func);

                function operator(doOp: Dynamic -> Dynamic -> Dynamic) {
                    if (lv.hasValue && rv.hasValue) {
                        return ExpressionResult.withValue(lv.type, doOp(lv.value, rv.value));
                    }
                    return ExpressionResult.withoutValue(types.specTypeInt);
                }

                switch (op) {
                    case '==', '!=': return ExpressionResult.withoutValue(types.specTypeBool);
                    case '...': return ExpressionResult.withoutValue(types.createArray(types.specTypeInt));
                    case '+': return operator(function(a, b) return a + b);
                    case '-': return operator(function(a, b) return a - b);
                    case '%': return operator(function(a, b) return a % b);
                    case '/': return operator(function(a, b) return a / b);
                    case '*': return operator(function(a, b) return a * b);
                    default: throw 'Unknown operator $op';
                }
                return ExpressionResult.withoutValue(types.specTypeDynamic);
            default:
                //trace('TypeBuilder: Unimplemented processExprValue $expr');
                errors.add(new ParserError(expr.pos, 'TypeBuilder: Unimplemented processExprValue $expr'));
                throw 'TypeBuilder: Unimplemented processExprValue $expr';
        }
        return ExpressionResult.withoutValue(types.specTypeDynamic);
    }

/*

class HaxeCompletion {
    public var errors:HaxeErrors;
    public var types:HaxeTypes;

    public function new(types:HaxeTypes, ?errors:HaxeErrors) {
        this.types = types;
        this.errors = (errors != null) ? errors : new HaxeErrors();
    }

    public function processCompletion(znode:ZNode):CompletionScope {
        return process(znode, new CompletionScope(this, znode));
    }

    private function process(znode:ZNode, scope:CompletionScope):CompletionScope {
        if (znode == null || znode.node == null) return scope;

        var types = scope.types;

        switch (znode.node) {
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

            case Node.NArrayAccess(left, index):
                process(left, scope);
                process(index, scope);
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
*/

    /*
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
    */
}
