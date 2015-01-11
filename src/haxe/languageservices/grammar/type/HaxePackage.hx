package haxe.languageservices.grammar.type;

class HaxePackage {
    public var parent(default, null):HaxePackage;
    public var fqName(default, null):String;
    public var name(default, null):String;
    public var children = new Map<String, HaxePackage>();
    public var types = new Map<String, HaxeType>();

    public function new(name:String, ?parent:HaxePackage) {
        this.parent = parent;
        this.name = name;
        if (parent != null) {
            parent.children.set(name, this);
            this.fqName = (parent.fqName != '') ? parent.fqName + '.' + name : name;
        } else {
            this.fqName = name;
        }
    }
    
    public function getLeafs(?out:Array<HaxePackage>):Array<HaxePackage> {
        if (out == null) out = [];
        var count = 0;
        for (child in children) {
            count++;
            child.getLeafs(out);
        }
        if (count == 0) out.push(this);
        return out;
    }
    
    public function toString() {
        return 'Package("$name",${[for (child in children) child]})';
    }

    public function access(path:String, create:Bool):HaxePackage {
        return accessParts(path.split('.'), create);
    }

    public function accessType(path:String, create:Bool):HaxeType {
        var parts = path.split('.');
        var typeName = parts.pop();
        var packag = accessParts(parts, create);
        if (packag.types.exists(typeName)) return packag.types[typeName];
        if (create) return packag.types[typeName] = new HaxeType(packag, typeName);
        return null;
    }

    private function accessParts(parts:Array<String>, create:Bool):HaxePackage {
        var node = this;
        for (part in parts) {
            if (node.children.exists(part)) {
                node = node.children[part];
            } else {
                if (!create) return null;
                node = node.children[part] = new HaxePackage(part, node);
            }
        }
        return node;
    }
}
