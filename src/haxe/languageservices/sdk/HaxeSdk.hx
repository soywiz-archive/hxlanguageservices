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
    
    public var libraries(get, null):Map<String, HaxeLibrary>;
    private var _libraries:Map<String, HaxeLibrary>;

    private function get_libraries():Map<String, HaxeLibrary> {
        if (_libraries == null) {
            _libraries = new Map<String, HaxeLibrary>();
            for (libpath in FileSystem2.listFiles('$path/lib')) {
                var library = new HaxeLibrary(this, '$path/lib/$libpath');
                _libraries[library.name] = library;
            }
        }
        return _libraries;
    }

    public function getLibrary(name:String):HaxeLibrary {
        return new HaxeLibrary(this, '$path/lib/$name');
    }
}
