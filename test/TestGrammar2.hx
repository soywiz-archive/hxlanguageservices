package ;
import haxe.languageservices.grammar.HaxeGrammar;
import haxe.languageservices.grammar.Grammar;
import haxe.languageservices.grammar.Grammar.Reader;
import haxe.unit.TestCase;
class TestGrammar2 extends TestCase {
    var hg = new HaxeGrammar();

    public function testGrammar() {
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
            '' + hg.parse(hg.packageDecl, new Reader("package a.b.c;"))
        );
        assertEquals(
            'RMatchedValue(NIf(NConst(CInt(1))@4:5,NId(test)@7:11,null)@0:11)',
            '' + hg.parse(hg.expr, new Reader("if (1) test"))
        );
        assertEquals(
            'RMatchedValue(NIf(NConst(CInt(1))@4:5,NId(test)@7:11,NId(demo)@17:21@12:21)@0:21)',
            '' + hg.parse(hg.expr, new Reader("if (1) test else demo"))
        );
        assertEquals(
            'RMatchedValue(NFor(NId(a)@5:6,NArray([NList([NConst(CInt(1))@11:12,NConst(CInt(2))@13:14,NConst(CInt(3))@15:16])@11:16])@10:17,NId(a)@19:20)@0:20)',
            '' + hg.parse(hg.expr, new Reader("for (a in [1,2,3]) a"))
        );

        assertEquals(
            'RMatchedValue(NBlock([NList([NConst(CInt(1))@1:2,NConst(CInt(2))@4:5])@1:6])@0:7)',
            '' + hg.parse(hg.expr, new Reader("{1; 2;}"))
        );


    }

    public function testProgram() {
        assertEquals(
            'RMatchedValue(NList([NClass(NId(Test)@6:10,null,NList([NMember(NList([])@13:20,NVar(NId(a)@24:25,null,null)@20:26)@13:26,NMember(NList([])@27:34,NVar(NId(b)@38:39,null,null)@34:40)@27:40])@13:41)@0:42])@0:42)',
            '' + hg.parse(hg.program, new Reader("class Test { static var a; public var b; }"))
        );

        assertEquals(
            'RMatchedValue(NList([NPackage(NIdList([NId(a)@8:9,NId(b)@10:11,NId(c)@12:13])@8:13)@0:14,NImport(NIdList([NId(a)@22:23,NId(b)@24:25,NId(c)@26:27])@22:27)@15:28,NClass(NId(Z)@35:36,null,NList([])@38:38)@29:39])@0:39)',
            '' + hg.parse(hg.program, new Reader("package a.b.c; import a.b.c; class Z {}"))
        );
    }

    public function testExpressions() {
        assertEquals(
            'RMatchedValue(NAccessList(NId(a)@0:1,NList([NAccess(NId(b)@2:3)@1:3,NAccess(NConst(CInt(777))@4:7)@3:8])@1:8)@0:8)',
            '' + hg.parse(hg.expr, new Reader("a.b[777]"))
        );
        assertEquals(
            'RMatchedValue(NAccessList(NId(a)@0:1,NList([NAccess(NId(b)@2:3)@1:3,NAccess(NConst(CInt(777))@4:7)@3:8,NCall(NList([NConst(CInt(1))@9:10,NConst(CInt(2))@12:13])@9:13)@8:14])@1:14)@0:14)',
            '' + hg.parse(hg.expr, new Reader("a.b[777](1, 2)"))
        );
        assertEquals(
            'RMatchedValue(NNew(NId(Test)@4:8,NCall(NList([NConst(CInt(1))@9:10,NConst(CInt(2))@12:13,NConst(CInt(3))@15:16])@9:16)@8:17)@0:17)',
            '' + hg.parse(hg.expr, new Reader("new Test(1, 2, 3)"))
        );
        assertEquals(
            'RMatchedValue(NVar(NId(z)@4:5,[NId(Int)@6:9]@5:9,NConst(CInt(1))@12:13@10:13)@0:14)',
            '' + hg.parse(hg.expr, new Reader("var z:Int = 1;"))
        );
        assertEquals(
            'RMatchedValue(NVar(NId(z)@4:5,[NList([NList([NIdWithType(NId(a)@7:8,[NId(Int)@9:12]@8:12)@7:12])@7:12])@6:13]@5:13,NObject([NList([NObjectItem(NId(a)@17:18,NConst(CInt(1))@19:20)@17:20])@17:20])@16:21@14:21)@0:22)',
            '' + hg.parse(hg.expr, new Reader("var z:{a:Int} = {a:1};"))
        );
    }
}
