package ;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;
import haxe.languageservices.type.HaxeDoc;

using StringTools;

class TestDoc extends HLSTestCase {
    public function new() { super(); }

    public function test1() {
        var doc = new HaxeDoc([
            '     * Small description',
            '  *  ',
            '  * @param  a  Hello',
            '  * @param b    World   ',
            '  * @param   c Again'
        ].join('\n'));
        assertEqualsString('Small description', doc.heading);
        assertEquals(3, doc.params.length);
        assertEqualsString('Doc(0,a:Hello)', doc.params[0]);
        assertEqualsString('Doc(1,b:World)', doc.params[1]);
        assertEqualsString('Doc(2,c:Again)', doc.params[2]);
    }
    
    private function getCompCall(text:String):CompCall {
        var index = text.indexOf('###');
        text = text.replace('###', '');
        var hls = new HaxeLanguageServices(new MemoryVfs().set('live.hx', text));
        hls.updateHaxeFile('live.hx');
        return hls.getCallInfoAt('live.hx', index);
    }

    public function test2() {
        assertEquals('Test1', getCompCall('class Test { /** Test1 */ function test1() { this.test1(###); } } ').func.doc.heading);
        assertEquals('Doc(0,a:hello)', getCompCall('class Test { /** * Test1\n* @param a hello */ function test1(a:Int) { this.test1(###10); } } ').func.doc.getParamByName('a').toString());
    }
}
