package haxe.languageservices.sdk;

import haxe.languageservices.util.FileSystem2;

using StringTools;

//2014-04-13: 3.1.3

class HaxeSdk {
    private var path:String;

    public function new(?path:String) {
        if (path == null) path = detectPath();
        this.path = path;
    }
    
    static public function detectPath():String {
        return '/usr/lib/haxe';
    }
    
    public function getVersion():String {
        var match = ~/\d+\.\d+\.\d+/;
        var changes = FileSystem2.readString('$path/CHANGES.txt').split('\n')[0];
        if (!match.match(changes)) throw "Can't detect version";
        return match.matched(0);
    }

    public function getLibraries():Map<String, HaxeLibrary> {
        var out = new Map<String, HaxeLibrary>();
        for (libpath in FileSystem2.listFiles('$path/lib')) {
            var library = new HaxeLibrary('$path/lib/$libpath');
            out[library.name] = library;
        }
        return out;
    }
}
