package ;
import haxe.PosInfos;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;
import haxe.unit.TestCase;

using StringTools;

class TestReferences extends HLSTestCase {
    private function assertReferences(program:String, assert:String, ?p:PosInfos) {
        var index = program.indexOf('###');
        program = program.replace('###', '');
        var hls = new HaxeLanguageServices(new MemoryVfs().set('live.hx', program));
        hls.updateHaxeFile('live.hx');
        assertEqualsString(assert, hls.getReferencesAt('live.hx', index), p);
    }

    public function testMethodReferences() {
        assertReferences(
            'class Test { function a() { } function b() { this.a(); ###a(); } }',
            'a:[22:23:Declaration,50:51:Read,55:56:Read]'
        );
    }

    public function testFieldReferences() {
        assertReferences(
            'class Test { var ###m = 10; function a() { m; this.m; return m + 1; } }',
            'm:[17:18:Declaration,40:41:Read,48:49:Read,58:59:Read]'
        );
        assertReferences(
            'class Test { var ###m = 10; function a(m) { m; this.m; return m + 1; } }',
            'm:[17:18:Declaration,49:50:Read]'
        );
    }

    public function testFunctionArgumentReferences() {
        assertReferences(
            'class Test { var m = 10; function a(###m) { m; this.m; return m + 1; } }',
            'm:[36:37:Declaration,41:42:Read,59:60:Read]'
        );
    }

    public function testSqStringReferences() {
        assertReferences(
            "class Test { var m = 10; function a(###m) { return '$m'; } }",
            'm:[36:37:Declaration,50:51:Read]'
        );
    }

    public function testClassReferences() {
        assertReferences(
            "class Test extends D###emo { } class Demo { }",
            'Demo:[34:38:Declaration,19:23:Read]'
        );
    }

    public function testNewReferences() {
        assertReferences(
            "class Test { function a() { var vv:Te###st = new Test(); } }",
            'Test:[6:10:Declaration,35:39:Read,46:50:Read]'
        );
    }
}
