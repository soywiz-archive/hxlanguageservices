package haxe.languageservices.grammar;
import haxe.languageservices.type.HaxeModifiers;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.type.HaxeMember.FieldHaxeMember;
import haxe.languageservices.type.HaxeType.ClassHaxeType;
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
                                error(item.pos, 'package should be first element in the file');
                            } else {
                                var pathParts = checkPackage(name);
                                packag = types.rootPackage.access(pathParts.join('.'), true);
                            }
                        case Node.NImport(name) | Node.NUsing(name):
                            if (builtTypes.length > 0) error(item.pos, 'import should appear before any type decl');
                        case Node.NClass(name, typeParams, extendsImplementsList, decls):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) {
                                error(item.pos, 'type $typeName already exists');
                            }
                            var type:ClassHaxeType = packag.accessTypeCreate(typeName, item.pos, ClassHaxeType);
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
                            builtTypes.push(type);
                        case Node.NInterface(name, typeParams, extendsImplementsList, decls):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'type $typeName already exists');
                            var type:InterfaceHaxeType = packag.accessTypeCreate(typeName, item.pos, InterfaceHaxeType);
                            processClass(type, decls);
                            builtTypes.push(type);
                        case Node.NTypedef(name):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'type $typeName already exists');
                            var type:TypedefHaxeType = packag.accessTypeCreate(typeName, item.pos, TypedefHaxeType);
                            builtTypes.push(type);
                        case Node.NEnum(name):
                            var typeName = getId(name);
                            if (packag.accessType(typeName) != null) error(item.pos, 'type $typeName already exists');
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
                            if (ZNode.isValid(modifiers)) {
                                switch (modifiers.node) {
                                    case Node.NList(parts):
                                        for (part in parts) {
                                            if (ZNode.isValid(part)) {
                                                switch (part.node) {
                                                    case Node.NId(z): mods.add(z);
                                                    default: throw 'Invalid $part';
                                                }
                                            }
                                        }
                                    default: throw 'Invalid $modifiers';
                                }
                            }
                            if (ZNode.isValid(decl)) {
                                switch (decl.node) {
                                    case Node.NVar(vname, vtype, vvalue):
                                        var field = new FieldHaxeMember(member.pos, getId(vname));
                                        field.modifiers = mods;
                                        type.addMember(field);
                                    case Node.NFunction(vname, vexpr):
                                        var method = new MethodHaxeMember(member.pos, getId(vname));
                                        method.modifiers = mods;
                                        type.addMember(method);
                                    default:
                                        throw 'Invalid $decl';
                                }
                            }
                        default: throw 'Invalid $member';
                    }
                }
            default:
                throw 'Invalid $decls';
        }
    }
}
