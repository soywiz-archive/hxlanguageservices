package haxe.languageservices.type;

import haxe.languageservices.node.Position;
class HaxePackage {
    public var base:HaxeTypes;
    public var root(default, null):HaxePackage;
    public var parent(default, null):HaxePackage;
    public var fqName(default, null):String;
    public var name(default, null):String;
    public var children = new Map<String, HaxePackage>();
    public var types = new Map<String, HaxeType>();

    public function new(base:HaxeTypes, name:String, ?parent:HaxePackage) {
        this.base = base;
        this.parent = parent;
        this.name = name;
        if (parent != null) {
            parent.children.set(name, this);
            this.fqName = (parent.fqName != '') ? parent.fqName + '.' + name : name;
            this.root = parent.root;
        } else {
            this.fqName = name;
            this.root = this;
        }
    }
    
    public function isLeaf():Bool {
        for (child in children) return false;
        return true;
    }

    public function getAllTypes():Array<HaxeType> {
        return [for (p in getAll()) for (t in p.types) t];
    }

    public function getLeafs():Array<HaxePackage> {
        return getAll().filter(function(p:HaxePackage) return p.isLeaf());
    }

    public function getAll(?out:Array<HaxePackage>):Array<HaxePackage> {
        if (out == null) out = [];
        out.push(this);
        for (child in children) child.getAll(out);
        return out;
    }

    public function toString() {
        return 'Package("$name",${[for (child in children) child]})';
    }

    public function access(path:String, create:Bool):HaxePackage {
        if (path == null) return null;
        return accessParts(path.split('.'), create);
    }

    public function accessType(path:String):HaxeType {
        return _accessType(path, false, null, null);
    }

    public function accessTypeCreate<T:HaxeType>(path:String, pos:Position, type:Class<HaxeType>):T {
        return cast _accessType(path, true, pos, type);
    }

    private function _accessType(path:String, create:Bool, pos:Position, type:Class<HaxeType>):HaxeType {
        if (path == null) return null;
        var parts = path.split('.');
        var typeName = parts.pop();
        var packag = accessParts(parts, create);
        var exists = packag.types.exists(typeName);
        if (exists && create) {
            trace('type "$path" already exists, recreating');
        }
        if (create) return packag.types[typeName] = Type.createInstance(type, [packag, pos, typeName]);
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
                node = node.children[part] = new HaxePackage(base, part, node);
            }
        }
        return node;
    }
}
