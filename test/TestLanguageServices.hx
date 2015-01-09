import haxe.languageservices.HaxeLanguageServices;
import haxe.unit.TestCase;

class TestLanguageServices extends TestCase {
    public function test1() {
        var services = new HaxeLanguageServices(new LambdaHaxeFileProvider(function(path:String) {
            return 'var z = 1;';
        }));

        services.updateFile('test.hx');
        var completions = services.getCompletionAt('test.hx', 10);
        assertEquals('false:Bool,null:Dynamic,true:Bool,z:Int', completions.toString());
    }
}