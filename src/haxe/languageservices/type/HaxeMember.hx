package haxe.languageservices.type;

import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.ProcessNodeContext;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;

class HaxeMember implements HaxeCompilerElement {
    public var baseType:HaxeType;
    public var pos:TextRange;
    public var name(default, null):String;
    public var modifiers = new HaxeModifiers();
    public var doc:HaxeDoc;
    public var typeNode:ZNode;
    public var valueNode:ZNode;
    public var nameNode:ZNode;
    public var refs = new HaxeCompilerReferences();

    public function new(baseType:HaxeType, pos:TextRange, nameNode:ZNode) {
        this.baseType = baseType;
        this.pos = pos;
        this.nameNode = nameNode;
        this.name = NodeTools.getId(nameNode);
        refs.addNode(UsageType.Declaration, nameNode);
    }
    
    public function toString() return 'Member($name)';

    public function getType(?context:ProcessNodeContext):SpecificHaxeType {
        return baseType.types.specTypeDynamic;
    }

    public function getPosition():TextRange return this.pos;
    public function getNode():ZNode return valueNode;
    public function getName():String return name;
    public function getReferences():HaxeCompilerReferences return refs;
    public function getResult(?context:ProcessNodeContext):ExpressionResult {
        return ExpressionResult.withoutValue(getType(context));
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
