package haxe.languageservices.grammar;
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
import haxe.languageservices.type.HaxeMember.FieldHaxeMember;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.util.StringUtils;
import haxe.languageservices.grammar.Grammar.Result;
import haxe.languageservices.node.Position;
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

    public function processResult(result:Result) {
        switch (result) {
            case Result.RMatchedValue(v): return process(cast(v));
            default: throw "Can't process";
        }
        return null;
    }
    
    private function error(pos:Position, text:String) {
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
                var index = 0;
                var packag = types.rootPackage;
                for (item in items) {
                    switch (item.node) {
                        case Node.NPackage(name):
                            if (index != 0) {
                                error(item.pos, 'Package should be first element in the file');
                            } else {
                                var pathParts = checkPackage(name);
                                packag = types.rootPackage.access(pathParts.join('.'), true);
                            }
                        case Node.NImport(name) | Node.NUsing(name):
                            if (builtTypes.length > 0) error(item.pos, 'Import should appear before any type decl');
                        case Node.NClass(name, typeParams, extendsImplementsList, decls):
                            var typeName = getId(name);

                            checkClassName(name.pos, typeName);
                            
                            if (packag.accessType(typeName) != null) {
                                error(item.pos, 'Type name $typeName is already defined in this module');
                            }
                            var type:ClassHaxeType = packag.accessTypeCreate(typeName, item.pos, ClassHaxeType);
                            builtTypes.push(type);
                            if (ZNode.isValid(extendsImplementsList)) {
                                switch (extendsImplementsList.node) {
                                    case Node.NList(items):
                                        for (item in items) {
                                            switch (item.node) {
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
                                            }
                                        }
                                    default: throw 'Invalid';
                                }
                            }

                            //trace(extendsImplementsList);
                            type.node = item;
                            processClass(type, decls);
                        case Node.NInterface(name, typeParams, extendsImplementsList, decls):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                            var type:InterfaceHaxeType = packag.accessTypeCreate(typeName, item.pos, InterfaceHaxeType);
                            builtTypes.push(type);
                            processClass(type, decls);
                        case Node.NTypedef(name):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                            var type:TypedefHaxeType = packag.accessTypeCreate(typeName, item.pos, TypedefHaxeType);
                            builtTypes.push(type);
                        case Node.NAbstract(name):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                            var type:AbstractHaxeType = packag.accessTypeCreate(typeName, item.pos, AbstractHaxeType);
                            builtTypes.push(type);
                        case Node.NEnum(name):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'Type name $typeName is already defined in this module');
                            var type:EnumHaxeType = packag.accessTypeCreate(typeName, item.pos, EnumHaxeType);
                            builtTypes.push(type);
                        default:
                            error(item.pos, 'invalid node');
                    }
                    index++;
                }
            default:
                throw 'Expected haxe file';
        }
        return builtTypes;
    }

    private function processClass(type:HaxeType, decls:ZNode) {
        switch (decls.node) {
            case Node.NList(members):
                for (member in members) {
                    switch (member.node) {
                        case Node.NMember(modifiers, decl):
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
                            if (ZNode.isValid(decl)) switch (decl.node) {
                                case Node.NVar(vname, propInfo, vtype, vvalue):
                                    checkType(vtype);
                                    var field = new FieldHaxeMember(type, member.pos, vname);
                                    field.modifiers = mods;
                                    if (type.existsMember(field.name)) {
                                        error(vname.pos, 'Duplicate class field declaration : ${field.name}');
                                    }
                                    type.addMember(field);
                                case Node.NFunction(vname, vargs, vret, vexpr):
                                    checkFunctionDeclArgs(vargs);
                                    checkType(vret);

                                    var ffargs = [];
                                    if (ZNode.isValid(vargs)) switch (vargs.node) {
                                        //case null:
                                        case Node.NList(_vargs): for (arg in _vargs) {
                                            if (ZNode.isValid(arg)) switch (arg.node) {
                                                case Node.NFunctionArg(opt, name, type, value):
                                                    ffargs.push(new FunctionArgument(NodeTools.getId(name), NodeTypeTools.getTypeDeclType(types, type).type.fqName));
                                                default:
                                                    throw 'Invalid (VII) $arg';
                                            }
                                            //checkFunctionDeclArgs(item);
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

                                    var method = new MethodHaxeMember(new FunctionHaxeType(types, member.pos, vname, ffargs, fretval));
                                    method.modifiers = mods;
                                    if (type.existsMember(method.name)) {
                                        error(vname.pos, 'Duplicate class field declaration : ${method.name}');
                                    }
                                    type.addMember(method);
                                    processMethodBody(type, method, vexpr);
                                default:
                                    throw 'Invalid (III) $decl';
                            }
                        default: throw 'Invalid (IV) $member';
                    }
                }
            default:
                throw 'Invalid (V) $decls';
        }
    }
    
    private function checkFunctionDeclArgs(znode:ZNode):Void {
        if (!ZNode.isValid(znode)) return;
        switch (znode.node) {
            case Node.NList(items): for (item in items) checkFunctionDeclArgs(item);
            case Node.NFunctionArg(opt, id, type, value): checkType(type);
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
    
    private function checkClassName(pos:Position, typeName:String):Void {
        if (!StringUtils.isFirstUpper(typeName)) {
            error(pos, 'Type name should start with an uppercase letter');
        }
    }

    private function processMethodBody(type:HaxeType, method:MethodHaxeMember, expr:ZNode) {
        if (!ZNode.isValid(expr)) return;
        switch (expr.node) {
            case Node.NBlock(items) | Node.NList(items): for (item in items) processMethodBody(type, method, item);
            case Node.NVar(vname, propertyInfo, vtype, vvalue):
                checkType(vtype);
                processMethodBody(type, method, vvalue);
            default:
                //errors.add(new ParserError(expr.pos, 'TypeBuilder: Unimplemented body $expr'));
        }
    }
}
