package haxe.languageservices.grammar;

enum GrammarResult {
    RMatched;
    RUnmatched(validCount:Int, lastPos:Int);
    RMatchedValue(value:GrammarNode<Dynamic>);
}
