package ;

import Main.NonTerminal;
class Main {
    public function new() {
    }

    static public function main() {
        var _id = new Terminal();
        var _numberLiteral = tok("123");
        var _typeName = tok("Abc");
        var _expr = new NonTerminal();
        var _exprSimple = new NonTerminal();
        var _qualifiedName = new NonTerminal();
        var _package = new NonTerminal();
        var _import = new NonTerminal();
        var _if = new NonTerminal();
        var _class = new NonTerminal();

        _expr.rule = any([
            seq([_exprSimple, any(['+', '-', '*', '/', '%']), _expr]),
            _exprSimple,
            //expr
        ]);
        _exprSimple.rule = any([
            seq(["(", _expr, ")"]),
            _numberLiteral,
        ]);

        _qualifiedName.rule = repeat(_id, ".");
        _package.rule = seq(["package", optional(_qualifiedName), ";"]);
        _import.rule = seq(["import", optional(_qualifiedName), ";"]);
        _if.rule = seq(["if", "(", _expr, ")", _expr, optional(seq(["else", _expr]))]);
        _class.rule = seq(["class", _typeName]);

        //var reader = new StringReader("    package test;");
        var reader = new StringReader("if (123 * (123 + 10)) 123");
        var context = new ParserContext(reader);
        var parser = new Parser();
        //parser.add(_package);
        parser.add(_if);
        parser.add(_class);
        parser.match(context);
        trace(reader.len);
        trace(reader);

    }

    static private function optional(token:Dynamic) {
        return new ParserNodeOptional(tok(token));
    }

    static private function repeat(token:Dynamic, between:Dynamic) {
        return new ParserNodeRepeat(tok(token), tok(between));
    }

    static private function any(items:Array<Dynamic>) {
        return new ParserNodeAny(items.map(tok));
    }

    static private function tok(item:Dynamic):ParserNode {
        if (Std.is(item, String)) {
            return new ParserNodeLiteral(item);
        } else {
            return cast(item, ParserNode);
        }
    }

    static private function seq(items:Array<Dynamic>) {
        return new ParserNodeSequence(items.map(tok));
    }
}

class BnfTerm extends ParserNode { public function new() { super(); } }

class Terminal extends BnfTerm { public function new() { super(); } }
class NonTerminal extends BnfTerm {
    public var rule:ParserNode;
    public function new() { super(); }

    override private function _match(context:ParserContext) {
        return rule.match(context);
    }
}

class Parser {
    private var nodes = new Array<ParserNode>();

    public function new() {}

    public function add(node:ParserNode) {
        this.nodes.push(node);
    }

    public function match(context:ParserContext) {
        for (node in nodes) {
            var result = node.match(context);
        }
    }
}

class ParserContext {
    public var reader:StringReader;
    private var stack = new Array<Dynamic>();

    public function new(reader:StringReader) {
        this.reader = reader;
    }

    public function save() {
        stack.push(reader.pos);
    }

    public function restore() {
        reader.pos = stack.pop();
    }
}

class CType {
    static public function isSpace(c:Int) {
        return (c == ' '.code) || (c == '\t'.code) || (c == '\r'.code) || (c == '\n'.code);
    }

    static public function isDigit(c:Int) return (c >= '0'.code) && (c <= '9'.code);
    static public function isXDigit(c:Int) return isDigit(c) || ((c >= 'a'.code) && (c <= 'f'.code)) || ((c >= 'A'.code) && (c <= 'F'.code));
}

class Matchers {
    static public function skipSpaces(reader:StringReader) {
        reader.match(CType.isSpace);
    }
}

class ParserNodeLiteral extends ParserNode {
    private var literal:String;

    public function new(literal:String) {
        super();
        this.literal = literal;
    }

    override private function _match(context:ParserContext) {
        return context.reader.matchLiteral(literal) ? MatchResult.Matching : MatchResult.NotMatching(100);
    }

    public function toString() { return "ParserNodeLiteral('" + literal + "')"; }
}

class ParserNodeRepeat extends ParserNode {
    private var node:ParserNode;
    private var between:ParserNode;

    public function new(node:ParserNode, between:ParserNode) {
        super();
        this.node = node;
        this.between = between;
    }

    override private function _match(context:ParserContext) {
        var result2:MatchResult;
        do {
            var result1 = this.node.match(context);
            result2 = this.between.match(context);
        } while (result2 == MatchResult.Matching);
        return MatchResult.Matching;
    }
}

enum MatchResult {
    Matching;
    NotMatching(matchedCount:Int);
}

class ParserNodeOptional extends ParserNode {
    private var opt:ParserNode;

    public function new(opt:ParserNode) {
        super();
        this.opt = opt;
    }

    override private function _match(context:ParserContext) {
        var result = opt.match(context);
        return MatchResult.Matching;
    }
}

class ParserNodeSequence extends ParserNode {
    private var nodes:Array<ParserNode>;

    public function new(nodes:Array<ParserNode>) {
        super();
        this.nodes = nodes;
    }

    override private function _match(context:ParserContext) {
        for (node in nodes) {
            var result = node.match(context);
            if (result != MatchResult.Matching) return result;
        }
        return MatchResult.Matching;
    }
}

class ParserNodeAny extends ParserNode {
    private var nodes:Array<ParserNode>;

    public function new(nodes:Array<ParserNode>) {
        super();
        this.nodes = nodes;
    }

    override private function _match(context:ParserContext) {
        for (node in nodes) {
            context.save();
            var result = node.match(context);
            if (result == MatchResult.Matching) {
                return MatchResult.Matching;
            }
            context.restore();
        }

        return MatchResult.NotMatching(100);
    }
}

class ParserNode {
    public function new() { }
    private function _match(context:ParserContext):MatchResult {
        return MatchResult.NotMatching(100);
    }
    public function match(context:ParserContext):MatchResult {
        Matchers.skipSpaces(context.reader);
        //context.reader.
        return _match(context);
    }
}

class StringReader {
    private var str:String;
    public var len(get, never):Int;
    public var pos:Int;

    public function new(str:String) {
        this.str = str;
        this.pos = 0;
    }

    private function get_len() return this.str.length;

    public function hasMore():Bool {
        return this.pos < this.str.length;
    }

    public function match(matcher: Int -> Bool) {
        while (hasMore() && matcher(peek())) next();
    }

    public function matchLiteral(literal:String) {
        var oldpos = this.pos;
        for (n in 0 ... literal.length) {
            if (literal.charCodeAt(n) != peek()) {
                this.pos = oldpos;
                return false;
            }
            this.next();
        }
        return true;
    }

    public function peek():Int {
        return this.str.charCodeAt(this.pos);
    }

    public function next():Void {
        this.pos++;
    }
}