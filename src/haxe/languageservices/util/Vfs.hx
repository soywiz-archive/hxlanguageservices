package haxe.languageservices.util;

using StringTools;

class Vfs {
    public function new() { }

    private function _exists(path:String):Bool { throw "Not implemented"; return false; }
    private function _listFiles(path:String):Array<String> { throw "Not implemented"; return null; }
    private function _readString(path:String):String { throw "Not implemented"; return null; }
    private function _exec(cmd:String, args:Array<String>):String { throw "Not implemented"; return null; }
    
    private function normalizePath(path:String):String {
        return PathUtils.combine(path, '.');
    }

    @:final public function exists(path:String):Bool return _exists(normalizePath(path));
    @:final public function listFiles(path:String):Array<String> return _listFiles(normalizePath(path));
    @:final public function readString(path:String):String return _readString(normalizePath(path));
    @:final public function exec(cmd:String, args:Array<String>):String return _exec(cmd, args);
    @:final public function access(path:String):AccessVfs {
        return new AccessVfs(this, normalizePath(path));
    }
}
