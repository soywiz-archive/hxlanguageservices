package;

class Test {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new TestProject());
		r.add(new TestLanguageServices());
		r.add(new TestGrammar2());
		r.run();
	}
}
