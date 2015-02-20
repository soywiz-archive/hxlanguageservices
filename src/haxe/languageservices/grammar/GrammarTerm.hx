package haxe.languageservices.grammar;

enum GrammarTerm {
    TLit(lit:String, ?conv:Dynamic -> Dynamic);
    TReg(name:String, reg:EReg, ?conv:Dynamic -> Dynamic, ?checker: String -> Bool);
    TCustomMatcher(name:String, matcher: GrammarContext -> Dynamic);
    TCustomSkipper(handler:GrammarContext -> Void);
    TRef(ref:GrammarTermRef);
    TAny(items:Array<GrammarTerm>, recover:Array<GrammarTerm>);
    TNot(term:GrammarTerm);
    TSure;
    TSeq(items:Array<GrammarTerm>, ?conv: Dynamic -> Dynamic);
    TOpt(term:GrammarTerm, errorMessage:String);
    TList(item:GrammarTerm, separator:GrammarTerm, minCount:Int, allowExtraSeparator:Bool, conv:Dynamic -> Dynamic);
}
