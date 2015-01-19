package haxe.languageservices.type;

import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class FunctionHaxeType extends HaxeType {
    public var optBaseType:HaxeType;
    public var args = new Array<FunctionArgument>();
    public var body:ZNode;
    //public var name:String;
    public var nameNode:ZNode;
    public var retval:FunctionRetval = new FunctionRetval('Dynamic', '');

    public function new(types:HaxeTypes, optBaseType:HaxeType, pos:Position, nameNode:ZNode, args:Array<FunctionArgument>, retval:FunctionRetval) {
        super(types.rootPackage, pos, nameNode.pos.text);
        this.optBaseType = optBaseType;
        this.args = args;
        this.name = nameNode.pos.text;
        this.nameNode = nameNode;
        this.retval = retval;
    }

    override public function toString() return 'FunctionType(' + args.join(',') + '):' + retval;
}
