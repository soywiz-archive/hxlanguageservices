package haxe.languageservices.completion;

import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.ProcessNodeContext;
class CompletionEntryFunctionElement extends CompletionEntry {
    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        //return ExpressionResult.withoutValue(new SpecificHaxeType(scope.types, new FunctionHaxeType(scope.types.rootPackage, pos, name)));
        //return ExpressionResult.withoutValue(scope.types.specTypeDynamic);
        return ExpressionResult.withoutValue(type2);
    }
}