package haxe.languageservices.sdk;
import haxe.languageservices.util.PathUtils;
import haxe.languageservices.util.Vfs;
import haxe.languageservices.sdk.HaxeLibraryVersion;
import haxe.languageservices.util.LocalVfs;

class HaxeLibraryVersion {
    public var exists(get, never):Bool;
    public var name(default, null):String;
    public var version(default, null):String;
    public var path(default, null):String;
    public var library(default, null):HaxeLibrary;
    public var info(get, never):Dynamic;
    public var license(get, never):String;
    public var classPath(get, never):String;
    public var tags(get, never):Array<String>;
    public var contributors(get, never):Array<String>;
    public var releasenote(get, never):String;
    public var description(get, never):String;
    public var dependencies(get, never):Array<HaxeLibraryVersion>;
    public var url(get, never):String;

    public function new(library:HaxeLibrary, version:String, path:String) {
        this.library = library;
        this.name = library.name;
        this.version = version;
        this.path = path;
        
    }
    
    private inline function getVfs():Vfs return library.sdk.vfs;
    
    private function get_exists() return getVfs().exists(path);

    private var _info:Dynamic;
    private function get_info() {
        if (_info == null) _info = Json.parse(getVfs().readString('$path/haxelib.json'));
        return _info;
    }
    private function get_license() return this.info.license;
    private function get_classPath() return this.info.classPath;
    private function get_description() return this.info.description;
    private function get_tags() return this.info.tags;
    private function get_contributors() return this.info.contributors;
    private function get_releasenote() return this.info.releasenote;
    private function get_url() return this.info.url;
    private function get_dependencies() {
        var deps = this.info.dependencies;
        var out:Array<HaxeLibraryVersion> = [];
        for (key in Reflect.fields(deps)) {
            var value = Reflect.field(deps, key);
            out.push(library.sdk.getLibrary(key).getVersion(value));
        }
        return out;
    }
    
    public function getFullClassPath() return PathUtils.combine(path, classPath);

    public function toString() return 'HaxeLibraryVersion($name:$version)';
}
