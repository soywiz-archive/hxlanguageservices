package ;
import haxe.languageservices.node.Reader;
import haxe.languageservices.grammar.HaxeErrors;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.grammar.HaxeCompletion;
import haxe.languageservices.grammar.HaxeTypeChecker;
import haxe.Json;
import haxe.languageservices.grammar.HaxeTypeBuilder;
import haxe.PosInfos;
import haxe.languageservices.grammar.HaxeGrammar;
import haxe.languageservices.grammar.Grammar;
import haxe.unit.TestCase;

using StringTools;

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
        assertEqualsString(
            'RMatchedValue(NFile([NClass(NId(Test)@6:10,null,NList([])@11:11,NList([NMember(NList([])@13:20,NVar(NId(a)@24:25,null,null)@20:26)@13:26,NMember(NList([])@27:34,NVar(NId(b)@38:39,null,null)@34:40)@27:40])@13:41)@0:42])@0:42)',
            hg.parse(hg.program, new Reader("class Test { static var a; public var b; }"))
        );

        assertEqualsString(
            'RMatchedValue(NFile([NPackage(NIdList([NId(a)@8:9,NId(b)@10:11,NId(c)@12:13])@8:13)@0:14,NImport(NIdList([NId(a)@22:23,NId(b)@24:25,NId(c)@26:27])@22:27)@15:28,NClass(NId(Z)@35:36,null,NList([])@37:37,NList([])@38:38)@29:39])@0:39)',
            hg.parse(hg.program, new Reader("package a.b.c; import a.b.c; class Z {}"))
        );

        assertEqualsString(
            'RMatchedValue(NFile([NClass(NId(A)@6:7,null,NList([NExtends(NId(B)@16:17)@8:17,NImplements(NId(C)@29:30)@18:30])@8:31,NList([])@33:33)@0:34])@0:34)',
            hg.parse(hg.program, new Reader("class A extends B implements C { }"))
        );
    }
    
    public function testExpressions() {
        function assertExpr(str, expected, ?p) assertEquals(expected, '' + hg.parse(hg.expr, new Reader(str)), p);
        assertExpr("a.b[777]", 'RMatchedValue(NAccessList(NId(a)@0:1,NList([NAccess(NId(b)@2:3)@1:3,NAccess(NConst(CInt(777))@4:7)@3:8])@1:8)@0:8)');
        assertExpr("a.b[777](1, 2)", 'RMatchedValue(NAccessList(NId(a)@0:1,NList([NAccess(NId(b)@2:3)@1:3,NAccess(NConst(CInt(777))@4:7)@3:8,NCall(NList([NConst(CInt(1))@9:10,NConst(CInt(2))@12:13])@9:13)@8:14])@1:14)@0:14)');
        assertExpr("new Test(1, 2, 3)", 'RMatchedValue(NNew(NId(Test)@4:8,NCall(NList([NConst(CInt(1))@9:10,NConst(CInt(2))@12:13,NConst(CInt(3))@15:16])@9:16)@8:17)@0:17)');
        assertExpr("var z:Int = 1;", 'RMatchedValue(NVar(NId(z)@4:5,[NId(Int)@6:9]@5:9,NConst(CInt(1))@12:13@10:13)@0:14)');
        assertExpr("var z:{a:Int} = {a:1};", 'RMatchedValue(NVar(NId(z)@4:5,[NList([NList([NIdWithType(NId(a)@7:8,[NId(Int)@9:12]@8:12)@7:12])@7:12])@6:13]@5:13,NObject([NList([NObjectItem(NId(a)@17:18,NConst(CInt(1))@19:20)@17:20])@17:20])@16:21@14:21)@0:22)');
        assertExpr("7 + 9 + 3", 'RMatchedValue(NAccessList(NConst(CInt(7))@0:1,NList([NBinOpPart(NAccessList(NConst(CInt(9))@4:5,NList([NBinOpPart(NConst(CInt(3))@8:9,null)@6:9])@6:9)@4:9,null)@2:9])@2:9)@0:9)');
        assertExpr("-7", 'RMatchedValue(NUnary(NOp(-)@0:1,NConst(CInt(7))@1:2)@0:2)');
        assertExpr("-(test)", 'RMatchedValue(NUnary(NOp(-)@0:1,NId(test)@2:6@1:7)@0:7)');
    }
    
    private function assertEqualsString(a:Dynamic, b:Dynamic, ?p:PosInfos) {
        assertEquals('' + a, '' + b, p);
    }

    private function assertEqualsJson(a:Dynamic, b:Dynamic, ?p:PosInfos) {
        assertEquals(Json.stringify(a), Json.stringify(b), p);
    }

    public function testSem() {
        function assert(program:String, checker: HaxeTypeBuilder -> Void) {
            var sem = new HaxeTypeBuilder();
            sem.processResult(hg.parseString(hg.program, program, 'program.hx'));
            checker(sem);
        }
        assert(
            'package p.T; import a; class Test { var z; } import b; package c;',
            function(sem:HaxeTypeBuilder) {
                assertEqualsString(['p.T'], sem.types.getLeafPackageNames());
                assertEqualsString([
                    '8:11:package should be lowercase',
                    '45:54:import should appear before any type decl',
                    '55:65:package should be first element in the file'
                ], sem.errors);
                assertEqualsString('Type("p.T.Test", [Field(z)])', sem.types.rootPackage.accessType('p.T.Test'));
                assertEqualsString('[Dynamic,Bool,Int,Float,p.T.Test]', [for (t in sem.types.getAllTypes()) t.fqName]);
                var tc = new HaxeTypeChecker(sem.types);
                tc.checkType(sem.types.rootPackage.accessType('p.T.Test'));
                assertEqualsString('[]', tc.errors);
            }
        );
    }

    public function testAutocompletion() {
        function assert(str:String, callback: ZNode -> CompletionScope -> Void) {
            var types = new HaxeTypes();
            var completionIndex = str.indexOf('###');
            str = str.replace('###', '');
            var result = hg.parseString(hg.expr, str, 'program.hx');
            var completion = new HaxeCompletion(types);
            switch (result) {
                case Result.RMatchedValue(value):
                    var node:ZNode = cast(value);
                    var cc = completion.process(node);
                    var scope = cc.locateIndex(completionIndex);
                    callback(node, scope);
                default:
                    trace(result);
                    trace(str);
                    throw 'Error';
            }

        }

        assert('{var z = 10;###}', function(node:ZNode, scope:CompletionScope) {
            assertEqualsString('[z]', [for (l in scope.getLocals()) l.name]);
            assertEqualsString('Int', scope.getLocal('z').getType().fqName);
        });

        /*
        assert('{var z = 10; -z; z;###}', function(node:ZNode, scope:CompletionScope) {
            var local = scope.getLocal('z');
            assertEqualsString('5:6', local.pos);
            assertEqualsString('[NId(z)@14:15,NId(z)@17:18]', local.usages);
        });
        */

        assert('if (z) true else false', function(node:ZNode, scope:CompletionScope) {
            assertEqualsString('Bool', scope.getNodeType(node).fqName);
        });
    }

    public function testRecovery() {
        function assert(term:Term, program:String, expectedError:String, ?p:PosInfos) {
            var errors = new HaxeErrors();
            var result = hg.parseString(term, program, 'program.hx', errors);
            switch (result) {
                case Result.RMatched | Result.RUnmatched(_):
                    trace(result);
                    trace(errors);
                    assertTrue(false, p);
                case Result.RMatchedValue(v):
                    //trace(v);
            }
            assertEqualsString(expectedError, errors.errors, p);
        }
        /*
        var a = { a: 1};
        var b = { var a = 1; 10; }
        trace(a);
        trace(b);
        */

        //assert(hg.expr, '{ var a = 10; var c = 9 }', '[24:24:expected semicolon]');
        assert(hg.program, 'package a.b.c package d', '[14:14:expected ;,23:23:expected ;]');
        assert(hg.program, 'class Test', '[10:10:expected "{"]');
        assert(hg.program, 'class Test {', '[12:12:expected "}"]');
        //trace(hg.parseStringNode(hg.program, 'class Test {', 'file.hx'));
        assert(hg.program, 'class Test { }', '[]');
        assert(hg.program, 'class Test extends { public var test; }', '[18:18:expected identifier or "{",28:28:expected "{"]');
    }

    public function testLocateNodeByIndex() {
        var node:ZNode = hg.parseStringNode(hg.expr, 'if (test) 1 else 2', 'program.hx');
        assertEqualsString('NId(test)@4:8', node.locateIndex(5));
        assertEqualsString('NConst(CInt(1))@10:11', node.locateIndex(10));
    }

    public function testCompletionLocateNode() {
        var node:ZNode = hg.parseStringNode(hg.expr, 'if (test) demo else 2', 'program.hx');
        var scope = new HaxeCompletion(new HaxeTypes()).process(node);
        assertEqualsString(null, scope.getIdentifierAt(0));
        assertEqualsString({ pos: '4:8', name: 'test' }, scope.getIdentifierAt(5));
        assertEqualsString({ pos: '10:14', name: 'demo' }, scope.getIdentifierAt(12));
        assertEqualsString(null, scope.getLocalAt(5));
    }

    public function testCompletionLocateNode2() {
        var node:ZNode = hg.parseStringNode(hg.expr, 'var test = test;', 'program.hx');
        var scope = new HaxeCompletion(new HaxeTypes()).process(node);
        assertEqualsString(null, scope.getIdentifierAt(0));
        assertEqualsString({ pos: '4:8', name: 'test' }, scope.getIdentifierAt(5));
        assertEqualsString({ pos: '11:15', name: 'test' }, scope.getIdentifierAt(12));
        assertEqualsString('test', scope.getIdentifierAt(12).pos.text);
        assertEqualsString('test@4:8', scope.getLocalAt(5));
        assertEqualsString('test@4:8', scope.getLocalAt(12));
        assertEqualsString('[NId(test)@11:15]', scope.getLocalAt(5).usages);
    }

    public function testCompletionLocateNode3() {
        var node:ZNode = hg.parseStringNode(hg.expr, 'for (it in [1,2,3]) var test = it;', 'program.hx');
        var scope = new HaxeCompletion(new HaxeTypes()).process(node);
        assertEqualsString({pos : '5:7', name : 'it'}, scope.getIdentifierAt(6));
        assertEqualsString({pos : '31:33', name : 'it'}, scope.getIdentifierAt(32));
        //assertEqualsString('', scope.getLocalAt(6));
        //assertEqualsString('', scope.getLocalAt(32));
    }
}
