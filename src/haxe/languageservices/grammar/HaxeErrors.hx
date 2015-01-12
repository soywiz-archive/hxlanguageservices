package haxe.languageservices.grammar;
class HaxeErrors {
    public var errors = new Array<ParserError>();
    public function new() {}
    public function add(error:ParserError) {
        errors.push(error);
    }
}
