package ;
import haxe.languageservices.util.IndentWriter;
import haxe.unit.TestCase;

class TestIndentWriter extends HLSTestCase {
    public function test1() {
        var iw = new IndentWriter();
        iw.write('class {\n');
        iw.indent(function() {
            iw.write('Hello\nWorld\n');
        });
        iw.write('}');
        assertEquals('class {\n\tHello\n\tWorld\n}', iw.toString());
    }
}
