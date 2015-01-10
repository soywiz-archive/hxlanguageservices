package haxe.languageservices.sdk;

import haxe.languageservices.util.FileSystem2;

using StringTools;

class HaxeLibrary {
    public var name:String;
    public var versions = new Map<String, HaxeLibraryVersion>();
    public var currentVersion:HaxeLibraryVersion;

    public function new(path:String) {
        var nameMatch = ~/\/?(\w+)$/;
        nameMatch.match(path);
        this.name = nameMatch.matched(1);
        for (version in FileSystem2.listFiles(path)) {
            if (version.charAt(0) == '.') continue;
            var versionNormalized = normalizeVersion(version);
            this.versions[versionNormalized] = currentVersion = new HaxeLibraryVersion(name, versionNormalized, '$path/$version');
        }
        var currentVersionString = FileSystem2.readString('$path/.current');
        var expectedCurrentVersion = versions[normalizeVersion(currentVersionString)];
        currentVersion = (expectedCurrentVersion != null) ? expectedCurrentVersion : currentVersion;
    }
    
    static private function normalizeVersion(version:String) return version.replace(',', '.');

    public function toString() return 'HaxeLibrary($name)';
}
