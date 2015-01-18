package haxe.languageservices.type.tool;

import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.node.Node;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.node.ZNode;

class NodeTypeTools {
    static public function getFunctionBodyReturnType(types:HaxeTypes, body:ZNode):SpecificHaxeType {
        throw 'Not implemented';
        return null;
    }

    static public function getTypeDeclType(types:HaxeTypes, typeDecl:ZNode):SpecificHaxeType {
        if (ZNode.isValid(typeDecl)) switch (typeDecl.node) {
            case Node.NList(items):
                if (items.length > 1) {
                    if (items[1] != null) throw 'Invalid2 $items';
                    if (items.length > 2) throw 'Invalid3 $items';
                }
                return getTypeDeclType(types, items[0]);
            case Node.NId(name):
                return types.createSpecific(types.getType(name));
            default: throw 'Invalid $typeDecl';
        }
        return types.specTypeDynamic;
    }

    static public function getExprResult(types:HaxeTypes, typeDecl:ZNode):ExpressionResult {
        throw 'Not implemented';
        return null;
    }
}
