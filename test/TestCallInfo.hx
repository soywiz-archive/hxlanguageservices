package ;

import haxe.languageservices.HaxeLanguageServices;
import haxe.languageservices.util.MemoryVfs;
import haxe.PosInfos;

using StringTools;

class TestCallInfo extends HLSTestCase {
    private function assertCallInfo(assert:String, program:String, ?p:PosInfos) {
        var index = program.indexOf('###');
        program = program.replace('###', '');
        var hls = new HaxeLanguageServices(new MemoryVfs().set('live.hx', program));
        hls.updateHaxeFile('live.hx');
        assertEqualsString(assert, hls.getCallInfoAt('live.hx', index), p);
    }

    public function test1() {
        assertCallInfo('0:a(test:Int):Dynamic', 'class Test { function a(test:Int) { a(###1); } }');
        assertCallInfo('1:a(test:Int, arg:Int):Dynamic', 'class Test { function a(test:Int, arg:Int) { a(1, ###2); } }');
    }

    public function test2() {
        assertCallInfo('0:a(test:Int):Dynamic', 'class Test { function a(test:Int) { a(###); } }');
        assertCallInfo('0:a(test:Int):Dynamic', 'class Test { function a(test:Int) { a( ### ); } }');
        assertCallInfo('0:a(test:Int):Dynamic', 'class Test { function a(test:Int) { a( ###); } }');
    }

    public function test3() {
        //assertCallInfo('0:a(test:Int, arg:Int):Dynamic', 'class Test { function a(test:Int, arg:Int) { a(1###, ); } }');
        assertCallInfo('1:a(test:Int, arg:Int):Dynamic', 'class Test { function a(test:Int, arg:Int) { a(1, ###); } }');
    }

/*
    public function test3() {
        assertCallInfo(
            'class Test { function a(test:Int, arg:Int) { a(1,### 2); } }',
            '1:(test:Int, arg:Int):Dynamic'
        );
    }
*/
}
