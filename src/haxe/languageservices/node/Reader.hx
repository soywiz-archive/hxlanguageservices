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

    public function peekChar():Int {
        return str.charCodeAt(pos);
    }

    public function read(count:Int):String {
        var out = peek(count);
        skip(count);
        return out;
    }

    public function unread(count:Int):Void {
        pos -= count;
    }
    public function readChar():Int {
        var out = peekChar();
        skip(1);
        return out;
    }

    public function skip(count:Int):Void {
        pos += count;
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

    public function matchStartEnd(start:String, end:String) {
        if (str.substr(pos, start.length) != start) return null;
        var startIndex = pos;
        var index = str.indexOf(end, pos);
        if (index < 0) return null;
        //trace(index);
        pos = index + end.length;
        return slice(startIndex, pos);
    }
}