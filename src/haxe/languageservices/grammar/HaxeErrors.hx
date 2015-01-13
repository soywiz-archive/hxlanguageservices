package haxe.languageservices.grammar;
class HaxeErrors {
    public var errors = new Array<ParserError>();
    public function new() {}
    public function reset() {
        errors.splice(0, errors.length);
    }
    public function add(error:ParserError) {
        errors.push(error);
    }
}
