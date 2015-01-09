package haxe.languageservices.debug.js;

import haxe.languageservices.debug.DebugInterface.ExecType;

class JsV8Debug {
    public function new() {
    }
}

class V8DebugSocket {
}

class V8DebugInterface implements DebugInterface {
    public function execute(type:ExecType):Void {
    }

    public function evaluate(expr:String):Dynamic {
    }

    public function backtrace() {
    }

    public function scripts():Array<String> {
    }

    public function gc():Void {
    }

    public function listBreakpoints():Array<Breakpoint> {
    }
}
