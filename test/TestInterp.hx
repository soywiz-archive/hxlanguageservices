import haxe.languageservices.parser.Interp;
import haxe.languageservices.parser.Parser;
import haxe.PosInfos;
class TestInterp extends haxe.unit.TestCase {
    public function testExec() {
        assertExec("0",0);
        assertExec("0xFF", 255);
        assertExec("0xBFFFFFFF",0xBFFFFFFF);
        assertExec("0x7FFFFFFF", 0x7FFFFFFF);
        assertExec("-123",-123);
        assertExec("- 123",-123);
        assertExec("1.546",1.546);
        assertExec(".545",.545);
        assertExec("'bla'","bla");
        assertExec("null",null);
        assertExec("true",true);
        assertExec("false",false);
        assertExec("1 == 2",false);
        assertExec("1.3 == 1.3",true);
        assertExec("5 > 3",true);
        assertExec("0 < 0",false);
        assertExec("-1 <= -1",true);
        assertExec("1 + 2",3);
        assertExec("~545",-546);
        assertExec("'abc' + 55","abc55");
        assertExec("'abc' + 'de'","abcde");
        assertExec("-1 + 2",1);
        assertExec("1 / 5",0.2);
        assertExec("3 * 2 + 5",11);
        assertExec("3 * (2 + 5)",21);
        assertExec("3 * 2 // + 5 \n + 6",12);
        assertExec("3 /"+"* 2\n *"+"/ + 5",8);
        assertExec("[55,66,77][1]",66);
        assertExec("var a = [55]; a[0] *= 2; a[0]",110);
/*
		assertExec("x",55,{ x : 55 });
		assertExec("var y = 33; y",33);
		assertExec("{ 1; 2; 3; }",3);
		assertExec("{ var x = 0; } x",55,{ x : 55 });
		assertExec("o.val",55,{ o : { val : 55 } });
		assertExec("o.val",null,{ o : {} });
		assertExec("var a = 1; a++",1);
		assertExec("var a = 1; a++; a",2);
		assertExec("var a = 1; ++a",2);
		assertExec("var a = 1; a *= 3",3);
		assertExec("a = b = 3; a + b",6);
		assertExec("add(1,2)",3,{ add : function(x,y) return x + y });
		assertExec("a.push(5); a.pop() + a.pop()",8,{ a : [3] });
		assertExec("if( true ) 1 else 2",1);
		assertExec("if( false ) 1 else 2",2);
		assertExec("var t = 0; for( x in [1,2,3] ) t += x; t",6);
		assertExec("var a = new Array(); for( x in 0...5 ) a[x] = x; a.join('-')","0-1-2-3-4");
		assertExec("(function(a,b) return a + b)(4,5)",9);
		assertExec("var y = 0; var add = function(a) y += a; add(5); add(3); y", 8);
		assertExec("var a = [1,[2,[3,[4,null]]]]; var t = 0; while( a != null ) { t += a[0]; a = a[1]; }; t",10);
		assertExec("var t = 0; for( x in 1...10 ) t += x; t", 45);
		assertExec("var t = 0; for( x in new IntIterator(1,10) ) t +=x; t", 45);
		assertExec("var x = 1; try { var x = 66; throw 789; } catch( e : Dynamic ) e + x",790);
		assertExec("var x = 1; var f = function(x) throw x; try f(55) catch( e : Dynamic ) e + x",56);
		assertExec("var i=2; if( true ) --i; i",1);
		assertExec("var i=0; if( i++ > 0 ) i=3; i",1);
		assertExec("var a = 5/2; a",2.5);
		assertExec("{ x = 3; x; }", 3);
		assertExec("{ x : 3, y : {} }.x", 3);
		assertExec("function bug(){ \n }\nbug().x", null);
		assertExec("1 + 2 == 3", true);
		assertExec("-2 == 3 - 5", true);
		*/
    }

    private function assertExec(x,v:Dynamic,?vars : Dynamic,  ?c : PosInfos) {
        var p = new Parser();
        var program = p.parseExpressionsString(x);
        for (e in p.errors.errors) trace('Error:$e');
        var interp = new Interp();
        if( vars != null )
            for( v in Reflect.fields(vars) )
                interp.variables.set(v,Reflect.field(vars,v));
        var ret : Dynamic = interp.execute(program);
        assertEquals(v, ret, c);
    }
}
