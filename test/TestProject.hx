import haxe.languageservices.util.Vfs;
import haxe.languageservices.project.LimeXmlHaxeProject;
import haxe.languageservices.sdk.HaxeSdk;
import haxe.languageservices.util.FileSystem2;
import haxe.languageservices.project.HxmlHaxeProject;
import haxe.unit.TestCase;

class TestProject extends TestCase {
    private var testassets:Vfs;
    private var sdk:HaxeSdk;
    
    public function new() {
        super();
        testassets = new FileSystem2().access('testassets');
        sdk = new HaxeSdk(testassets, 'fakehaxesdk');
    }

    public function testHxml() {
        var project = new HxmlHaxeProject(sdk, 'testproject/sample.hxml');
        project.setBaseDefines(['demo']);
        assertEquals(['testproject/src', 'testproject/test', 'fakehaxesdk/lib/cairo/0,0,2/src'].toString(), project.getClassPaths().toString());
        assertEquals(['demo', 'haxe3', 'js', 'test1'].toString(), project.getDefines().toString());
    }

    public function testLime() {
        var project = new LimeXmlHaxeProject(sdk, 'testproject/limeproject.xml');
        project.setBaseDefines(['cpp']);
        assertEquals(['testproject/src', 'testproject/test', 'fakehaxesdk/lib/cairo/0,0,2/src'].toString(), project.getClassPaths().toString());
        assertEquals(['cpp', 'haxe3', 'include1', 'test1', 'test1b', 'test1c'].toString(), project.getDefines().toString());
    }
}