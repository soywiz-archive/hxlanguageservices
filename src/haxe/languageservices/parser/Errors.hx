package haxe.languageservices.parser;

import haxe.languageservices.parser.Expr.Error;

class Errors {
    public function new() {
    }
}

class ErrorContext {
    public var errors = new Array<Error>();
}

