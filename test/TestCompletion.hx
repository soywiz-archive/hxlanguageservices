package ;
import haxe.languageservices.HaxeLanguageServices;
import haxe.languageservices.util.MemoryVfs;
import haxe.PosInfos;
import haxe.unit.TestCase;

using StringTools;
using Lambda;

class TestCompletion extends TestCase {
    private function assertProgramBody(prg:String, include:Array<String>, exclude:Array<String>, ?p:PosInfos) {
        var index = prg.indexOf('###');
        prg = prg.replace('###', '');
        var live = 'live.hx';
        var vfs = new MemoryVfs().set(live, prg);
        var services = new HaxeLanguageServices(vfs);
        services.updateHaxeFile(live);

        for (error in services.getErrors(live)) {
            trace(error);
        }

        var items = services.getCompletionAt(live, index).items;
        for (i in include) {
            var included = Lambda.exists(items, function(e:CompEntry) { return i == e.toString(); });
            if (!included) {
                assertEquals('not containing $i in $items', '-', p);
            } else {
                assertTrue(true, p);
            }
        }

        for (i in exclude) {
            var included = Lambda.exists(items, function(e:CompEntry) { return i == e.name; });
            if (included) {
                assertEquals('containing $i in $items', '-', p);
            } else {
                assertTrue(true, p);
            }
        }

        //assertEquals('' + completion, '' + services.getCompletionAt(live, index), p);
    }

    private function assertFuntionBody(func:String, included:Array<String>, excluded:Array<String>, ?p:PosInfos) {
        assertProgramBody('class Test { function funcname() { ' + func + ' } }', included, excluded, p);
    }

    public function test1() {
        assertFuntionBody('var a = 10; ###', ['a:Int = 10'], []);
        assertFuntionBody('var a = [1,2,3]; ###', ['a:Array<Int>'], []);
        assertFuntionBody('var a = []; ###', ['a:Array<Dynamic>'], []);
        assertFuntionBody('var a = [false]; ###', ['a:Array<Bool>'], []);
        assertFuntionBody('for (a in []) ### a;', ['a:Dynamic'], []);
        assertFuntionBody('for (a in []) a; ###', [], ['a']);
        assertFuntionBody('var a = 10; { var a = false; ### }', ['a:Bool = false'], []);
        assertFuntionBody('var a = 10; { var a = false; } ###', ['a:Int = 10'], []);
        assertFuntionBody('for (a in [1, 2, 3]) ### a;', ['a:Int'], []);
        assertFuntionBody('for (a in [false, true, false]) ### a;', ['a:Bool'], []);
        assertFuntionBody('var a = false; for (a in [1, 2, 3]) a; ###', ['a:Bool = false'], []);
    }

    public function test2() {
        assertFuntionBody('var a = a; ###', ['a:Dynamic'], []);
    }

    public function test3() {
        assertProgramBody('class Test { function a() { } function b() { ### } }', ['a:Dynamic', 'b:Dynamic', 'this:Dynamic'], []);
    }

    public function test4() {
        assertFuntionBody('var array = [[1],[2],[3]]; var item = array[0]; ###', ['item:Array<Int>'], []);
    }

    public function testArguments() {
        assertProgramBody('class A { function method(a:Int, b:Int, c, d:Bool) { ### } }', ['a:Int', 'b:Int', 'c:Dynamic', 'd:Bool'], []);
    }
}
