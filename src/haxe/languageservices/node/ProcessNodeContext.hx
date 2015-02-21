package haxe.languageservices.node;

class ProcessNodeContext {
    public var nodes = new Map<ZNode, Bool>();

    public function new() { }

    public function isExplored(node:ZNode):Bool {
        if (node == null) return false;
        return nodes.exists(node);
    }

    public function recursionDetected() {

    }

    public function markExplored(node:ZNode) {
        if (node == null) return;
        nodes[node] = true;
    }
}