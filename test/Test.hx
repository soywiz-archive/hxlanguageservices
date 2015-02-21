package;

class Test {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new TestProject());
		r.add(new TestHaxeSdk());
        r.add(new TestErrorReporting());
        r.add(new TestIndentWriter());
        r.add(new TestCallInfo());
        r.add(new TestReferences());
        r.add(new TestCompletion());
		r.add(new TestGrammar());
        r.add(new TestRenames());
        r.add(new TestDoc());
		var result = r.run();
		var code = result ? 0 : -1;
		#if js
		untyped process.exit(code);
		#else
		Sys.exit(code);
		#end
	}
}
