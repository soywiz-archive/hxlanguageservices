package haxe.languageservices.project;

import haxe.languageservices.util.ArrayUtils;
import haxe.languageservices.util.PathUtils;
import haxe.io.Path;
import haxe.languageservices.sdk.HaxeSdk;

// http://www.openfl.org/documentation/command-line-tools/project-files/xml-format/
class LimeXmlHaxeProject extends HaxeProject {
    public var path(default, null):String;
    public var basePath(default, null):String;
    public var sdk(default, null):HaxeSdk;
    public var xml(get, null):Xml;

    public function new(sdk:HaxeSdk, path:String) {
        super();
        this.sdk = sdk;
        this.path = path;
        this.basePath = Path.directory(path);
    }
    
    private var _xml:Xml;
    
    private function get_xml():Xml {
        if (_xml == null) _xml = Xml.parse(sdk.vfs.readString(path));
        return _xml;
    }
    

    override public function getDefines():Array<String> {
        function containsDefine(out:Array<String>, def:String):Bool {
            return out.indexOf(def) >= 0;
        }

        var out = baseDefines.slice(0, baseDefines.length);
        
        function parseXml(xml:Xml) {
            for (_element in xml.firstElement().elements()) {
                var element:Xml = _element;
                switch (element.nodeName) {
                    case 'set':
                        var set:Xml = _element;
                        if (set.exists('if') && !containsDefine(out, set.get('if'))) continue;
                        if (set.exists('unless') && containsDefine(out, set.get('unless'))) continue;

                        out.push(set.get('name'));
                    case 'include':
                        parseXml(Xml.parse(sdk.vfs.readString(PathUtils.combine(this.basePath, element.get('path')))));
                    default:
                }
            }
        }
        
        parseXml(this.xml);
        return ArrayUtils.uniqueSorted(out);
    }

    override public function getClassPaths():Array<String> {
        //trace('aaaa:' + xml);
        var out:Array<String> = [];
        for (source in xml.firstElement().elementsNamed('source')) {
            out.push(PathUtils.combine(this.basePath, source.get('path')));
        }
        for (haxelib in xml.firstElement().elementsNamed('haxelib')) {
            out.push(sdk.getLibraryVersion(haxelib.get('name') + ':' + haxelib.get('version')).getFullClassPath());
        }
        return out;
    }
}
