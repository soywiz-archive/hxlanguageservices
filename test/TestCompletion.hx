import haxe.languageservices.parser.Parser;
import haxe.languageservices.util.StringUtils;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.parser.Completion.CCompletion;
import haxe.languageservices.parser.Completion.CompletionType;
import haxe.PosInfos;
import haxe.unit.TestCase;

class TestCompletion extends TestCase {
    public function testCompletion() {
        assertCompletion(
            'var z = {a:1};var sum=0;for (item in [z,z,z]) sum += item.###a; sum;',
            ['a:Int']
        );

        assertCompletion2(
            'var z = {a:1};var sum=0;for (item in [z,z,z]) sum += item.a; ###',
            ['sum:Int','z:{a:Int}']
        );

        assertCompletion2(
            'var z = 1; { var x = 1; ### }',
            ['x:Int', 'z:Int']
        );

        assertCompletion2(
            'var z = 1; { var x = 1; } ###',
            ['z:Int']
        );

        assertCompletion2(
            'var c:Bool = false; function test(a:Int, b:Float, c:String) { ### }',
            ['a:Int', 'b:Float', 'c:String', 'test:Int -> Float -> String -> Void']
        );

        assertCompletion2(
            'var c:Bool = false; function test(a:Int, b:Float, c:String) { } ###',
            ['c:Bool', 'test:Int -> Float -> String -> Void']
        );

        assertCompletion2(
            'var c = if (true) 1; else 2; ###',
            ['c:Int']
        );

        assertCompletion2(
            'var c = -(1 + 2.1); ###',
            ['c:Float']
        );

        // @TODO: Fixme
        assertCompletion2(
            'var c = [for (n in 0 ... 10) "test" + n]; ###',
            ['c:Dynamic']
        );
    }

    public function testCallCompletion() {
        assertCallCompletion(
            'function test(a:Int, b:String, c) { return 7; } test(1, ###2, 3);',
            CCompletion.CallCompletion(
                '<anonymous>',
                'test',
                [
                    { name : "a", type : CompletionType.Int, optional: null },
                    { name : "b", type : CompletionType.String, optional: null },
                    { name : "c", type : CompletionType.Dynamic, optional: null },
                ],
                { type: CompletionType.Int },
                1
            )
        );
    }

    private function assertCompletion(x:String, v:Array<String>,  ?c : PosInfos) {
        var index = x.indexOf('###');
        x = StringTools.replace(x, '###', '');
        var p = new Parser();
        var program = p.parseExpressionsString(x);
        for (e in p.errors.errors) trace('Error:$e');
        assertEquals(v.join(','), p.completionsAt(index).toString(), c);
        return p.errors;
    }

    private function assertCompletion2(x:String, v:Array<String>,  ?c : PosInfos) {
        var v2 = v.slice(0, v.length);
        v2.push('false:Bool');
        v2.push('true:Bool');
        v2.push('null:Dynamic');
        v2.sort(StringUtils.compare);
        assertCompletion(x, v2, c);
    }

    private function assertCallCompletion(x:String, v:CCompletion,  ?c : PosInfos) {
        var index = x.indexOf('###');
        x = StringTools.replace(x, '###', '');
        var p = new Parser();
        var program = p.parseExpressionsString(x);
        for (e in p.errors.errors) trace('Error:$e');
        assertEquals('' + v, '' + p.callCompletionAt(index), c);
        return p.errors;
    }
}