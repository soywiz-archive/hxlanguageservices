package ;
import haxe.PosInfos;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;

using StringTools;

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
    private function assertQuickFix(fixString:String, program:String, ?p:PosInfos) {
        var index = program.indexOf('###');
        program = program.replace('###', '');
        var hls = new HaxeLanguageServices(new MemoryVfs().set('live.hx', program));
        hls.updateHaxeFile('live.hx');
        var acts = [];
        for (error in hls.getErrors('live.hx')) {
            for (fix in error.fixes) {
                acts.push(fix.name + ':' + fix.fixer());
            }
        }
        assertEqualsString(fixString, '$acts', p);
    }

    public function test1() {
        assertQuickFix(
            '[Change type:[QFReplace(36:43,Int)],Add cast:[QFReplace(45:47,cast(10, String ))]]',
            'class Test { function a() { var str:String = 10; } }'
        );
        assertQuickFix(
            '[Change type:[QFReplace(34:38,String)],Add cast:[QFReplace(40:48,cast("string", Int ))]]',
            'class Test { function a() { var i:Int = "string"; } }'
        );
    }
}
