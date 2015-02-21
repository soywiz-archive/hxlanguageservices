package haxe.languageservices.error;

import haxe.languageservices.node.TextRange;
enum QuickFixAction {
    QFReplace(pos:TextRange, newtext:String);
}
