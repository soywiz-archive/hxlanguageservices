package ;
import haxe.PosInfos;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;
class TestRenames extends HLSTestCase {
    /*
    private function assertRename(after:String, program:String, ?p:PosInfos) {
        var index = program.indexOf('###');
        program = program.replace('###', '');
        var hls = new HaxeLanguageServices(new MemoryVfs().set('live.hx', program));
        hls.updateHaxeFile('live.hx');
        assertEqualsString(assert, hls.getCallInfoAt('live.hx', index), p);
    }

    public function test1() {
        assertRename('');
    }
    */
}
