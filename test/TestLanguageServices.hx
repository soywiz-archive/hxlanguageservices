import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.util.FileSystem2;
import haxe.Json;
import haxe.languageservices.sdk.HaxeLibrary;
import haxe.languageservices.sdk.HaxeSdk;
import haxe.languageservices.HaxeLanguageServices;
import haxe.unit.TestCase;

class TestLanguageServices extends TestCase {
    /*
    public function test1() {
        var services = new HaxeLanguageServices(new MemoryVfs().set('test.hx', 'var z = 1;'));

        services.updateHaxeScriptFile('test.hx');
        var completions = services.getCompletionAt('test.hx', 10);
        assertEquals('false:Bool,null:Dynamic,true:Bool,z:Int', completions.toString());
    }
    */

    public function testHaxeVersion() {
        var sdk = new HaxeSdk(new FileSystem2(), 'testassets/fakehaxesdk');
        var sdkVersion = sdk.getVersion();
        assertEquals('3.1.3', sdkVersion);
        var libraries = sdk.libraries;
        assertEquals("{cairo => HaxeLibrary(cairo), nme => HaxeLibrary(nme)}", '' + libraries);
        var cairo:HaxeLibrary = libraries['cairo'];
        assertEquals(true, cairo.exists);
        assertEquals(true, cairo.currentVersion.exists);
        assertEquals(false, cairo.getVersion('11,0,0').exists);
        assertEquals('HaxeLibraryVersion(cairo:0.7.0)', cairo.currentVersion.toString());
        assertEquals('MIT', cairo.currentVersion.license);
        assertEquals(['soywiz'].toString(), cairo.currentVersion.contributors.toString());
        assertEquals(['HaxeLibraryVersion(hxcpp:3.1.48)'].toString(), cairo.currentVersion.dependencies.toString());
        assertEquals(false, cairo.currentVersion.dependencies[0].exists);
        assertEquals(true, sdk.getLibrary('cairo').getVersion('0.7.0').exists);
    }
}