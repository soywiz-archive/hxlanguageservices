package ;
import haxe.languageservices.HaxeLanguageServices;
import haxe.languageservices.util.MemoryVfs;
import haxe.PosInfos;
import haxe.unit.TestCase;

using StringTools;
using Lambda;

class TestCompletion extends HLSTestCase {
    private function assertProgramBody(prg:String, include:Array<String>, exclude:Array<String>, ?errors:Dynamic, ?callback:HaxeLanguageServices -> Void, ?p:PosInfos) {
        var index = prg.indexOf('###');
        prg = prg.replace('###', '');
        var live = 'live.hx';
        var vfs = new MemoryVfs().set(live, prg);
        var services = new HaxeLanguageServices(vfs);
        services.updateHaxeFile(live);
        
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
        
        if (callback != null) callback(services);

        if (errors != null) {
            assertEquals('' + errors, '' + services.getErrors(live), p);
        } else {
            for (error in services.getErrors(live)) haxe.Log.trace(error, p);
        }

//assertEquals('' + completion, '' + services.getCompletionAt(live, index), p);
    }

    private function assertFuntionBody(func:String, included:Array<String>, excluded:Array<String>, ?errors:Dynamic, ?p:PosInfos) {
        assertProgramBody('class Test { function funcname() { ' + func + ' } }', included, excluded, errors, p);
    }

    public function test1() {
        assertFuntionBody('var a = 10; ###', ['a:Int = 10'], []);
        assertFuntionBody('var a = [1,2,3]; ###', ['a:Array<Int>'], []);
        assertFuntionBody('var a = []; ###', ['a:Array<Dynamic>'], []);
        assertFuntionBody('var a = [false]; ###', ['a:Array<Bool>'], []);
        assertFuntionBody('for (a in []) { ###a; }', ['a:Dynamic'], []);
        assertFuntionBody('for (a in []) a; ###', [], ['a']);
        assertFuntionBody('var a = 10; { var a = false; ### }', ['a:Bool = false'], []);
        assertFuntionBody('var a = 10; { var a = false; } ###', ['a:Int = 10'], []);
        assertFuntionBody('for (a in [1, 2, 3]) { ### a; }', ['a:Int'], []);
        assertFuntionBody('for (a in [false, true, false]) { ### a; }', ['a:Bool'], []);
        assertFuntionBody('var a = false; for (a in [1, 2, 3]) a; ###', ['a:Bool = false'], []);
        assertFuntionBody('var a = "test"; ###', ['a:String = "test"'], []);
    }


    public function testInfiniteLoop() {
        assertFuntionBody('var a = a; ###', ['a:Dynamic'], []);
    }

    public function test3() {
        assertProgramBody('class Test { function a() { } function b() { ### } }', ['a:Void -> Dynamic', 'b:Void -> Dynamic', 'this:Test'], []);
    }

    public function test4() {
        assertFuntionBody('for (a in 0 ... 100) a; ###', [], ['a']);
        assertFuntionBody('for (a in 0...100) a; ###', [], ['a']);
        assertFuntionBody('for (a in 0...100) ###a;', ['a:Int'], []);
    }

    public function testArrayAccess() {
        assertFuntionBody('var array = [[1],[2],[3]]; var item = array[0]; var item2 = array[0][0]; ###', ['item:Array<Int>', 'item2:Int'], []);
    }

    public function testCall() {
        assertProgramBody('class A { function b() return 1; function a() { var result = b(); ### } }', ['result:Int = 1'], []);
    }

    public function testArguments() {
        assertProgramBody('class A { function method(a:Int, b:Int, c, d:Bool) { ### } }', ['a:Int', 'b:Int', 'c:Dynamic', 'd:Bool'], []);
    }

    public function testArguments2() {
        //assertProgramBody('class A { function method(a:Int, b:Int, c, d:Bool) { this.###method; } }', ['method:Int -> Int -> Bool -> Dynamic'], []);
        assertProgramBody('class A { function method(a:Int, b:Int, c, d:Bool) { this.###method; } }', ['method:Int -> Int -> Dynamic -> Bool -> Dynamic'], []);
    }

    public function testCast() {
        assertFuntionBody('var a = cast(10, Test); ###', ['a:Test'], []);
    }

    public function testArrayComprehension() {
        assertFuntionBody('var a = [for (n in 0 ... 10) n]; ###', ['a:Array<Dynamic>'], []);
        //assertFuntionBody('var a = [for (n in 0...10) if (true) 1]; ###', ['a:Array<Dynamic>'], []);
    }

    public function testTryCatch() {
        assertFuntionBody('try { ### } catch (e:Int) { }', [], ['e:Int']);
        assertFuntionBody('try { } catch (e:Int) { ### }', ['e:Int'], []);
    }

    public function testStringInterpolation() {
        assertFuntionBody("var a = 1; var z = '$###a';", ['a:Int = 1'], []);
    }

    public function testComments() {
        assertProgramBody(
            'class Test { /** MemberDoc *'+'/ function funcname() { ### } }', [], [], [],
            function(services:HaxeLanguageServices) {
                assertEqualsString('MemberDoc', services.getTypeMembers('Test')[0].doc);
            }
        );
    }

    public function testChaining() {
        assertProgramBody('class A { function chain() { return this; } function method() { this.chain().chain().###chain; } }', ['chain:Void -> A'], []);
    }

    /*
    public function testNew() {
        assertProgramBody('class A { function test() { var a = new A(); ### } }', ['a:A'], []);
    }
    */

    public function testFieldAccessCompletion() {
        assertProgramBody('class A { function a() { var m = []; m.###; } }', ['indexOf:Dynamic -> Int', 'charAt:Int -> String'], [], ['38:38:expected identifier']);
        assertProgramBody('class A { function a() { var m = []; m.###a; } }', ['indexOf:Dynamic -> Int', 'charAt:Int -> String'], [], ['39:40:Can\'t find member a in Array<Dynamic>']);
        assertProgramBody(
            'class A extends B { function a() { this.###; } } class B { function b() {} }',
            ['a:Void -> Dynamic', 'b:Void -> Dynamic'], [],
            '[39:39:expected identifier]'
        );
    }

    public function testFieldAccessInheritedCompletion() {
        assertProgramBody(
            'class A extends B { function a() { var m = this.b; ### } } class B { function b(a:Int):String { return "test"; } }',
            ['m:Int -> String'],
            [], []
        );
    }

    public function testStaticCall() {
        assertProgramBody(
            'class A { function a() { var m = B.b(10); ### } } class B { static public function b(a:Int):String { return "test"; } }',
            ['m:String'],
            [], []
        );
    }
}
