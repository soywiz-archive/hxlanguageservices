package haxe.languageservices.node;

import haxe.languageservices.node.ZNode;
import haxe.languageservices.util.Grammar.NNode;

enum Node {
    NId(value:String);
    NKeyword(value:String);
    NOp(value:String);
    NDoc(value:String);
    NConst(value:Dynamic);
    NList(value:Array<ZNode>);
    NListDummy(value:Array<ZNode>);
    NIdList(value:Array<ZNode>);
    NConstList(items:Array<ZNode>);

    NCast(expr:ZNode, ?type:ZNode);
    NIf(cond:ZNode, trueExpr:ZNode, falseExpr:ZNode);
    NArrayComprehension(iterator:ZNode);
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
    NAbstract(name:ZNode);

    NExtends(fqName:ZNode, params:ZNode);
    NImplements(fqName:ZNode, params:ZNode);

    NWrapper(node:ZNode);
    NProperty(a:ZNode, b:ZNode);
    NVar(name:ZNode, propertyInfo:ZNode, type:ZNode, value:ZNode, doc:ZNode);
    NFunctionArg(opt:ZNode, name:ZNode, type:ZNode, value:ZNode, doc:ZNode);
    NFunction(name:ZNode, typeParams:ZNode, args:ZNode, ret:ZNode, expr:ZNode, doc:ZNode);
    NContinue();
    NBreak();
    NReturn(?expr:ZNode);

    NArrayAccessPart(node:ZNode);
    NFieldAccessPart(node:ZNode);
    NCallPart(node:ZNode);
    NBinOpPart(op:ZNode, expr:ZNode);

    NStringParts(parts:Array<ZNode>);
    NStringSqDollarPart(expr:ZNode);
    NStringSq(parts:ZNode);

    NArrayAccess(left:ZNode, index:ZNode);
    NFieldAccess(left:ZNode, id:ZNode);
    NCall(left:ZNode, args:ZNode);
    NBinOp(left:ZNode, op:String, right:ZNode);
    
    NAccessList(node:ZNode, accessors:ZNode);
    NMember(modifiers:ZNode, decl:ZNode);
    NNew(id:ZNode, call:ZNode);
    NUnary(op:ZNode, value:ZNode);
    NIdWithType(id:ZNode, type:ZNode);
    NTypeParams(items:Array<ZNode>);
    NFile(decls:Array<ZNode>);
}

