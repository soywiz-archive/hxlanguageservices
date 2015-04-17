package ;
import haxe.languageservices.sdk.HaxeLibrary;
import haxe.languageservices.sdk.HaxeSdk;
import haxe.unit.TestCase;
import haxe.languageservices.util.LocalVfs;

class TestHaxeSdk extends HLSTestCase {
    public function testHaxeVersion() {
        var sdk = new HaxeSdk(new LocalVfs(), 'testassets/fakehaxesdk');
        var sdkVersion = sdk.getVersion();
        assertEquals('3.1.3', sdkVersion);
        var libraries = sdk.libraries;
        assertEquals("{cairo => HaxeLibrary(cairo), nme => HaxeLibrary(nme), }", '' + libraries);
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
