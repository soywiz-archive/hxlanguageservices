package;

class Test {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new TestProject());
		r.add(new TestHaxeSdk());
        r.add(new TestErrorReporting());
        /*
		r.add(new TestCompletion());
		r.add(new TestGrammar());
		r.add(new TestIndentWriter());
		r.add(new TestReferences());
		r.add(new TestCallInfo());
		*/
		var result = r.run();
		var code = result ? 0 : -1;
		#if js
		untyped process.exit(code);
		#else
		Sys.exit(code);
		#end
	}
}
