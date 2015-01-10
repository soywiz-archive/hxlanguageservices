Haxe Language Services
======================

[![Build Status](https://travis-ci.org/soywiz/hxlanguageservices.svg?branch=master)](https://travis-ci.org/soywiz/hxlanguageservices)

The aim for this project is to provide haxe language services completely written in haxe that are able to
work anywhere without a server or even an haxe compiler providing completion, refactoring, references services
and providing unified code to debug the haxe compiled code for several languages like flash, cpp or javascript.

These services will allow to create a proper IDE with proper tooling (completion, renaming, organizing imports, debugging, unittests...) easily.

This project is initially based on [hscript](https://github.com/HaxeFoundation/hscript) work
and modified to get type information and to provide other language services.

Services provided at this point:

```haxe
class HaxeLanguageServices {
    // Get a list of possible identifiers used in an offset with type information
    function getCompletionAt(path:String, offset:Int):CompletionList;
    
    // Get information about a calling function, with parameters information and current parameter index
    function getCallInfoAt(path:String, offset:Int):CCompletion;
    
    // Get a list of syntax/parser/semantic errors
    function getErrors(path:String):ErrorContext
}
```

Haxe Sdk + Libraries (get sdk version and libraries information, available versions, haxelib.json information...):

```haxe
class HaxeSdk {
    // Haxe Version of the defined SDK
    function getVersion():String;
    
    function getLibrary(name:String):HaxeLibrary;
    // ...
}
```


Projects (hxml and lime.xml projects):

```haxe
class HaxeProject {
    function setBaseDefines(base:Array<String>);
    function getDefines():Array<String>;
    function getClassPaths():Array<String>;
}

class HxmlHaxeProject extends HaxeProject;
class LimeXmlHaxeProject extends HaxeProject;
```

Debugger (not implemented yet):

```haxe
interface DebugInterface {
    function execute(type:ExecType):Void;
    function evaluate(expr:String):Dynamic;
    function backtrace();
    function scripts():Array<String>;
    function gc():Void;
    function listBreakpoints():Array<Breakpoint>;
    var onStop:Signal;
}
```