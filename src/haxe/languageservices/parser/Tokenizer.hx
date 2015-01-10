package haxe.languageservices.parser;

import haxe.io.Input;
import haxe.languageservices.parser.Expr.Const;
import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.parser.Expr.ErrorDef;

enum Token {
    TEof;
    TConst(c:Const);
    TId(s:String);
    TOp(s:String);
    TPOpen; // (
    TPClose; // )
    TBrOpen; // {
    TBrClose; // }
    TDot; // .
    TComma; // ,
    TSemicolon; // ;
    TBkOpen; // [
    TBkClose; // ]
    TQuestion; // ?
    TDoubleDot; // :
}

typedef TokenDef = {
min:Int,
max:Int,
t:Token
}

class Tokenizer {
    var input:haxe.io.Input;
    public var line:Int;
    var tokens:List<TokenDef>;
    public var tokenMin:Int;
    public var tokenMax:Int;
    var oldTokenMin:Int;
    var oldTokenMax:Int;
    var readPos:Int;
    var char:Int;
    var ops:Array<Bool>;
    var idents:Array<Bool>;
    var path:String;

    public function new(input:Input, ?path:String) {
        this.line = 1;
        this.ops = [];
        this.idents = [];
        this.readPos = 0;
        this.tokenMin = oldTokenMin = 0;
        this.tokenMax = oldTokenMax = 0;
        this.tokens = new List();
        this.char = -1;
        this.input = input;
        this.path = path;

        var opChars = "+*/-=!><&|^%~";
        var identChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";

        for (i in 0...opChars.length) ops[opChars.charCodeAt(i)] = true;
        for (i in 0...identChars.length) idents[identChars.charCodeAt(i)] = true;
    }

    public function token():Token {
        var t = tokens.pop();
        if (t != null) {
            tokenMin = t.min;
            tokenMax = t.max;
            return t.t;
        }
        oldTokenMin = tokenMin;
        oldTokenMax = tokenMax;
        tokenMin = (this.char < 0) ? readPos : readPos - 1;
        var t = _token();
        tokenMax = (this.char < 0) ? readPos - 1 : readPos - 2;
        return t;
    }

    function _token():Token {
        var char;
        if (this.char < 0)
            char = readChar();
        else {
            char = this.char;
            this.char = -1;
        }
        while (true) {
            switch( char ) {
                case 0: return Token.TEof;
                case 32, 9, 13: tokenMin++; // space, tab, CR
                case 10: line++; tokenMin++; // LF
                case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0...9
                    var n = (char - 48) * 1.0;
                    var exp = 0.;
                    while (true) {
                        char = readChar();
                        exp *= 10;
                        switch( char ) {
                            case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
                                n = n * 10 + (char - 48);
                            case 46:
                                if (exp > 0) {
// in case of '...'
                                    if (exp == 10 && readChar() == 46) {
                                        push(Token.TOp("..."));
                                        var i = Std.int(n);
                                        return Token.TConst((i == n) ? Const.CInt(i) : Const.CFloat(n));
                                    }
                                    invalidChar(char);
                                }
                                exp = 1.;
                            case 120: // x
                                if (n > 0 || exp > 0) invalidChar(char);
// read hexa
                                var n = 0;
                                while (true) {
                                    char = readChar();
                                    switch( char ) {
                                        case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0-9
                                            n = (n << 4) + char - 48;
                                        case 65, 66, 67, 68, 69, 70: // A-F
                                            n = (n << 4) + (char - 55);
                                        case 97, 98, 99, 100, 101, 102: // a-f
                                            n = (n << 4) + (char - 87);
                                        default:
                                            this.char = char;
                                            return Token.TConst(Const.CInt(n));
                                    }
                                }
                            default:
                                this.char = char;
                                var i = Std.int(n);
                                return Token.TConst((exp > 0) ? Const.CFloat(n * 10 / exp) : ((i == n) ? Const.CInt(i) : Const.CFloat(n)));
                        }
                    }
                case ';'.code: return Token.TSemicolon;
                case '('.code: return Token.TPOpen;
                case ')'.code: return Token.TPClose;
                case ','.code: return Token.TComma;
                case '.'.code:
                    char = readChar();
                    switch( char ) {
                        case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
                            var n = char - 48;
                            var exp = 1;
                            while (true) {
                                char = readChar();
                                exp *= 10;
                                switch( char ) {
                                    case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
                                        n = n * 10 + (char - 48);
                                    default:
                                        this.char = char;
                                        return Token.TConst(Const.CFloat(n / exp));
                                }
                            }
                        case 46:
                            char = readChar();
                            if (char != 46)
                                invalidChar(char);
                            return Token.TOp("...");
                        default:
                            this.char = char;
                            return Token.TDot;
                    }
                case '{'.code: return Token.TBrOpen;
                case '}'.code: return Token.TBrClose;
                case '['.code: return Token.TBkOpen;
                case ']'.code: return Token.TBkClose;
                case "'".code: return Token.TConst(Const.CString(readString(39)));
                case '"'.code: return Token.TConst(Const.CString(readString(34)));
                case '?'.code: return Token.TQuestion;
                case ':'.code: return Token.TDoubleDot;
                default:
                    if (ops[char]) {
                        var op = String.fromCharCode(char);
                        while (true) {
                            char = readChar();
                            if (!ops[char]) {
                                if (op.charCodeAt(0) == 47)
                                    return tokenComment(op, char);
                                this.char = char;
                                return TOp(op);
                            }
                            op += String.fromCharCode(char);
                        }
                    }
                    if (idents[char]) {
                        var id = String.fromCharCode(char);
                        while (true) {
                            char = readChar();
                            if (!idents[char]) {
                                this.char = char;
                                return Token.TId(id);
                            }
                            id += String.fromCharCode(char);
                        }
                    }
                    invalidChar(char);
            }
            char = readChar();
        }
        return null;
    }

