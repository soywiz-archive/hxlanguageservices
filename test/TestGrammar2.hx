package ;
import haxe.languageservices.grammar.HaxeGrammar;
import haxe.languageservices.grammar.Grammar.Reader;
import haxe.unit.TestCase;
class TestGrammar2 extends TestCase {
    public function testGrammar() {
        var hg = new HaxeGrammar();
        assertEquals(
            'RMatchedValue(NConstList([NConst(CInt(1))@1:2,NConst(CInt(2))@4:5,NConst(CInt(3))@7:8,NConst(CInt(4))@10:11])@1:11)',
            '' + hg.parse(hg.ints, new Reader(" 1, 2, 3, 4"))
        );
        assertEquals(
            'RMatchedValue(NIdList([NId(a)@0:1,NId(b)@2:3,NId(c)@4:5,NId(Test)@6:10])@0:10)',
            '' + hg.parse(hg.fqName, new Reader("a.b.c.Test"))
        );
        assertEquals(
            'RMatchedValue(NPackage(NIdList([NId(a)@8:9,NId(b)@10:11,NId(c)@12:13])@8:13)@0:14)',
            '' + hg.parse(hg.packageDesc, new Reader("package a.b.c;"))
        );
        assertEquals(
            'RMatchedValue(NIf(NConst(CInt(1))@4:5,NId(test)@7:11)@0:11)',
            '' + hg.parse(hg.expr, new Reader("if (1) test"))
        );
    }
}
