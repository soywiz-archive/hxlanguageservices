package haxe.languageservices.util;

class StringUtils {
    static public function compare(a : String, b : String) : Int {
        return if ( a < b ) -1 else if ( a > b ) 1 else 0;
    }

    static public function isLowerCase(a:String):Bool return a == a.toLowerCase();
    static public function isUpperCase(a:String):Bool return a == a.toUpperCase();
    static public function isFirstUpper(a:String):Bool return isUpperCase(a.substr(0, 1));
}