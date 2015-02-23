package ;
import haxe.languageservices.completion.CompletionProvider;
import haxe.Json;
import haxe.languageservices.completion.LocalScope;
import haxe.languageservices.grammar.GrammarTerm;
import haxe.languageservices.grammar.GrammarResult;
import haxe.languageservices.node.NodeTools;
import haxe.languageservices.node.Reader;
import haxe.languageservices.error.HaxeErrors;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.type.HaxeTypes;
import haxe.languageservices.grammar.HaxeTypeBuilder;
import haxe.languageservices.grammar.HaxeTypeChecker;
import haxe.PosInfos;
import haxe.languageservices.grammar.HaxeGrammar;
import haxe.languageservices.grammar.Grammar;
import haxe.unit.TestCase;

using StringTools;

class TestGrammar extends HLSTestCase {
    var hg = new HaxeGrammar();

    // Unstable tests that won't provide much value and will cost too much to maintain at this point at least
    /*
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
            'RMatchedValue(NBlock([NList([NList([NConst(CInt(1))@1:2])@1:3,NList([NConst(CInt(2))@4:5])@4:6])@1:6])@0:7)',
            '' + hg.parse(hg.expr, new Reader("{1; 2;}"))
        );
    }
    */

    public function testExpressions() {
        function assertExpr(str, expected, ?p) assertEqualsString(expected, hg.parse(hg.expr, new Reader(str)), p);
        function assertStm(str, expected, ?p) assertEqualsString(expected, hg.parse(hg.stm, new Reader(str)), p);
        function assertProgram(str, expected, ?p) assertEqualsString(expected, hg.parse(hg.program, new Reader(str)), p);

        //trace(NodeTools.dump(hg.parseStringNode(hg.expr, '7 + 3 * 2', 'test.hx')).toString());
        //trace(NodeTools.dump(hg.parseStringNode(hg.expr, '7 * 3 + 2', 'test.hx')).toString());

        assertExpr("7 + 9", 'RMatchedValue(NBinOp(NConst(CInt(7))@0:1,+,NConst(CInt(9))@4:5)@0:5)');
        assertExpr("7 * 9 + 2", 'RMatchedValue(NBinOp(NBinOp(NConst(CInt(7))@0:1,*,NConst(CInt(9))@4:5)@0:9,+,NConst(CInt(2))@8:9)@0:9)');
        assertExpr("7 + 9 * 2", 'RMatchedValue(NBinOp(NConst(CInt(7))@0:1,+,NBinOp(NConst(CInt(9))@4:5,*,NConst(CInt(2))@8:9)@4:9)@0:9)');
        //assertProgram('class A { function a() { 1 + 2; } }', '');
        /*
        assertExpr("a.b[777]", 'RMatchedValue(NAccessList(NId(a)@0:1,NList([NAccess(NId(b)@2:3)@1:3,NAccess(NConst(CInt(777))@4:7)@3:8])@1:8)@0:8)');
        assertExpr("a.b[777](1, 2)", 'RMatchedValue(NAccessList(NId(a)@0:1,NList([NAccess(NId(b)@2:3)@1:3,NAccess(NConst(CInt(777))@4:7)@3:8,NCall(NList([NConst(CInt(1))@9:10,NConst(CInt(2))@12:13])@9:13)@8:14])@1:14)@0:14)');
        assertExpr("new Test(1, 2, 3)", 'RMatchedValue(NNew(NId(Test)@4:8,NCall(NList([NConst(CInt(1))@9:10,NConst(CInt(2))@12:13,NConst(CInt(3))@15:16])@9:16)@8:17)@0:17)');
        assertStm("var z:Int = 1;", 'RMatchedValue(NVar(NId(z)@4:5,[NId(Int)@6:9]@5:9,NConst(CInt(1))@12:13@10:13)@0:14)');
        assertStm("var z:{a:Int} = {a:1};", 'RMatchedValue(NVar(NId(z)@4:5,[NList([NList([NIdWithType(NId(a)@7:8,[NId(Int)@9:12]@8:12)@7:12])@7:12])@6:13]@5:13,NObject([NList([NObjectItem(NId(a)@17:18,NConst(CInt(1))@19:20)@17:20])@17:20])@16:21@14:21)@0:22)');
        assertExpr("7 + 9 + 3", 'RMatchedValue(NAccessList(NConst(CInt(7))@0:1,NList([NBinOpPart(NAccessList(NConst(CInt(9))@4:5,NList([NBinOpPart(NConst(CInt(3))@8:9,null)@6:9])@6:9)@4:9,null)@2:9])@2:9)@0:9)');
        assertExpr("-7", 'RMatchedValue(NUnary(NOp(-)@0:1,NConst(CInt(7))@1:2)@0:2)');
        assertExpr("-(test)", 'RMatchedValue(NUnary(NOp(-)@0:1,NId(test)@2:6@1:7)@0:7)');
        */
    }
    

/*
    public function testProgram() {
        assertEqualsString(
            'RMatchedValue(NFile([NClass(NId(Test)@6:10,null,NList([])@11:11,NList([NMember(NList([NKeyword(static)@13:19])@13:20,NVar(NId(a)@24:25,null,null)@20:26)@13:26,NMember(NList([NKeyword(public)@27:33])@27:34,NVar(NId(b)@38:39,null,null)@34:40)@27:40])@13:41)@0:42])@0:42)',
            hg.parse(hg.program, new Reader("class Test { static var a; public var b; }"))
        );

        assertEqualsString(
            'RMatchedValue(NFile([NPackage(NIdList([NId(a)@8:9,NId(b)@10:11,NId(c)@12:13])@8:13)@0:14,NImport(NIdList([NId(a)@22:23,NId(b)@24:25,NId(c)@26:27])@22:27)@15:28,NClass(NId(Z)@35:36,null,NList([])@37:37,NList([])@38:38)@29:39])@0:39)',
            hg.parse(hg.program, new Reader("package a.b.c; import a.b.c; class Z {}"))
        );

        assertEqualsString(
            'RMatchedValue(NFile([NClass(NId(A)@6:7,null,NList([NExtends(NIdList([NId(B)@16:17])@16:18,null)@8:18,NImplements(NIdList([NId(C)@29:30])@29:31,null)@18:31])@8:31,NList([])@33:33)@0:34])@0:34)',
            hg.parse(hg.program, new Reader("class A extends B implements C { }"))
        );
    }
    */
    
