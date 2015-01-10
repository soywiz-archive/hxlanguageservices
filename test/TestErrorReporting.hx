import haxe.languageservices.parser.Parser;
import haxe.PosInfos;
import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.parser.Expr.ErrorDef;
import haxe.unit.TestCase;

class TestErrorReporting extends TestCase {

    public function testErrors() {
        assertParserErrors(
            'var z = {a:1};var sum=0;for (item in [z,z,z]) sum += item.a; sum;',
            []
        );
        assertParserErrors(
            'var z = {a:1};var sum=0;for (item in [z,z,z]) sum += test2.a; sum;',
            [new Error(ErrorDef.EUnknownVariable('Can\'t find "test2"'), 53, 57)]
        );

        assertParserErrors(
            'function test(a:Int, b:Float, c) { return a + b + c; }',
            []
        );

        assertParserErrors(
            'function test(a:Int, b:Float, c:Bool) { return a + b + c; }',
            [new Error(ErrorDef.EInvalidOp('Unsupported op2 Float + Bool'), 47, 55)]
        );

        assertParserErrors(
            'var a = true; var b = 1; var z = a + b;',
            [new Error(ErrorDef.EInvalidOp('Unsupported op2 Bool + Int'), 33, 37)]
        );
    }

    private function assertParserErrors(x:String, v:Dynamic,  ?c : PosInfos) {
        var p = new Parser();
        var program = p.parseExpressionsString(x);
        assertEquals(v.toString(), p.errors.errors.toString(), c);
        return p.errors;
    }
}