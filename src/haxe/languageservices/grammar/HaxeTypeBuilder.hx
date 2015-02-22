package haxe.languageservices.grammar;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.error.QuickFixAction;
import haxe.languageservices.error.QuickFix;
import haxe.languageservices.error.QuickFix;
import haxe.languageservices.node.ProcessNodeContext;
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
    
    private function error(pos:TextRange, text:String, ?fixes:Array<QuickFix>) {
        errors.add(new ParserError(pos, text, fixes));
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
        executePending();
        return builtTypes;
    }
    
    private var later:Array<Void -> Void> = [];
    private function addLater(c: Void -> Void) {
        later.push(c);
    }
    
    private function executePending() {
        while (later.length > 0) {
            var e = later.shift();
            e();
        }
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
            case Node.NClass(_name, typeParams, extendsImplementsList, decls):
                var name:ZNode = _name;
                var typeName = getId(name);

                checkClassName(name.pos, typeName);

                if (info.packag.accessType(typeName) != null) {
                    error(item.pos, 'Type name $typeName is already defined in this module');
                }
                var type:ClassHaxeType = info.packag.accessTypeCreate(typeName, item.pos, ClassHaxeType);

                var ls = new LocalScope();
                name.completion = ls;
                type.nameElement = new HaxeLocalVariable(name, ls, function(context) {
                    return types.resultAnyDynamic;
                });
                ls.add(type.nameElement);
                type.nameElement.getReferences().addNode(UsageType.Declaration, name);

                builtTypes.push(type);
                if (ZNode.isValid(extendsImplementsList)) {
                    switch (extendsImplementsList.node) {
                        case Node.NList(items): for (item in items) { switch (item.node) {
                            case Node.NExtends(_type2, params2):
                                var type2:ZNode = _type2;
                                if (type.extending != null) {
                                    error(item.pos, 'multiple inheritance not supported in haxe');
                                }
                                var className2 = type2.pos.text.trim();
                                type.extending = new TypeReference(types, className2, item);
                                addLater(function() {
                                    var e = type.extending.getClass();
                                    if (e != null) {
                                        type2.completion = e.nameElement.scope;
                                        e.nameElement.getReferences().addNode(UsageType.Read, type2);
                                    }
                                });
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
        var mods = new HaxeModifiers(modifiers);
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
                
                if (type.existsMember(field.name)) {
                    error(vname.pos, 'Duplicate class field declaration : ${field.name}');
                }
                type.addMember(field);
            case Node.NFunction(doc, vname, vtypeParams, vargs, vret, vexpr):
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
                                var vexpr = processExprValue(value, scope, func);
                                var arg = new FunctionArgument(types, func.args.length, name, scope);
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
                method.doc = func.doc = new HaxeDoc(NodeTools.getId(doc));

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

    // @TODO: NodeTypeTools.getTypeDeclType
    private function getTypeNodeType2(vret:ZNode):SpecificHaxeType {
        return NodeTypeTools.getTypeDeclType(types, vret);
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
    
    private function generateCast(exprText:String, fromType:SpecificHaxeType, toType:SpecificHaxeType) {
        switch ([fromType.toString(), toType.toString()]) {
            case ['Float', 'Int']: return 'Std.int($exprText)';
            case ['String', 'Int']: return 'Std.parseInt($exprText)';
            case ['String', 'Float']: return 'Std.parseFloat($exprText)';
            default:
        }
        return 'cast($exprText, ${toType.toString()})';
    }
    
    private function _processMethodBody(expr:ZNode, scope:LocalScope, func:FunctionHaxeType):LocalScope {
        if (!ZNode.isValid(expr)) return scope;
        
        function doExpr(expr:ZNode, ?context:ProcessNodeContext):ExpressionResult {
            if (context == null) context = new ProcessNodeContext();
            return _processExprValue(expr, scope, func, context);
        }

        function doBody(expr:ZNode, ?scope2:LocalScope):LocalScope {
            if (scope2 == null) scope2 = scope;
            return _processMethodBody(expr, scope2, func);
        }

        expr.completion = scope;
        //if (debug) trace(expr.node);
        switch (expr.node) {
            case Node.NList(items): for (item in items) doBody(item);
            case Node.NBlock(items):
                var blockScope = new LocalScope(scope);
                for (item in items) doBody(item, blockScope);
            case Node.NVar(vname, propertyInfo, _vtype, _vvalue, doc):
                var vtype:ZNode = _vtype;
                var vvalue:ZNode = _vvalue;
                var localVariable = new HaxeLocalVariable(vname, scope);
                localVariable.getReferences().addNode(UsageType.Declaration, vname);
                expr.element = localVariable;
                //trace('declared var: ' + vname);
                scope.add(localVariable);
                checkType(vtype);
                var ntype:SpecificHaxeType = vtype != null ? getTypeNodeType2(vtype) : null;
                localVariable.resultResolver = function(context) {
                    if (ntype != null) return types.result(ntype);
                    return doExpr(vvalue, context);
                }
                if (ntype != null && vvalue != null) {
                    var toType = ntype;
                    var exprType = doExpr(vvalue).type;
                    if (!ntype.canAssign(exprType)) {
                        error(vvalue.pos, 'Can\'t assign ${exprType} to ${ntype}', [
                            new QuickFix('Change type', function() {
                                return [QuickFixAction.QFReplace(vtype.pos, exprType.toString())];
                            }),
                            new QuickFix('Add cast', function() {
                                return [QuickFixAction.QFReplace(
                                    vvalue.pos,
                                    generateCast(vvalue.pos.text, exprType, toType)
                                )];
                            })
                        ]);
                    }
                }
                return doBody(vvalue);
            case Node.NId(name):
                //trace('field: ' + name);
                if (!ConstTools.isPredefinedConstant(name)) {
                    var id = scope.getEntryByName(name);
                    expr.element = id;
                    //trace(id);
                    if (id == null) {
                        //trace('Not found id: ' + name + ' in ' + expr.pos.reader.str);
                        //trace(scope.getEntries());
                        error(expr.pos, 'Identifier $name not found');
                    } else {
                        id.getReferences().addNode(UsageType.Read, expr);
                    }
                }
            case Node.NBinOp(_left, _op, _right):
                var left:ZNode = _left;
                var op:String = _op;
                var right:ZNode = _right;
                if (op == '=') {
                    // @TODO: Check lvalue
                    //checkLValue(left);
                    var tleft = doExpr(left);
                    var tright = doExpr(right);
                    if (!tleft.type.canAssign(tright.type)) {
                        error(expr.pos, 'Can\'t assign ${tright.type} to ${tleft.type}', [
                            new QuickFix('Add cast', function() {
                                return [QuickFixAction.QFReplace(
                                    right.pos,
                                    generateCast(right.pos.text, tright.type, tleft.type)
                                )];
                            })
                        ]);
                    }
                } else {

                }
                doBody(left);
                doBody(right);
            case Node.NConst(value):
            case Node.NCall(left, args):
                doBody(left);

                var znode = expr;
                var lvalue = processExprValue(left, scope, func);
                var callPos = znode.pos;

                var argnodes:Array<ZNode> = [];
                if (args != null) switch (args.node) {
                    case Node.NList(items): argnodes = items;
                    default: throw 'Invalid args: ' + args;
                }

                for (argnode in argnodes) doBody(argnode);

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
                        argnode2.callInfo = new CallInfo(0, start1, argnode2.pos.min, callPos.max, argnode2, f);
                        znode.children.unshift(argnode2);
                    } else {
                        var lastIndex = 0;
                        var lastNode:ZNode = null;
                        for (n in 0 ... argnodes.length) {
                            var argnode = argnodes[n];
                            var arg = f.args[n];
                            if (argnode != null) {
                                argnode.callInfo = new CallInfo(n, start1, argnode.pos.min, callPos.max, argnode, f);
                                lastIndex = n;
                                lastNode = argnode;
                            }
                            if (argnode != null && arg != null) {
                                //var argResult = scope.getNodeResult(argnode);
                                var argName = arg.getName();
                                var argResult = processExprValue(argnode, scope, func);
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
                            extraNode.callInfo = new CallInfo(extraIndex, start1, extraPos.min, callPos.max, extraNode, f);
                            znode.children.unshift(extraNode);
                        }
                    }
                }
            case Node.NIf(condExpr, trueExpr, falseExpr):
                doBody(condExpr);
                doBody(trueExpr);
                doBody(falseExpr);
                var econd = doExpr(condExpr);
                if (!types.specTypeBool.canAssign(econd.type)) {
                    errors.add(new ParserError(condExpr.pos, 'If condition must be Bool but was ' + econd.type));
                }
            case Node.NUnary(op, value):
                doBody(value);
            case Node.NFieldAccess(_left, _id):
                var left:ZNode = _left;
                var id:ZNode = _id;
                _processMethodBody(left, scope, func);
                var lvalue = processExprValue(left, scope, func);
                if (id == null) {
                    // @TODO: This node should exist actually (we should create non-semantic nodes)
                    var reader = expr.pos.reader;
                    var noid = new ZNode(reader.createPos(left.pos.max + 1, expr.pos.max), null);
                    noid.completion = new TypeMembersCompletionProvider(lvalue.type.type);
                    expr.children.unshift(noid);
                } else {
                    var idName:String = (id != null) ? id.pos.text : null;
                    id.completion = new TypeMembersCompletionProvider(lvalue.type.type);
                    var member = lvalue.type.type.getInheritedMemberByName(idName);
                    if (member != null) {
                        member.getReferences().addNode(UsageType.Read, id);
                    } else {
                        error(id.pos, 'Can\'t find member $idName in ${lvalue.type.type}');
                    }
                }
            case Node.NReturn(expr):
                doBody(expr);
                if (func != null) func.returns.push(processExprValue(expr, scope, func));
            case Node.NArray(items) | Node.NList(items):
                for (item in items) doBody(item);
            case Node.NArrayAccess(left, index):
                doBody(left);
                doBody(index);
            case Node.NStringSq(part):
                doBody(part);
            case Node.NStringParts(parts):
                for (part in parts) doBody(part);
            case Node.NStringSqDollarPart(expr):
                if (expr != null) doBody(expr);
            case Node.NFor(_iteratorName, _iteratorExpr, _body):
                var iteratorName:ZNode = _iteratorName;
                var iteratorExpr:ZNode = _iteratorExpr;
                var body:ZNode = _body;
                var innerScope = new LocalScope(scope);
                doBody(iteratorExpr);
                var local = new HaxeLocalVariable(iteratorName, innerScope, function(context:ProcessNodeContext) {
                    return doExpr(iteratorExpr, context).getArrayElement();
                });
                local.getReferences().addNode(UsageType.Declaration, iteratorName);
                innerScope.add(local);
                // @TODO: there should be a completion scope for searching and for declaring?
                iteratorName.completion = innerScope;
                body.completion = innerScope;
                doBody(body, innerScope);
            case Node.NWhile(condExpr, body) | Node.NDoWhile(body, condExpr):
                var condType = doExpr(condExpr).type;
                if (!types.specTypeBool.canAssign(condType)) {
                    errors.add(new ParserError(condExpr.pos, 'While condition must be Bool but was ' + condType));
                }

                doBody(condExpr);
                doBody(body);
            case Node.NSwitch(subject, cases):
                doBody(subject);
                doBody(cases);
            case Node.NCast(expr, type):
                doBody(expr);
            
                // @TODO:
                //doBody(type);
            case Node.NArrayComprehension(expr):
                doBody(expr);
            case Node.NNew(id, call):
                //doBody(call);
            case Node.NTryCatch(tryCode, catches):
                doBody(tryCode);
                doBody(catches);
            case Node.NCatch(_name, _type, _code):
                var name:ZNode = _name;
                var type:ZNode = _type;
                var code:ZNode = _code;
                //doBody(name);
                //doBody(type);
                var catchScope = new LocalScope(scope);
                var local = new HaxeLocalVariable(name, scope, function(context) {
                    return types.result(getTypeNodeType2(type));
                });
                if (type == null) {
                    error(name.pos, 'Catch must specify type');
                }
                local.getReferences().addNode(UsageType.Declaration, name);
                name.completion = catchScope;
                catchScope.add(local);
                doBody(code, catchScope);
            default:
                trace('TypeBuilder: Unimplemented body $expr');
                errors.add(new ParserError(expr.pos, 'TypeBuilder: Unimplemented body $expr'));
                throw 'TypeBuilder: Unimplemented body $expr';
        }
        return scope;
    }

    public function processExprValue(expr:ZNode, ?scope:LocalScope, ?func:FunctionHaxeType, ?context:ProcessNodeContext):ExpressionResult {
        if (scope == null) scope = new LocalScope();
        if (context == null) context = new ProcessNodeContext();
        return _processExprValue(expr, scope, func, context);
    }
    
    private function _processExprValue(expr:ZNode, scope:LocalScope, func:FunctionHaxeType, context:ProcessNodeContext):ExpressionResult {
        if (!ZNode.isValid(expr)) return ExpressionResult.withoutValue(types.specTypeDynamic);
        if (context.isExplored(expr)) {
            context.recursionDetected();
            return ExpressionResult.withoutValue(types.specTypeDynamic);
        }
        context.markExplored(expr);
        //trace(expr + ' : ' + context);
        expr.completion = scope;
        function doExpr(expr:ZNode):ExpressionResult {
            return _processExprValue(expr, scope, func, context);
        }
        switch (expr.node) {
            case Node.NBlock(values):
                return types.resultAnyDynamic;
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
                    if (id != null) return id.getResult(context);
                }
            case Node.NArray(pp):
                switch (pp[0].node) {
                    case Node.NList(items):
                        return ExpressionResult.withoutValue(types.createArray(types.unify([for (item in items) _processExprValue(item, scope, func, context).type ])));
                    default:
                        trace('Invalid array $expr');
                }
            case Node.NList(values):
                return types.result(types.unify([for (value in values) doExpr(value).type]));
            case Node.NIf(cond, trueExpr, falseExpr):
                var texp = doExpr(trueExpr);
                var fexp = doExpr(falseExpr);
                return ExpressionResult.unify2(types, texp, fexp);
            case Node.NUnary(op, value):
                return doExpr(value);
            case Node.NConst(Const.CInt(value)): return ExpressionResult.withValue(types.specTypeInt, value);
            case Node.NConst(Const.CFloat(value)): return ExpressionResult.withValue(types.specTypeFloat, value);
            case Node.NConst(Const.CString(value)): return ExpressionResult.withValue(types.specTypeString, value);
            case Node.NFieldAccess(left, id):
                var expr2 = doExpr(left);
                return ExpressionResult.withoutValue(expr2.type.access(NodeTools.getId(id)));
            case Node.NBinOp(left, op, right):
                var lv = doExpr(left);
                var rv = doExpr(right);

                function operator(doOp: Dynamic -> Dynamic -> Dynamic) {
                    if (lv.hasValue && rv.hasValue) {
                        return ExpressionResult.withValue(lv.type, doOp(lv.value, rv.value));
                    }
                    return types.result(types.specTypeInt);
                }

                switch (op) {
                    case '==', '!=': return types.result(types.specTypeBool);
                    case '...': return types.result(types.createArray(types.specTypeInt));
                    case '+': return operator(function(a, b) return a + b);
                    case '-': return operator(function(a, b) return a - b);
                    case '%': return operator(function(a, b) return a % b);
                    case '/': return types.result(types.specTypeFloat);
                    case '*': return operator(function(a, b) return a * b);
                    case '=': return rv;
                    default: throw 'Unknown operator $op';
                }
                return types.resultAnyDynamic;
            case Node.NStringSqDollarPart(expr):
                return doExpr(expr);
            case Node.NArrayAccess(left, index):
                var lresult = doExpr(left);
                var iresult = doExpr(index);
                return types.result(lresult.type.getArrayElement());
            case Node.NStringParts(parts):
                var value = '';
                var hasValue = true;
                for (part in parts) {
                    var result = doExpr(part);
                    if (result.hasValue) {
                        value += result.value;
                    } else {
                        hasValue = false;
                    }
                }
                return hasValue ? types.resultValue(types.specTypeString, value) : types.result(types.specTypeString);
            case Node.NStringSq(parts):
                return doExpr(parts);
            case Node.NCall(left, args):
                var value = doExpr(left);
                if (Std.is(value.type.type, FunctionHaxeType)) {
                    return cast(value.type.type, FunctionHaxeType).getReturn();
                }
                return types.resultAnyDynamic;
            case Node.NCast(expr, type):
                var evalue = doExpr(expr);
                var type2 = NodeTypeTools.getTypeDeclType(types, type);
                return types.result(type2);
            case Node.NArrayComprehension(iterator):
                var itResult = doExpr(iterator);
                return types.result(types.createArray(itResult.type));
            case Node.NFor(iteratorName, iteratorExpr, body):
                return doExpr(body);
            case Node.NWhile(condExpr, body) | Node.NDoWhile(body, condExpr):
                return doExpr(body);
            case Node.NNew(id, call):
                var type = NodeTypeTools.getTypeDeclType(types, id);
                return types.result(type);
            default:
                //trace('TypeBuilder: Unimplemented processExprValue $expr');
                errors.add(new ParserError(expr.pos, 'TypeBuilder: Unimplemented processExprValue $expr'));
                throw 'TypeBuilder: Unimplemented processExprValue $expr';
        }
        return ExpressionResult.withoutValue(types.specTypeDynamic);
    }
}
