package haxe.languageservices.node;

import haxe.languageservices.grammar.GrammarNode;
import haxe.languageservices.util.IndentWriter;
class NodeTools {
    static public function getId(znode:ZNode):String {
        if (znode == null) return null;
        switch (znode.node) {
            case Node.NId(v): return v;
            case Node.NKeyword(v): return v;
            case Node.NOp(v): return v;
            case Node.NDoc(v): return v;
            default: throw 'Invalid id: $znode';
        }
    }

    static public function dump(znode:ZNode, ?iw:IndentWriter):IndentWriter {
        if (iw == null) iw = new IndentWriter();
        _dump(znode, iw);
        return iw;
    }

    static private function _dump(item:Dynamic, iw:IndentWriter):Void {
        if (Std.is(item, GrammarNode)) {
            //trace('[1]');
            _dump(Std.instance(item, GrammarNode).node, iw);
        } else if (Std.is(item, Node)) {
            //trace('[2]');
            iw.write(item + '{\n');
            iw.indent(function() {
                for (i in Type.enumParameters(item)) {
                    _dump(i, iw);
                    //iw.write('\n');
                }
            });
            iw.write('\n}\n');
        } else {
            iw.write('' + item);
        }
        //trace(item);
    }

    /*
    static public function getType(znode:ZNode):String {
        switch (znode.node) {
            case Node.NId(v): return v;
            case Node.NKeyword(v): return v;
            default: throw 'Invalid id';
        }
    }
    */
}
