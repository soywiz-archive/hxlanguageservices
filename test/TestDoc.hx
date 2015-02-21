package ;
import haxe.languageservices.type.HaxeDoc;
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
}
