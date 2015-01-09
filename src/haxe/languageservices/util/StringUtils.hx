package haxe.languageservices.util;

class StringUtils {
    static public function compare(a : String, b : String) : Int {
        return if ( a < b ) -1 else if ( a > b ) 1 else 0;
    }
}