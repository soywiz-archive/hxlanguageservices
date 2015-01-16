package;

class Test {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new TestProject());
		r.add(new TestHaxeSdk());
		r.add(new TestCompletion());
		r.add(new TestErrorReporting());
		r.add(new TestGrammar());
		r.add(new TestIndentWriter());
		var result = r.run();
		var code = result ? 0 : -1;
		#if js
		untyped process.exit(code);
		#else
		Sys.exit(code);
		#end
	}
}