    public function testSem() {
        function assert(program:String, checker: HaxeTypeBuilder -> Void) {
            var sem = new HaxeTypeBuilder(new HaxeTypes(), new HaxeErrors());
            sem.processResult(hg.parseString(hg.program, program, 'program.hx'));
            checker(sem);
        }
        assert(
            'package p.T; import a; class Test { var z; } import b; package c;',
            function(sem:HaxeTypeBuilder) {
                assertEqualsString(['p.T'], sem.types.getLeafPackageNames());
                assertEqualsString([
                    '8:11:package should be lowercase',
                    '45:54:Import should appear before any type decl',
                    '55:65:Package should be first element in the file'
                ], sem.errors.errors);
                assertEqualsString('Type("p.T.Test", [Field(z)])', sem.types.rootPackage.accessType('p.T.Test').getName());
                //assertEqualsString('[Dynamic,Bool,Int,Float,Array,p.T.Test]', [for (t in sem.types.getAllTypes()) t.fqName]);
                var tc = new HaxeTypeChecker(sem.types, new HaxeErrors());
                tc.checkType(sem.types.rootPackage.accessType('p.T.Test'));
                assertEqualsString('[]', tc.errors.errors);
            }
        );
    }

    public function testAutocompletion() {
        function assert(str:String, callback: HaxeTypeBuilder -> ZNode -> CompletionProvider -> Void) {
            var types = new HaxeTypes();
            var completionIndex = str.indexOf('###');
            str = str.replace('###', '');
            var result = hg.parseString(hg.stm, str, 'program.hx');
            switch (result) {
                case GrammarResult.RMatchedValue(value):
                    var typeBuilder = new HaxeTypeBuilder(types, new HaxeErrors());
                    var node:ZNode = cast(value);
                    typeBuilder.processMethodBody(node, new LocalScope());
                    //var cc = completion.processCompletion(node);
                    callback(typeBuilder, node, node.locateIndex(completionIndex).getCompletion());
                default:
                    trace(result);
                    trace(str);
                    throw 'Error';
            }

        }

        assert('{var z = 10;###}', function(typeBuilder:HaxeTypeBuilder, node:ZNode, scope:CompletionProvider) {
            assertEqualsString('[z]', [for (l in scope.getEntries()) l.getName()]);
            assertEqualsString('Int = 10', scope.getEntryByName('z').getResult());
        });

        /*
        assert('{var z = 10; -z; z;###}', function(typeBuilder:HaxeTypeBuilder, node:ZNode, scope:CompletionScope) {
            var local = scope.getLocal('z');
            assertEqualsString('5:6', local.pos);
            assertEqualsString('[NId(z)@14:15,NId(z)@17:18]', local.usages);
        });
        */

        assert('if (z) true else false', function(typeBuilder:HaxeTypeBuilder, node:ZNode, scope:CompletionProvider) {
            assertEqualsString('Bool', typeBuilder.processExprValue(node));
        });
    }

