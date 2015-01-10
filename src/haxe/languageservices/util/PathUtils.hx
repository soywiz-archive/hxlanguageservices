package haxe.languageservices.util;

using StringTools;

class PathUtils {
    static public function isAbsolute(path:String) {
        if (path.startsWith('/')) return true;
        if (path.substr(1, 1) == ':') return true;
        return false;
    }

    static public function combine(p1:String, p2:String) {
        p1 = p1.replace('\\', '/');
        p2 = p2.replace('\\', '/');
        if (isAbsolute(p2)) return p2;
        var parts = [];
        for (part in p1.split('/').concat(p2.split('/'))) {
            switch (part) {
                case '.', '':
                case '..': if (parts.length > 0) parts.pop();
                default: parts.push(part);
            }
        }
        var result = parts.join('/');
        return p1.startsWith('/') ? '/$result' : result;
    }
}
