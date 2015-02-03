package haxe.languageservices.completion;

import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.ProcessNodeContext;

class CompletionEntryArrayElement extends CompletionEntry {
    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(scope.types.getArrayElement(super.getResult().type));
    }
}
