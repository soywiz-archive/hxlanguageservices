package haxe.languageservices.debug;

import haxe.languageservices.util.Signal;

interface DebugInterface {
    function execute(type:ExecType):Void;
    function evaluate(expr:String):Dynamic;
    function backtrace();
    function scripts():Array<String>;
    function gc():Void;
    function listBreakpoints():Array<Breakpoint>;
    var onStop:Signal;
    //var onStop(callback:Void -> Void):Void;
}

enum ExecType {
    StepOver(count:Int = 1);
    StepInto(count:Int = 1);
    StepOut(count:Int = 1);
    Continue;
}

enum Breakpoint {
    BPoint(file:String, line:Int);
}
