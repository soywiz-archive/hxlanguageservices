package haxe.languageservices.type;

import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Position;
import haxe.languageservices.node.ProcessNodeContext;

interface HaxeCompilerElement {
    function getPosition():Position;
    function getNode():ZNode;
    function getName():String;
    function getReferences():HaxeCompilerReferences;
    function getResult(?context:ProcessNodeContext):ExpressionResult;
    function toString():String;
}
