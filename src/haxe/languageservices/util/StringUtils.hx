package haxe.languageservices.util;

using StringTools;

class StringUtils {
    static public function compare(a : String, b : String) : Int {
        return if ( a < b ) -1 else if ( a > b ) 1 else 0;
    }

    static public function empty(str:String) return str == null || str.length == 0;

    static public function isLowerCase(a:String):Bool return a == a.toLowerCase();
    static public function isUpperCase(a:String):Bool return a == a.toUpperCase();
    static public function isFirstUpper(a:String):Bool return isUpperCase(a.substr(0, 1));

    static public function removeStart(a:String, sub:String):String {
        while (a.startsWith(sub)) a = a.substr(sub.length);
        return a;
    }

    static public function removeEnd(a:String, sub:String):String {
        while (a.endsWith(sub)) a = a.substr(0, a.length - sub.length);
        return a;
    }
}