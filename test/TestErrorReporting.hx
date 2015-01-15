import haxe.PosInfos;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;
import haxe.unit.TestCase;

class TestErrorReporting extends TestCase {
    private function assertProgramErrors(prg:String, errors:Dynamic, ?p:PosInfos) {
        var live = 'live.hx';
        var vfs = new MemoryVfs().set(live, prg);
        var services = new HaxeLanguageServices(vfs);
        services.updateHaxeFile(live);
        assertEquals('' + errors, '' + services.getErrors(live), p);
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
}