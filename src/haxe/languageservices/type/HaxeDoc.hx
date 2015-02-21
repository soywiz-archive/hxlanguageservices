package haxe.languageservices.type;

import haxe.languageservices.util.StringUtils;
using StringTools;
using haxe.languageservices.util.StringUtils;

class HaxeDoc {
    public var text:String;
    public var heading(default, null):String;
    public var params(default, null):Array<HaxeDocParam>;

    public function new(text:String) {
        this.text = text;
        var lines = text.split('\n').map(function(v:String) {
            return v.trim().removeStart('*').trim();
        });
        params = [];
        for (line in lines) {
            if (line.length == 0) continue;
            
            if (heading == null) {
                heading = line;
            } else {
                if (line.startsWith('@param')) {
                    var paramInfo = line.removeStart('@param').trim();
                    var reg = ~/^(\w+)(\s+(.*))?$/;
                    var name = '?';
                    var doc = '?';
                    if (reg.match(paramInfo)) {
                        name = reg.matched(1).trim();
                        doc = reg.matched(2).trim();
                    }
                    params.push(new HaxeDocParam(params.length, name, doc));
                    //trace(line);
                }
            }
        }
        //trace(lines);
    }
    
    public function getParam(index:Int):HaxeDocParam {
        return (index >= 0 && index < params.length) ? params[index] : nullParam;
    }

    public function getParamByName(name:String):HaxeDocParam {
        for (param in params) if (param.name == name) return param;
        return nullParam;
    }
    
    static private var nullParam = new HaxeDocParam(0, '', '');

    public function toString() { return text; }
}
