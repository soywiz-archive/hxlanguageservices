package haxe.languageservices.util;

class ProxyVfs extends Vfs {
    private var parent:Vfs;

    public function new(parent:Vfs) {
        this.parent = parent;
        super();
    }
    
    private function transformPath(path:String):String return path;

    override private function _exists(path:String):Bool return parent.exists(transformPath(path));
    override private function _listFiles(path:String):Array<String> return parent.listFiles(transformPath(path));
    override private function _readString(path:String):String return parent.readString(transformPath(path));
    override private function _exec(cmd:String, args:Array<String>):String return parent.exec(cmd, args);
}
