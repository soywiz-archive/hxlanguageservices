package haxe.languageservices.util;

class AccessVfs extends ProxyVfs {
    private var accessPath:String;
    public function new(parent:Vfs, accessPath:String) {
        super(parent);
        this.accessPath = accessPath;
    }

    override private function transformPath(path:String):String {
        return '$accessPath/$path';
    }
}
