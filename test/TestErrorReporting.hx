import haxe.PosInfos;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;
import haxe.unit.TestCase;

class TestErrorReporting extends HLSTestCase {
    private function assertProgramErrors(prg:String, errors:Dynamic, ?p:PosInfos) {
        var live = 'live.hx';
        var vfs = new MemoryVfs().set(live, prg);
        var services = new HaxeLanguageServices(vfs);
        services.updateHaxeFile(live);
        assertEquals('' + errors, '' + services.getErrors(live), p);
    }

    private function assertMethodErrors(body:String, errors:Dynamic, ?p:PosInfos) {
        assertProgramErrors('class A { function a() { $body }}', errors, p);
    }

    public function testSimpleProgramErrors() {
        assertProgramErrors('class T {}', []);
        assertProgramErrors('class T extends z {}', ['8:18:type z not defined']);
        assertProgramErrors('class z {}', '[6:7:Type name should start with an uppercase letter]');
        assertProgramErrors('class Z { }  class T extends Z {}', []);
        assertProgramErrors('package A; package B;', '[8:9:package should be lowercase,11:21:Package should be first element in the file]');
        assertProgramErrors('class A { public function test() { } }', []);
        assertProgramErrors('class A { function test():int { } }', '[26:29:Type name should start with an uppercase letter]');
        assertProgramErrors('class A { function test(a,b,c) { } }', []);
        assertProgramErrors('class A { function test(a:Int) { } }', []);
        //assertProgramErrors('class A { function test(a:int, b:Int, c:int) { } }', []);
    }

    public function testInterfaceImplementations() {
        assertProgramErrors('class A implements B { }', '[8:21:type B not defined]');
        assertProgramErrors('interface B {} class A implements B { }', '[]');
        assertProgramErrors('interface B { function a() { } } class A implements B { }', '[33:57:member a not implemented]');
        assertProgramErrors('interface B { } class A implements B { function a() { } }', '[]');
    }

    public function testInheritanceChecks() {
        assertProgramErrors('class B { } class A extends B { }', '[]');
        assertProgramErrors('class B { } class A extends B { function a() { } }', '[]');
        assertProgramErrors('class B { } class A extends B { override function a() { } }', '[32:57:member a not overriding anything]');
        assertProgramErrors('class B { function a() { } } class A extends B { override function a() { } }', '[]');
        assertProgramErrors('class B { function a() { } } class A extends B { function a() { } }', '[49:65:member a must override]');
    }

    public function testComments() {
        assertProgramErrors('//', []);
        assertProgramErrors('class //\nTest {}', []);
        assertProgramErrors('class Test /* a */ {}', []);
        assertProgramErrors('class Test {} //', []);
        //assertProgramErrors('class //Test {}', []);
    }

    public function testMethodCalling() {
        assertProgramErrors('class Test { public function test(a) { test(1); } }', []);
    }

    public function testMethodBinop() {
        assertProgramErrors('class Test { public function test(a) { 1+2+3; } }', []);
    }

    public function testMethodChecks() {
        assertMethodErrors('var a = 1;', '[]');
        assertMethodErrors('var a:bool;', '[31:35:Type name should start with an uppercase letter]');
        assertMethodErrors('var a = 1; if (a) 1; else 2;', '[40:41:If condition must be Bool but was Int]');
        assertMethodErrors('var a = true; if (a) 1; else 2;', '[]');
        //assertMethodErrors('var a:Bool = 1;', '...');
    }

    public function testIfCheck() {
        assertMethodErrors('if (true) 1; else 2;', '[]');
        assertMethodErrors('if (1) 1; else 2;', '[29:30:If condition must be Bool but was Int]');
    }

    public function testCallCount() {
        assertProgramErrors('class A { function b(a, b, c) { } function a() { b(1,2,3); } }', '[]');
        assertProgramErrors('class A { function b(a, b, c) { } function a() { b(); } }', '[49:50:Trying to call function with 0 arguments but required 3]');
        assertProgramErrors('class A { function b(a, b, c) { } function a() { b(1,2); } }', '[51:54:Trying to call function with 2 arguments but required 3]');
        assertProgramErrors('class A { function b(a, b, c) { } function a() { b(1,2,3,4); } }', '[51:58:Trying to call function with 4 arguments but required 3]');
    }

    public function testDuplicateDeclaration() {
        assertProgramErrors('class A { function a() { } function a() { } }', '[36:37:Duplicate class field declaration : a]');
        assertProgramErrors('class A { var a; function a() { } }', '[26:27:Duplicate class field declaration : a]');
    }
}