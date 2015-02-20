package haxe.languageservices.grammar;

import haxe.languageservices.node.Reader;
import haxe.languageservices.error.HaxeErrors;

class GrammarContext {
    public var errors:HaxeErrors;
    public var reader:Reader;
    public var doc:String = '';
    public function new(reader:Reader, errors:HaxeErrors = null) {
        if (errors == null) errors = new HaxeErrors();
        this.reader = reader;
        this.errors = errors;
    }
}