    function readString(until) {
        var c = 0;
        var b = new haxe.io.BytesOutput();
        var esc = false;
        var old = line;
        var s = input;
        var p1 = readPos - 1;
        while (true) {
            try {
                incPos();
                c = s.readByte();
            } catch (e:Dynamic) {
                line = old;
                error(ErrorDef.EUnterminatedString, p1, p1);
            }
            if (esc) {
                esc = false;
                switch( c ) {
                    case 'n'.code: b.writeByte(10);
                    case 'r'.code: b.writeByte(13);
                    case 't'.code: b.writeByte(9);
                    case "'".code, '"'.code, '\\'.code: b.writeByte(c);
                    case '/'.code: b.writeByte(c);
                    case "u".code:
                        var code:String = null;
                        try {
                            incPos();
                            incPos();
                            incPos();
                            incPos();
                            code = s.readString(4);
                        } catch (e:Dynamic) {
                            line = old;
                            error(ErrorDef.EUnterminatedString, p1, p1);
                        }
                        var k = 0;
                        for (i in 0...4) {
                            k <<= 4;
                            var char = code.charCodeAt(i);
                            switch (char) {
                                case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: k += char - 48; // 0-9
                                case 65, 66, 67, 68, 69, 70: k += char - 55; // A-F
                                case 97, 98, 99, 100, 101, 102: k += char - 87; // a-f
                                default: invalidChar(char);
                            }
                        }
                        // encode k in UTF8
                        if (k <= 0x7F) {
                            b.writeByte(k);
                        } else if (k <= 0x7FF) {
                            b.writeByte(0xC0 | (k >> 6));
                            b.writeByte(0x80 | (k & 63));
                        } else {
                            b.writeByte(0xE0 | (k >> 12));
                            b.writeByte(0x80 | ((k >> 6) & 63));
                            b.writeByte(0x80 | (k & 63));
                        }
                    default: invalidChar(c);
                }
            } else if (c == 92)
                esc = true;
            else if (c == until)
                break;
            else {
                if (c == 10) line++;
                b.writeByte(c);
            }
        }
        return b.getBytes().toString();
    }

    function tokenComment(op:String, char:Int) {
        var c = op.charCodeAt(1);
        var s = input;
        if (c == 47) { // comment
            try {
                while (char != 10 && char != 13) {
                    incPos();
                    char = s.readByte();
                }
                this.char = char;
            } catch (e:Dynamic) {
            }
            return token();
        }
        if (c == 42) { /* comment */
            var old = line;
            try {
                while (true) {
                    while (char != 42) {
                        if (char == 10) line++;
                        incPos();
                        char = s.readByte();
                    }
                    incPos();
                    char = s.readByte();
                    if (char == 47)
                        break;
                }
            } catch (e:Dynamic) {
                line = old;
                error(ErrorDef.EUnterminatedComment, tokenMin, tokenMin);
            }
            return token();
        }
        this.char = char;
        return Token.TOp(op);
    }

    public inline function error(err, pmin, pmax) {
        throw new Error(err, pmin, pmax);
    }

    public inline function push(tk) {
        tokens.push({ t : tk, min : tokenMin, max : tokenMax });
        tokenMin = oldTokenMin;
        tokenMax = oldTokenMax;
    }

    inline function incPos() {
        readPos++;
    }

    function readChar() {
        incPos();
        return try input.readByte() catch (e:Dynamic) 0;
    }

    public function invalidChar(c) {
        error(ErrorDef.EInvalidChar(c), readPos, readPos);
    }

    public function constString(c) {
        return switch(c) {
            case Const.CInt(v): Std.string(v);
            case Const.CFloat(f): Std.string(f);
            case Const.CString(s): s; // TODO : escape + quote
        }
    }

    public function tokenString(t) {
        return switch( t ) {
            case Token.TEof: "<eof>";
            case Token.TConst(c): constString(c);
            case Token.TId(s): s;
            case Token.TOp(s): s;
            case Token.TPOpen: "(";
            case Token.TPClose: ")";
            case Token.TBrOpen: "{";
            case Token.TBrClose: "}";
            case Token.TDot: ".";
            case Token.TComma: ",";
            case Token.TSemicolon: ";";
            case Token.TBkOpen: "[";
            case Token.TBkClose: "]";
            case Token.TQuestion: "?";
            case Token.TDoubleDot: ":";
        }
    }

}
