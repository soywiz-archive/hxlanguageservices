package haxe.languageservices.completion;

import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.type.HaxeType;

class CompletionEntryThis extends CompletionEntry {
    public function new(scope:CompletionScope, type:HaxeType) {
        super(scope, TextRange.createDummy(), null, null, 'this', type.types.createSpecific(type));

    }

    override public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(type2);
    }
}