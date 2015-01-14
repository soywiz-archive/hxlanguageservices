package haxe.languageservices.node;

class NodeTools {
    static public function getId(znode:ZNode):String {
        switch (znode.node) {
            case Node.NId(v): return v;
            case Node.NKeyword(v): return v;
            default: throw 'Invalid id';
        }
    }
}
