package haxe.languageservices.type;

import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class FunctionHaxeType extends HaxeType {
    public var args = new Array<FunctionArgument>();
    public var body:ZNode;
    public var retval:FunctionRetval = new FunctionRetval('Dynamic', '');

    public function new(types:HaxeTypes, pos:Position, name:String, args:Array<FunctionArgument>, retval:FunctionRetval) {
        super(types.rootPackage, pos, name);
        this.args = args;
        this.retval = retval;
    }

    override public function toString() return 'FunctionType(' + args.join(',') + '):' + retval;
}
