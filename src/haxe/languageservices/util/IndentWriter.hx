package haxe.languageservices.util;

using StringTools;

class IndentWriter {
    private var output = '';
    private var indentCount = 0;
    private var indents = [];
    private var startLine = true;

    public function new() {
    }

    public function write(text:String) {
        if (text.indexOf('\n') < 0) return writeChunk(text);
        var first = true;
        for (chunk in text.split('\n')) {
            if (!first) {
                writeEol();
            }
            writeChunk(chunk);
            first = false;
        }
    }
    
    private function writeEol() {
        //trace('eol');
        output += '\n';
        startLine = true;
    }
    
    private function writeChunk(text:String) {
        if (text == '') return;
        //trace('chunk:$text');
        if (startLine && indents != null && indents.length > 0) {
            output += indents.join('');
        }
        output += text;
        startLine = false;
    }

    public function indentStart() {
        indents.push('\t');
        indentCount++;
    }
    
    public function indentEnd() {
        indentCount--;
        indents.pop();
    }

    public inline function indent(callback: Void -> Void) {
        indentStart();
        callback();
        indentEnd();
    }

    public function toString() return output;
}