    public function testRecovery() {
        function assert(term:GrammarTerm, program:String, expectedError:String, ?p:PosInfos) {
            var errors = new HaxeErrors();
            var result = hg.parseString(term, program, 'program.hx', errors);
            switch (result) {
                case GrammarResult.RMatched | GrammarResult.RUnmatched(_):
                    trace(result);
                    trace(errors);
                    assertTrue(false, p);
                case GrammarResult.RMatchedValue(v):
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
        assert(hg.program, 'package a.b.c package d', '[13:13:expected ";",23:23:expected ";"]');
        assert(hg.program, 'class Test', '[10:10:expected "{"]');
        assert(hg.program, 'class Test {', '[12:12:expected "}"]');
        //trace(hg.parseStringNode(hg.program, 'class Test {', 'file.hx'));
        assert(hg.program, 'class Test { }', '[]');
        assert(hg.program, 'class Test extends { public var test; }', '[11:11:expected identifier]');
    }

    public function testLocateNodeByIndex() {
        var node:ZNode = hg.parseStringNode(hg.stm, 'if (test) 1 else 2', 'program.hx');
        assertEqualsString('NId(test)@4:8', node.locateIndex(5));
        assertEqualsString('NConst(CInt(1))@10:11', node.locateIndex(10));
    }

    public function testString() {
        assertEqualsString('NConst(CString(hello world))@0:13', hg.parseStringNode(hg.expr, '"hello world"', 'program.hx'));
    }

    public function testStringDoubleQuotes() {
        assertEqualsString('NConst(CString(hello \" world))@0:16', hg.parseStringNode(hg.expr, '"hello \\" world"', 'program.hx'));
        assertEqualsString('NConst(CString(hello \n world))@0:16', hg.parseStringNode(hg.expr, '"hello \\n world"', 'program.hx'));
        assertEqualsString('NConst(CString(hello \x50 world))@0:18', hg.parseStringNode(hg.expr, '"hello \\x50 world"', 'program.hx'));
        assertEqualsString('NConst(CString(hello \u3042 world))@0:20', hg.parseStringNode(hg.expr, '"hello \\u3042 world"', 'program.hx'));
    }

    public function testStringSingleQuotes() {
        assertEqualsString('NStringSq(NStringParts([NConst(CString(hello))@1:6])@1:6)@0:7', hg.parseStringNode(hg.expr, "'hello'", 'program.hx'));
        assertEqualsString('NStringSq(NStringParts([NConst(CString(he\nllo))@1:7])@1:7)@0:8', hg.parseStringNode(hg.expr, "'he\nllo'", 'program.hx'));
        assertEqualsString('NStringSq(NStringParts([NConst(CString(hello ))@1:7,NStringSqDollarPart(NId(a)@8:9)@7:9])@1:9)@0:10', hg.parseStringNode(hg.expr, "'hello $a'", 'program.hx'));
        assertEqualsString('NStringSq(NStringParts([NConst(CString(hello ))@1:7,NStringSqDollarPart(NBinOp(NConst(CInt(1))@9:10,+,NConst(CInt(2))@13:14)@9:14)@7:15])@1:15)@0:16', hg.parseStringNode(hg.expr, "'hello ${1 + 2}'", 'program.hx'));
        assertEqualsString('NStringSq(NStringParts([NStringSqDollarPart(NId(a)@2:3)@1:3,NConst(CString( ))@3:4,NStringSqDollarPart(NId(b)@5:6)@4:6])@1:6)@0:7', hg.parseStringNode(hg.expr, "'$a $b'", 'program.hx'));
    }
    
    private function processNodeStm(node:ZNode):ZNode {
        var typeBuilder = new HaxeTypeBuilder(new HaxeTypes(), new HaxeErrors());
        typeBuilder.processMethodBody(node, new LocalScope());
        return node;
    }

    public function testCompletionLocateNode() {
        var node:ZNode = processNodeStm(hg.parseStringNode(hg.stm, 'if (test) demo else 2', 'program.hx'));
        assertEqualsString(null, node.getIdentifierAt(0));
        assertEqualsString({ pos: '4:8', name: 'test' }, node.getIdentifierAt(5));
        assertEqualsString({ pos: '10:14', name: 'demo' }, node.getIdentifierAt(12));
        assertEqualsString(null, node.getLocalAt(12));
    }

    public function testCompletionLocateNode2() {
        var node:ZNode = processNodeStm(hg.parseStringNode(hg.stm, 'var test = test;', 'program.hx'));
        assertEqualsString({ pos: '4:8', name: 'test' }, node.getIdentifierAt(5));
        assertEqualsString({ pos: '11:15', name: 'test' }, node.getIdentifierAt(12));
        assertEqualsString('test', node.getIdentifierAt(12).pos.text);
        assertEqualsString('Local(test:Dynamic)', node.getLocalAt(5));
        assertEqualsString('Local(test:Dynamic)', node.getLocalAt(12));
        assertEqualsString('[test:Declaration@4:8,test:Read@11:15]', node.getLocalAt(5).getReferences().usages);
    }

    public function testCompletionLocateNode3() {
        var node:ZNode = processNodeStm(hg.parseStringNode(hg.stm, 'for (it in [1,2,3]) var test = it;', 'program.hx'));
        assertEqualsString({pos : '5:7', name : 'it'}, node.getIdentifierAt(6));
        assertEqualsString({pos : '31:33', name : 'it'}, node.getIdentifierAt(32));
        //assertEqualsString('', scope.getLocalAt(6));
        //assertEqualsString('', scope.getLocalAt(32));
    }

    public function testNewCompletion() {
        var node:ZNode = hg.parseStringNode(hg.stm, '{ var z = 7; { var m = z * z * 2; } }', 'program.hx');
        var htb = new HaxeTypeBuilder(new HaxeTypes(), new HaxeErrors());
        var cp = htb.processMethodBody(node, new LocalScope());
        assertEqualsString('[z:Declaration@6:7,z:Read@23:24,z:Read@27:28]', node.locateIndex(16).getCompletion().getEntryByName('z').getReferences().usages);
    }

    public function testNewCompletion2() {
        var node:ZNode = hg.parseStringNode(hg.stm, '{ var z = [1,2,3]; }', 'program.hx');
        var htb = new HaxeTypeBuilder(new HaxeTypes(), new HaxeErrors());
        var cp = htb.processMethodBody(node, new LocalScope());
        assertEqualsString('Array<Int>', node.locateIndex(5).getCompletion().getEntryByName('z').getResult());
    }

    public function testNewCompletion3() {
        var str = '{ var z = true; if (z) { var m = 7; z = false; m.||| } else { z = true; } }';
        var index = str.indexOf('|||');
        var node:ZNode = hg.parseStringNode(hg.stm, str.replace('|||', ''), 'program.hx');
        var htb = new HaxeTypeBuilder(new HaxeTypes(), new HaxeErrors());
        var cp = htb.processMethodBody(node, new LocalScope());

        //trace(node.locateIndex(index));
        //assertEqualsString('Local(m:Int = 7)', node.locateIndex(index));
        assertEqualsString('Local(m:Int = 7)', node.locateIndex(29).getCompletion().getEntryByName('m'));
        assertEqualsString('Bool = true', node.locateIndex(5).getCompletion().getEntryByName('z').getResult());
    }
    
    private function doProgram(str:String):HaxeTypes {
        var node:ZNode = hg.parseStringNode(hg.program, str, 'program.hx');
        var htb = new HaxeTypeBuilder(new HaxeTypes(), new HaxeErrors());
        var cp = htb.process(node);
        return htb.types;
    }

    public function testNewCompletion4() {
        var types = doProgram('class Test { function test() { return 7; } }');
        assertEqualsString('Int = 7', types.getClass('Test').getMethod('test').func.getReturn());
    }
    
    public function testNewCompletion5() {
        var types = doProgram('class Test { function test() { return 7; return 2; } }');
        assertEqualsString('Int', types.getClass('Test').getMethod('test').func.getReturn());
    }

    public function testNewCompletion6() {
        var types = doProgram('class Test { function test():Int { } }');
        assertEqualsString('Int', types.getClass('Test').getMethod('test').func.getReturn());
    }
}
