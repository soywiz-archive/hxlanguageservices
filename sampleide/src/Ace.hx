package ;

import js.Browser;

// Misses: do and using keywords
@:native("ace")
extern class Ace {
    static public function edit(el:String):Editor;
    static public function require(path:String):Dynamic;
}

class AceTools {
    static private function _createRange(startRow:Int, startColumn:Int, endRow:Int, endColumn:Int):Range {
        var vv = untyped ace.require("ace/range").Range;
        return Type.createInstance(vv, [startRow, startColumn, endRow, endColumn]);
    }
    static public function createRange(start:Position, end:Position):Range {
        return _createRange(start.row, start.column, end.row, end.column);
    }
}

extern class Editor {
    public var session:Session;
    public var renderer:Renderer;
    public function setTheme(name:String):Void;
    public function setOptions(name:Options):Void;
    public function getSession():Session;
}

typedef Options = {
    ?enableBasicAutocompletion:Bool,
};

extern class Document {
    public function indexToPosition(index: Int, startRow: Int): Position;
    public function positionToIndex(pos: Position, startRow: Int): Int;
}

typedef Position = { row:Int, column:Int };
typedef ScreenPosition = { pageX:Int, pageY:Int };

@:native('')
extern class Range {
    public function new(startRow:Int, startColumn:Int, endRow:Int, endColumn:Int);
}

typedef Annotation = {
    var row: Float;
    var column: Float;
    var text: String;
    var type: String;
}

extern class TokenInfo {
}

extern class UndoManager {
}

extern class Renderer {
    public function textToScreenCoordinates(row:Int, column:Int):ScreenPosition;
}

extern class Session {
    //public var bgTokenizer: BackgroundTokenizer;
    
    public var selection:Selection;
    public var document:Document;
    
    public var doc:Document;
    public function on(event:String, fn:Dynamic -> Dynamic):Void;
    public function findMatchingBracket(position:Position):Void;
    public function addFold(text:String, range:Range):Void;
    public function getFoldAt(row:Float, column:Float):Dynamic;
    public function removeFold(arg:Dynamic):Void;
    public function expandFold(arg:Dynamic):Void;
    public function unfold(arg1:Dynamic, arg2:Bool):Void;
    public function screenToDocumentColumn(row:Float, column:Float):Void;
    public function getFoldDisplayLine(foldLine:Dynamic, docRow:Float, docColumn:Float):Dynamic;
    public function getFoldsInRange(range:Range):Dynamic;
    public function highlight(text:String):Void;
    public function setDocument(doc:Document):Void;
    public function getDocument():Document;
    //public function $resetRowCache(row: number);
    public function setValue(text:String):Void;
    public function setMode(mode:String):Void;
    public function getValue():String;
    public function getSelection():Selection;
    public function getState(row:Float):String;
    public function getTokens(row:Float):Array<TokenInfo>;
    public function getTokenAt(row:Float, column:Float):TokenInfo;
    
    public function setUndoManager(undoManager:UndoManager):Void;
    public function getUndoManager():UndoManager;
    public function getTabString():String;
    public function setUseSoftTabs(useSoftTabs:Bool):Void;
    public function getUseSoftTabs():Bool;
    public function setTabSize(tabSize:Float):Void;
    public function getTabSize():String;
    
    public function isTabStop(position:Dynamic):Bool;

/*
    setOverwrite(overwrite: boolean);
    getOverwrite(): boolean;
    toggleOverwrite();
    addGutterDecoration(row: number, className: string);
    removeGutterDecoration(row: number, className: string);
    getBreakpoints(): number[];
    setBreakpoints(rows: any[]);
    clearBreakpoints();
    setBreakpoint(row: number, className: string);
    clearBreakpoint(row: number);
    */
    @:overload(function(range:Range, clazz:String, type:Dynamic, inFront:Bool):Void {})
    public function removeMarker(markerId:Int):Void;
    public function addMarker(range:Range, clazz:String, type:String, inFront:Bool):Int;
    public function setAnnotations(annotations: Array<Annotation>):Void;
    public function getAnnotations(): Array<Annotation>;
/*
    addDynamicMarker(marker: any, inFront: boolean);
    removeMarker(markerId: number);
    getMarkers(inFront: boolean): any[];
    clearAnnotations();
    $detectNewLine(text: string);
    getWordRange(row: number, column: number): Range;
    getAWordRange(row: number, column: number): any;
    setNewLineMode(newLineMode: string);
    getNewLineMode(): string;
    setUseWorker(useWorker: boolean);
    getUseWorker(): boolean;
    onReloadTokenizer();
    $mode(mode: TextMode);
    getMode(): TextMode;
    setScrollTop(scrollTop: number);
    getScrollTop(): number;
    setScrollLeft();
    getScrollLeft(): number;
    getScreenWidth(): number;
    getLine(row: number): string;
    getLines(firstRow: number, lastRow: number): string[];
    getLength(): number;
    getTextRange(range: Range): string;
    insert(position: Position, text: string): any;
    remove(range: Range): any;
    undoChanges(deltas: any[], dontSelect: boolean): Range;
    redoChanges(deltas: any[], dontSelect: boolean): Range;
    setUndoSelect(enable: boolean);
    replace(range: Range, text: string): any;
    moveText(fromRange: Range, toPosition: any): Range;
    indentRows(startRow: number, endRow: number, indentString: string);
    outdentRows(range: Range);
    moveLinesUp(firstRow: number, lastRow: number): number;
    moveLinesDown(firstRow: number, lastRow: number): number;
    duplicateLines(firstRow: number, lastRow: number): number;
    setUseWrapMode(useWrapMode: boolean);
    getUseWrapMode(): boolean;
    setWrapLimitRange(min: number, max: number);
    adjustWrapLimit(desiredLimit: number): boolean;
    getWrapLimit(): number;
    getWrapLimitRange(): any;
    $getDisplayTokens(str: string, offset: number);
    $getStringScreenWidth(str: string, maxScreenColumn: number, screenColumn: number): number[];
    getRowLength(row: number): number;
    getScreenLastRowColumn(screenRow: number): number;
    getDocumentLastRowColumn(docRow: number, docColumn: number): number;
    getDocumentLastRowColumnPosition(docRow: number, docColumn: number): number;
    getRowSplitData(): string;
    getScreenTabSize(screenColumn: number): number;
    screenToDocumentPosition(screenRow: number, screenColumn: number): any;
    documentToScreenPosition(docRow: number, docColumn: number): any;
    documentToScreenColumn(row: number, docColumn: number): number;
    documentToScreenRow(docRow: number, docColumn: number);
    getScreenLength(): number;
    */
}

extern class Selection {
    public function on(event:String, fn:Dynamic -> Dynamic):Void;
    public function moveCursorFileEnd():Void;
    public function isEmpty(): Bool;
    public function isMultiLine(): Bool;
    public function getCursor(): Position;
}