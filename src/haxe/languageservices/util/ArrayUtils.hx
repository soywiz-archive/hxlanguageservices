package haxe.languageservices.util;

class ArrayUtils {
    static public function unique<T>(array:Array<T>):Array<T> {
        var out = new Array<T>();
        for (item in array) if (out.indexOf(item) < 0) out.push(item);
        return out;
    }

    static public function sorted<T>(array:Array<T>):Array<T> {
        var out = array.slice(0, array.length);
        out.sort(compare);
        return out;
    }

    static public function uniqueSorted<T>(array:Array<T>):Array<T> {
        return sorted(unique(array));
    }

    static private function compare(a:Dynamic, b:Dynamic):Int {
        return if ( a < b ) -1 else if ( a > b ) 1 else 0;
    }

    static public function contains<T>(array:Array<T>, item:T) return array.indexOf(item) >= 0;

    static public function containsAll<T>(a:Array<T>, sub:Array<T>) {
        for (i in sub) if (!contains(a, i)) return false;
        return true;
    }

    static public function containsAny<T>(a:Array<T>, sub:Array<T>) {
        for (i in sub) if (contains(a, i)) return true;
        return false;
    }

    static public function pushOnce<T>(array:Array<T>, value:T) {
        if (!contains(array, value)) array.push(value);
    }
}
