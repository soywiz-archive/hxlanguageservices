package ;

import haxe.languageservices.parser.Parser;
import haxe.PosInfos;
import haxe.unit.TestCase;

class TestFileCompletion extends TestCase {
    public function testTypes() {
        assertTypes('', '[]');
        assertTypes('package ;', '[]');
        assertTypes('package com.test;', '[]');
        assertTypes('import com.test.Test;', '[]');
        assertTypes('class Test {}', '[TypeClass(Test)]');
        assertTypes('class Test { var test; }', '[TypeClass(Test)]');
        assertTypes('class Test { public var test; }', '[TypeClass(Test)]');
        assertTypes('class Test { static private var test; }', '[TypeClass(Test)]');
        assertTypes('class Test { private static var test; }', '[TypeClass(Test)]');
        assertTypes('class Test1{} class Test2{}', '[TypeClass(Test1),TypeClass(Test2)]');
        assertTypes('package ; class T1{} class T2{}', '[TypeClass(T1),TypeClass(T2)]');
        assertTypes('package a.b.c; class T1{} class T2{}', '[TypeClass(a.b.c.T1),TypeClass(a.b.c.T2)]');
        assertTypes('typedef Int2 = Int;', '[TypeTypedef(Int2->Int)]');
        //assertNoError('package com.Test;');
    }

    private function assertTypes(x:String, test:String, ?c : PosInfos) {
        var p = new Parser();
        var program = p.parseFileString(x);
        for (e in p.errors.errors) trace('Error:$e');
        assertEquals(0, p.errors.errors.length);
        assertEquals('' + test, '' + p.typeContext.getAllClasses());
        return p.errors;
    }
}
