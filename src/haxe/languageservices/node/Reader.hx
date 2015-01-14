package haxe.languageservices.node;

class Reader {
    public var str(default, null):String;
    public var file(default, null):String;
    public var pos:Int;

    public function new(str:String, file:String = 'file.hx') {
        this.str = str;
        this.file = file;
        this.pos = 0;
    }
    
    public function reset() {
        this.pos = 0;
    }
    
    public function eof() {
        return this.pos >= this.str.length;
    }

    public function createPos(?start:Int, ?end:Int):Position {
        if (start == null) start = this.pos;
        if (end == null) end = this.pos;
        return new Position(start, end, this);
    }
    
    public function slice(start:Int, end:Int):String {
        return str.substr(start, end - start);
    }

    public function peek(count:Int):String {
        return str.substr(pos, count);
    }

    public function skip(count:Int):Void {
        pos++;
    }

    public function matchLit(lit:String) {
        if (str.substr(pos, lit.length) != lit) return null;
        pos += lit.length;
        return lit;
    }

    public function matchEReg(v:EReg) {
        if (!v.match(str.substr(pos))) return null;
        var m = v.matched(0);
        pos += m.length;
        return m;
    }
}