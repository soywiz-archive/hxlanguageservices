package haxe.languageservices.type;

import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.completion.CompletionProvider;
class MethodHaxeMember extends HaxeMember {
    public var func:FunctionHaxeType;
    public var scope:CompletionProvider;
    public function new(func:FunctionHaxeType) {
        super(func, func.pos, func.nameNode);
        this.func = func;
    }
    override public function toString() return 'Method($name)';
    override public function getType(?context:ProcessNodeContext):SpecificHaxeType {
        return func.types.createSpecific(func);
    }
}
