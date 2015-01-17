package haxe.languageservices.util;

class LocalVfs extends Vfs {
    public function new() { super(); }

    override private function _readString(path:String):String {
        #if (neko || cpp || php)
            return sys.io.File.read(path, false).readAll(1024).toString();
        #elseif (js)
            return untyped require('fs').readFileSync(path, 'utf-8');
        #else
            throw "Not supported FileSystem2.readString";
        #end
    }

    override private function _exists(path:String):Bool {
        #if (neko || cpp || php)
            return sys.io.FileSystem.exists(path);
        #elseif (js)
            return untyped require('fs').existsSync(path);
        #else
            throw "Not supported FileSystem2.exists";
        #end
    }

    override private function _listFiles(path:String):Array<String> {
        #if (neko || cpp || php)
            return sys.FileSystem.readDirectory(path);
        #elseif (js)
            return untyped require('fs').readdirSync(path);
        #else
            throw "Not supported FileSystem2.listFiles";
        #end
    }

    override private function _exec(cmd:String, args:Array<String>):String {
        #if (neko || cpp)
        var process = new sys.io.Process(cmd, args);
        return process.stdout.readAll(1024).toString();
        #else
        throw "Not supported FileSystem2";
        #end
    }
}
