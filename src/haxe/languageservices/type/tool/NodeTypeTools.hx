package haxe.languageservices.type.tool;

import haxe.languageservices.grammar.ExpressionResult;
import haxe.languageservices.node.ZNode;

class NodeTypeTools {
    static public function getFunctionBodyReturnType(body:ZNode):SpecificHaxeType {
        throw 'Not implemented';
        return null;
    }

    static public function getTypeDeclType(typeDecl:ZNode):SpecificHaxeType {
        throw 'Not implemented';
        return null;
    }

    static public function getExprResult(typeDecl:ZNode):ExpressionResult {
        throw 'Not implemented';
        return null;
    }
}
