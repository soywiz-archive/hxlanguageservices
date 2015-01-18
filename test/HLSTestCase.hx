package ;

import haxe.Json;
import haxe.PosInfos;
import haxe.unit.TestCase;

class HLSTestCase extends TestCase {
    private function assertEqualsString(a:Dynamic, b:Dynamic, ?p:PosInfos) {
        assertEquals('' + a, '' + b, p);
    }

    private function assertEqualsJson(a:Dynamic, b:Dynamic, ?p:PosInfos) {
        assertEquals(Json.stringify(a), Json.stringify(b), p);
    }
}
