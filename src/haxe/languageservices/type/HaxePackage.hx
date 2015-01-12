package haxe.languageservices.type;

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

    public function accessType(path:String):HaxeType {
        return _accessType(path, false, null);
    }

    public function accessTypeCreate<T:HaxeType>(path:String, type:Class<HaxeType>):T {
        return cast _accessType(path, true, type);
    }

    private function _accessType(path:String, create:Bool, type:Class<HaxeType>):HaxeType {
        var parts = path.split('.');
        var typeName = parts.pop();
        var packag = accessParts(parts, create);
        var exists = packag.types.exists(typeName);
        if (exists && create) {
            trace('type already exists, recreating');
        }
        if (create) return packag.types[typeName] = Type.createInstance(type, [packag, typeName]);
        if (exists) return packag.types[typeName];
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
