package haxe.languageservices.grammar;
import haxe.languageservices.type.HaxeMember;
import haxe.languageservices.type.HaxeType;
import haxe.languageservices.type.HaxeMember.FieldHaxeMember;
import haxe.languageservices.type.HaxeType.ClassHaxeType;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.util.StringUtils;
import haxe.languageservices.grammar.Grammar.Result;
import haxe.languageservices.grammar.Position;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Node;

class HaxeTypeBuilder {
    public var errors = new Array<ParserError>();
    public var types:HaxeTypes;

    public function new(?types:HaxeTypes) {
        if (types == null) types = new HaxeTypes();
        this.types = types;
    }

    public function processResult(result:Result) {
        switch (result) {
            case Result.RMatchedValue(v): return process(cast(v));
            default: throw "Can't process";
        }
        return null;
    }
    
    private function error(pos:Position, text:String) {
        errors.push(new ParserError(pos, text));
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
    
    private function getId(znode:ZNode):String {
        switch (znode.node) {
            case Node.NId(v): return v;
            default: throw 'Invalid id';
        }
    }

    public function process(znode:ZNode) {
        switch (znode.node) {
            case Node.NFile(items):
                var index = 0;
                var typesCount = 0;
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
                        case Node.NImport(name):
                            if (typesCount > 0) error(item.pos, 'import should appear before any type decl');
                        case Node.NClass(name, typeParams, decls):
                            typesCount++;
                            var type = packag.accessTypeCreate(getId(name), ClassHaxeType);
                            processClass(type, decls);
                        case Node.NTypedef(name):
                            typesCount++;
                        case Node.NEnum(name):
                            typesCount++;
                        default:
                            error(item.pos, 'invalid node');
                    }
                    index++;
                }
            default:
                throw 'Expected haxe file';
        }
    }

    private function processClass(type:ClassHaxeType, decls:ZNode) {
        switch (decls.node) {
            case Node.NList(members):
                for (member in members) {
                    switch (member.node) {
                        case Node.NMember(modifiers, decl):
                            switch (decl.node) {
                                case Node.NVar(vname, vtype, vvalue):
                                    var field = new FieldHaxeMember(getId(vname));
                                    type.addMember(field);
                                default:
                                    trace(decl.node);
                            }
                        default: throw 'Invalid';
                    }
                }
            default:
                throw 'Invalid';
        }
    }
}
