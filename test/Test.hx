package;

class Test {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new TestProject());
		r.add(new TestLanguageServices());
		r.add(new TestGrammar2());
		var result = r.run();
		var code = result ? 0 : -1;
		#if js
		untyped process.exit(code);
		#else
		Sys.exit(code);
		#end
	}
}
