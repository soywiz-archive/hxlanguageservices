package ;

import haxe.languageservices.parser.Completion.CompletionType;
import haxe.languageservices.parser.Completion.CompletionTypeUtils;
import haxe.languageservices.util.ArrayUtils;
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
        assertTypes('typedef Int2<T> = Int;', '[TypeTypedef(Int2<T>->Int)]');
        assertTypes('class Test<T> {}', '[TypeClass(Test<T>)]');
        assertTypes('class Test<T:Int> {}', '[TypeClass(Test<T:Int>)]');
        assertTypes('class Test<T:(Int,String)> {}', '[TypeClass(Test<T:(Int,String)>)]');
        //assertNoError('package com.Test;');
    }

    public function testCompletion() {
        assertCompletion('class Test<T1, T2> { ### }', ['T1:TypeParam', 'T2:TypeParam'], []);
        assertCompletion('class Test<T1, T2> { } ###', [], ['T1:TypeParam', 'T2:TypeParam']);
    }

    private function assertCompletion(x:String, has:Array<String>, nohas:Array<String>,  ?c : PosInfos) {
        var index = x.indexOf('###');
        x = StringTools.replace(x, '###', '');
        var p = new Parser();
        var program = p.parseFileString(x);
        for (e in p.errors.errors) trace('Error:$e');
        var list = [for (i in p.completionsAt(index).items) i.name + ':' + CompletionTypeUtils.toString(i.type)];
        if (!ArrayUtils.containsAll(list, has)) {
            assertEquals('', 'List ${list} doesn\'t contain ${has}');
        }
        if (ArrayUtils.containsAny(list, nohas)) {
            assertEquals('', 'List ${list} contains some of ${nohas}');
        }
        assertTrue(true);
        return p.errors;
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
