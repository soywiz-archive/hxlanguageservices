package haxe.languageservices.sdk;
import haxe.languageservices.util.FileSystem2;
class HaxeLibraryVersion {
    private var name:String;
    private var version:String;
    private var path:String;
    
    private var _info:Dynamic;
    public var info(get, never):Dynamic;
    public var license(get, never):String;
    public var classPath(get, never):String;
    public var tags(get, never):Array<String>;
    public var contributors(get, never):Array<String>;
    public var releasenote(get, never):String;
    public var description(get, never):String;
    public var url(get, never):String;

    public function new(name:String, version:String, path:String) {
        this.name = name;
        this.version = version;
        this.path = path;
    }
    
    private function get_info() {
        if (_info == null) _info = Json.parse(FileSystem2.readString('$path/haxelib.json'));
        return _info;
    }
    private function get_license() return this.info.license;
    private function get_classPath() return this.info.classPath;
    private function get_description() return this.info.description;
    private function get_tags() return this.info.tags;
    private function get_contributors() return this.info.contributors;
    private function get_releasenote() return this.info.releasenote;
    private function get_url() return this.info.url;

    public function toString() return 'HaxeLibraryVersion($name:$version)';
}
