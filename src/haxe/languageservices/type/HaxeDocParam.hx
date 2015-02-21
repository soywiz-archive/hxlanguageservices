package haxe.languageservices.type;

import haxe.languageservices.util.StringUtils;
class HaxeDocParam {
    public var index:Int;
    public var name:String;
    public var desc:String;
    
    public function new(index:Int, name:String, desc:String) {
        this.index = index;
        this.name = name;
        this.desc = desc;
    }
    
    public function nameAndDesc() {
        if (StringUtils.empty(name) && StringUtils.empty(desc)) return '';
        return '$name: $desc';
    }

    public function toString() return 'Doc($index,$name:$desc)';
}
