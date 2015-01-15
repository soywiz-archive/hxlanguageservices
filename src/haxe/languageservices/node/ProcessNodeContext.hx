package haxe.languageservices.node;

class ProcessNodeContext {
    public var nodes = new Map<ZNode, Bool>();

    public function new() { }

    public function isExplored(node:ZNode):Bool {
        return nodes.exists(node);
    }

    public function recursionDetected() {

    }

    public function markExplored(node:ZNode) {
        nodes[node] = true;
    }
}