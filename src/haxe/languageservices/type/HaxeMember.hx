package haxe.languageservices.type;

import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class HaxeMember implements HaxeCompilerElement {
    public var baseType:HaxeType;
    public var pos:Position;
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var doc:String = '';
    public var typeNode:ZNode;
    public var valueNode:ZNode;
    public var nameNode:ZNode;
    public var refs = new HaxeCompilerReferences();

    public function new(baseType:HaxeType, pos:Position, nameNode:ZNode) {
        this.baseType = baseType;
        this.pos = pos;
        this.nameNode = nameNode;
        this.name = NodeTools.getId(nameNode);
        refs.addNode(UsageType.Declaration, nameNode);
    }
    
    public function toString() return 'Member($name)';

    public function getType():SpecificHaxeType return baseType.types.specTypeDynamic;

    public function getPosition():Position return this.pos;
    public function getNode():ZNode return valueNode;
    public function getName():String return name;
    public function getReferences():HaxeCompilerReferences return refs;
    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(getType());
    }

    static public function staticIsStatic(member:HaxeMember):Bool {
        if (member == null) return false;
        return member.modifiers.isStatic;
    }

    static public function staticIsNotStatic(member:HaxeMember):Bool {
        if (member == null) return false;
        return !member.modifiers.isStatic;
    }
}

class MethodHaxeMember extends HaxeMember {
    private var type:FunctionHaxeType;
    public function new(type:FunctionHaxeType) {
        super(type, type.pos, type.nameNode);
        this.type = type;
    }
    override public function toString() return 'Method($name)';
    override public function getType():SpecificHaxeType {
        return type.types.createSpecific(type);
    }
}

class FieldHaxeMember extends HaxeMember {
    override public function toString() return 'Field($name)';
}
