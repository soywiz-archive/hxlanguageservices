package;

class Test {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new TestInterp());
		r.add(new TestErrorReporting());
		r.add(new TestHxml());
		r.add(new TestLanguageServices());
		r.add(new TestCompletion());
		r.run();
	}
}
