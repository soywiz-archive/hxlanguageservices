package haxe.languageservices.node;
class ConstTools {
    static public var predefinedConstants = ['true', 'false', 'null'];
    static public var keywords = [
        'package', 'import', 'using', 'abstract', 'enum', 'typedef', 'class', // top-level
        'extern', 'extends', 'implements', // class modifiers
        'inline', 'private', 'public', 'static', 'dynamic', 'override', // member modifiers
        'var', 'function',
        'default', 'never', // getters
        //'super', 'this', 'false', 'true', 'null',
        'untyped', 'new',
        'if', 'else',
        'switch', 'case', 'default',
        'cast',
        'return',
        'do', 'while', 'for', 'in', 'break', 'continue',
        'try', 'catch'
    ];

    static public function isPredefinedConstant(name:String) {
        // @TODO: improve lookup access with a map
        return predefinedConstants.indexOf(name) >= 0;
    }

    static public function isKeyword(name:String) {
        // @TODO: improve lookup access with a map
        return keywords.indexOf(name) >= 0;
    }
}
