package haxe.languageservices.grammar;
import haxe.languageservices.type.HaxeThisElement;
import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.completion.CompletionEntryThis;
import haxe.languageservices.node.Const;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.ConstTools;
import haxe.languageservices.type.UsageType;
import haxe.languageservices.type.HaxeLocalVariable;
import haxe.languageservices.completion.TypeMembersCompletionProvider;
import haxe.languageservices.completion.LocalScope;
import haxe.languageservices.completion.CompletionScope;
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
import haxe.languageservices.type.FunctionRetval;
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
            case Node.NIdList(nidList):
                for (nid in nidList) {
                    switch (nid.node) {
                        case Node.NId(c):
                            if (!StringUtils.isLowerCase(c)) {
                                error(nidList2.pos, 'package should be lowercase');
                            }
                            parts.push(c);
                        default: throw 'Invalid';
                    }
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
                            var scope = new LocalScope(TypeMembersCompletionProvider.forType(type, !member.modifiers.isStatic, true));
                            scope.add(new HaxeThisElement(type));
                            _processMethodBody(method.func.body, scope, method.func);
                        }
                    }
                }
            default:
                throw 'Expected haxe file';
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

//trace(extendsImplementsList);
                type.node = item;
                processClass(type, decls);
            case Node.NInterface(name, typeParams, extendsImplementsList, decls):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:InterfaceHaxeType = info.packag.accessTypeCreate(typeName, item.pos, InterfaceHaxeType);
                builtTypes.push(type);
                processClass(type, decls);
            case Node.NTypedef(name):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:TypedefHaxeType = info.packag.accessTypeCreate(typeName, item.pos, TypedefHaxeType);
                builtTypes.push(type);
            case Node.NAbstract(name):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:AbstractHaxeType = info.packag.accessTypeCreate(typeName, item.pos, AbstractHaxeType);
                builtTypes.push(type);
            case Node.NEnum(name):
                var typeName = getId(name);
                if (info.packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                var type:EnumHaxeType = info.packag.accessTypeCreate(typeName, item.pos, EnumHaxeType);
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
                if (type.existsMember(field.name)) {
                    error(vname.pos, 'Duplicate class field declaration : ${field.name}');
                }
                type.addMember(field);
            case Node.NFunction(vname, vtypeParams, vargs, vret, vexpr, doc):
                checkFunctionDeclArgs(vargs);
                checkType(vret);

                var ffargs = [];
                if (ZNode.isValid(vargs)) switch (vargs.node) {
                    case Node.NList(_vargs): for (arg in _vargs) {
                        if (ZNode.isValid(arg)) switch (arg.node) {
                            case Node.NFunctionArg(opt, name, type, value, doc):
                                ffargs.push(new FunctionArgument(ffargs.length, NodeTools.getId(name), NodeTypeTools.getTypeDeclType(types, type).type.fqName));
                            default:
                                throw 'Invalid (VII) $arg';
                        }
                    }
                    default: throw 'Invalid (VI) $vargs';
                }

                var fretval:FunctionRetval;
                if (vret != null) {
//fretval = new FunctionRetval(NodeTypeTools.getTypeDeclType(types, vret).type.fqName, '');
                    fretval = new FunctionRetval(vret.pos.text.trim(), '');
                } else {
                    fretval = new FunctionRetval('Dynamic');
                }

                var method = new MethodHaxeMember(new FunctionHaxeType(types, type, member.pos, vname, ffargs, fretval, vexpr));
                method.doc = new HaxeDoc(NodeTools.getId(doc));
                method.modifiers = mods;
                if (type.existsMember(method.name)) {
                    error(vname.pos, 'Duplicate class field declaration : ${method.name}');
                }
                type.addMember(method);
            default:
                throw 'Invalid (III) $decl';
        }
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
                //processMethodBody(left, scope);
                if (args != null) {
                    //switch (args) {
                    //}
                }
            case Node.NIf(cond, trueExpr, falseExpr):
                _processMethodBody(cond, scope, func);
                _processMethodBody(trueExpr, scope, func);
                _processMethodBody(falseExpr, scope, func);
            case Node.NFieldAccess(left, id):
                _processMethodBody(left, scope, func);
                var expr2 = _processExprValue(left, scope, func);
                //expr2.type.type.membersByName
                //trace(expr2);
                //trace(left);
            case Node.NReturn(expr):
                if (func != null) func.returns.push(_processExprValue(expr, scope, func));
            default:
                //trace('TypeBuilder: Unimplemented body $expr');
                //if (debug) errors.add(new ParserError(expr.pos, 'TypeBuilder: Unimplemented body $expr'));
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
                        trace('TypeBuilder: Unimplemented body $expr');
                }
            case Node.NUnary(op, value):
                return _processExprValue(value, scope, func);
            case Node.NConst(Const.CInt(value)): return ExpressionResult.withValue(types.specTypeInt, value);
            case Node.NConst(Const.CFloat(value)): return ExpressionResult.withValue(types.specTypeFloat, value);
            case Node.NConst(Const.CString(value)): return ExpressionResult.withValue(types.specTypeString, value);
            case Node.NFieldAccess(left, id):
                var expr2 = _processExprValue(left, scope, func);
                return ExpressionResult.withoutValue(expr2.type.access(NodeTools.getId(id)));
            // @TODO: CompletionScope
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
                //throw 'Test';
        }
        return ExpressionResult.withoutValue(types.specTypeDynamic);
    }
}
