package haxe.languageservices.util;

class ArrayUtils {
    static public function unique<T>(array:Array<T>):Array<T> {
        var out = new Array<T>();
        for (item in array) if (out.indexOf(item) < 0) out.push(item);
        return out;
    }
}
