package haxe.languageservices.type;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.Position;
import haxe.languageservices.node.ZNode;

class HaxeFile {
    public var path:String;
    public var text:String;
    public var programNode:ZNode; 

    public function new(path:String, text:String, programNode:ZNode) {
        this.path = path;
        this.text = text;
        this.programNode = programNode;
    }

    /*
    public function getIdentifierAt(index:Int):Position {
        var znode = programNode.locateIndex(index)
        if (znode != null) {
            switch (znode.node) {
                case Node.NId(_): return znode.pos;
                default:
            }
        }
        return null;
    }
    */
}
