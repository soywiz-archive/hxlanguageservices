package haxe.languageservices.util;

class MemoryVfs extends Vfs {
    private var root = new MemoryNode('');

    public function new() { super(); }

    override private function _exists(path:String):Bool return root.access(path) != null;
    override private function _listFiles(path:String):Array<String> return root.access(path).filenames();
    override private function _readString(path:String):String return root.access(path).content;

    public function set(path:String, content:String) {
        root.access(path, true).content = content;
        return this;
    }
}

class MemoryNode {
    public var name:String;
    public var children = new Map<String, MemoryNode>();
    public var content = ""; 
    
    public function new(name:String) {
        this.name = name;
    }
    
    public function filenames() return [for (child in children) child.name];

    public function access(path:String, create:Bool = false):MemoryNode {
        var parts = path.split('/');
        var current = this;
        for (part in parts) {
            if (current.children[part] == null) {
                if (create) {
                    current = current.children[part] = new MemoryNode(part);
                } else {
                    return null;
                }
            } else {
                current = current.children[part];
            }
        }
        return current;
    }
}
