import haxe.languageservices.sdk.HaxeSdk;
import haxe.languageservices.util.FileSystem2;
import haxe.languageservices.project.Hxml;
import haxe.unit.TestCase;

class TestHxml extends TestCase {

    public function test1() {
        var testassets = new FileSystem2().access('testassets');
        var sdk = new HaxeSdk(testassets, 'fakehaxesdk');
        
        var hxml = new Hxml(sdk, 'testproject/sample.hxml');
        assertEquals(['testproject/src', 'testproject/test', 'fakehaxesdk/lib/cairo/0,0,2/src'].toString(), hxml.getClassPaths().toString());
        assertEquals(['haxe3', 'js', 'test1'].toString(), hxml.getDefines().toString());
    }
}