package haxe.languageservices.sdk;

import haxe.languageservices.util.Vfs;
import haxe.languageservices.util.LocalVfs;

using StringTools;

class HaxeSdk {
    public var vfs(default, null):Vfs;
    private var path:String;

    public function new(vfs:Vfs, ?path:String) {
        this.vfs = vfs;
        if (path == null) path = detectPath();
        this.path = path;
    }
    
    static public function detectPath():String {
        return '/usr/lib/haxe';
    }
    
    public function getVersion():String {
        var match = ~/\d+\.\d+\.\d+/;
        var changes = vfs.readString('$path/CHANGES.txt').split('\n')[0];
        if (!match.match(changes)) throw "Can't detect haxe version: CHANGES.txt has invalid format";
        return match.matched(0);
    }
    
    public var libraries(get, null):Map<String, HaxeLibrary>;
    private var _libraries:Map<String, HaxeLibrary>;

    private function get_libraries():Map<String, HaxeLibrary> {
        if (_libraries == null) {
            _libraries = new Map<String, HaxeLibrary>();
            for (libpath in vfs.listFiles('$path/lib')) {
                var library = new HaxeLibrary(this, '$path/lib/$libpath');
                _libraries[library.name] = library;
            }
        }
        return _libraries;
    }

    public function getLibrary(name:String):HaxeLibrary {
        return new HaxeLibrary(this, '$path/lib/$name');
    }

    public function getLibraryVersion(qualifiedName:String):HaxeLibraryVersion {
        var parts = qualifiedName.split(':');
        var library = getLibrary(parts[0]);
        return if (parts.length >= 2) {
            library.getVersion(parts[1]);
        } else {
            library.currentVersion;
        }
    }
}
