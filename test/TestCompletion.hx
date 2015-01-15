package ;
import haxe.languageservices.HaxeLanguageServices;
import haxe.languageservices.util.MemoryVfs;
import haxe.PosInfos;
import haxe.unit.TestCase;

using StringTools;

class TestCompletion extends TestCase {
    private function assertProgramErrors(prg:String, completion:Dynamic, ?p:PosInfos) {
        var index = prg.indexOf('###');
        prg = prg.replace('###', '');
        var live = 'live.hx';
        var vfs = new MemoryVfs().set(live, prg);
        var services = new HaxeLanguageServices(vfs);
        services.updateHaxeFile(live);
        assertEquals('' + completion, '' + services.getCompletionAt(live, index));
    }

    private function assertFuntionBody(func:String, completion:Dynamic, ?p:PosInfos) {
        assertProgramErrors('class Test { function a() { ' + func + ' } }', completion, p);
    }

    public function test1() {
        assertFuntionBody('var a = 10; ###', 'a:Int');
        assertFuntionBody('for (a in []) ### a;', 'a:Dynamic');
        assertFuntionBody('for (a in []) a; ###', '');
        assertFuntionBody('var a = 10; { var a = false; ### }', 'a:Bool');
        assertFuntionBody('var a = 10; { var a = false; } ###', 'a:Int');
    }
}
