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
            '[Change type:[QFReplace(36:43,Int)],Add cast:[QFReplace(45:47,cast(10, String))]]',
            'class Test { function a() { var str:String = 10; } }'
        );
        assertQuickFix(
            '[Change type:[QFReplace(34:38,String)],Add cast:[QFReplace(40:48,Std.parseInt("string"))]]',
            'class Test { function a() { var i:Int = "string"; } }'
        );
        assertQuickFix(
            '[Change type:[QFReplace(34:38,Float)],Add cast:[QFReplace(40:44,Std.int(10.0))]]',
            'class Test { function a() { var i:Int = 10.0; } }'
        );
    }

    public function testImplementInterface() {
        assertQuickFix(
            '[Implement methods:[QFReplace(26:26,function demo(a:Int):Int { throw "Not implemented demo"; }\nfunction demo2(a:Int):Int { throw "Not implemented demo2"; }\n)]]',
            'class Test implements Z { } interface Z { function demo(a:Int):Int { } function demo2(a:Int):Int { } }'
        );
    }

    public function testRemoveOverride() {
        assertQuickFix(
            '[Remove override:[QFReplace(13:22,)]]',
            'class Test { override function demo():Void { }  } }'
        );

        assertQuickFix(
            '[Add override:[QFReplace(23:23,override )]]',
            'class Test extends A { function a():Void { } } class A { function a():Void { }  } }'
        );
    }
}
