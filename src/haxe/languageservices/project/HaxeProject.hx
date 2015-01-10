package haxe.languageservices.project;

class HaxeProject {
    private var baseDefines = [];

    public function new() { }

    public function setBaseDefines(base:Array<String>) {
        this.baseDefines = base;
    }

    public function getDefines():Array<String> { throw "Must Override"; return null; }
    public function getClassPaths():Array<String> { throw "Must Override"; return null; }
}
