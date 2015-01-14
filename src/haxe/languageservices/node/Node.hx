package haxe.languageservices.node;

import haxe.languageservices.grammar.Grammar.NNode;

enum Node {
    NId(value:String);
    NKeyword(value:String);
    NOp(value:String);
    NConst(value:Dynamic);
    NList(value:Array<ZNode>);
    NListDummy(value:Array<ZNode>);
    NIdList(value:Array<ZNode>);
    NConstList(items:Array<ZNode>);
    
    
    NIf(cond:ZNode, trueExpr:ZNode, falseExpr:ZNode);
    NArray(items:Array<ZNode>);
    NObjectItem(key:ZNode, value:ZNode);
    NObject(items:Array<ZNode>);
    NBlock(items:Array<ZNode>);
    NFor(iteratorName:ZNode, iteratorExpr:ZNode, body:ZNode);
    NWhile(cond:ZNode, body:ZNode);
    NDoWhile(body:ZNode, cond:ZNode);
    NSwitch(subject:ZNode, cases:ZNode);

    NCase(item:ZNode);
    NDefault();

    NPackage(fqName:ZNode);
    NImport(fqName:ZNode);
    NUsing(fqName:ZNode);

    NClass(name:ZNode, typeParams:ZNode, extendsImplementsList:ZNode, decls:ZNode);
    NInterface(name:ZNode, typeParams:ZNode, extendsImplementsList:ZNode, decls:ZNode);
    NTypedef(name:ZNode);
    NEnum(name:ZNode);

    NExtends(fqName:ZNode, params:ZNode);
    NImplements(fqName:ZNode, params:ZNode);

    NVar(name:ZNode, type:ZNode, value:ZNode);
    NFunction(name:ZNode, expr:ZNode);
    NContinue();
    NBreak();
    NReturn(?expr:ZNode);
    NAccess(node:ZNode);
    NCall(node:ZNode);
    NAccessList(node:ZNode, accessors:ZNode);
    NMember(modifiers:ZNode, decl:ZNode);
    NNew(id:ZNode, call:ZNode);
    NUnary(op:ZNode, value:ZNode);
    NIdWithType(id:ZNode, type:ZNode);
    NTypeParams(items:Array<ZNode>);
    NBinOpPart(op:ZNode, expr:ZNode);
    NFile(decls:Array<ZNode>);
}

