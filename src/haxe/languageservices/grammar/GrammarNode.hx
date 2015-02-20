package haxe.languageservices.grammar;

import haxe.languageservices.type.HaxeCompilerElement;
import haxe.languageservices.completion.CompletionProvider;
import haxe.languageservices.node.TextRange;

class GrammarNode<T> {
    public var pos:TextRange;
    public var node:T;
    public var completion:CompletionProvider;
    public var parent:GrammarNode<T>;
    public var children:Array<GrammarNode<T>> = [];
    public var element:HaxeCompilerElement;
    
    public function new(pos:TextRange, node:T) { this.pos = pos; this.node = node; }
    
    public function getCompletion():CompletionProvider {
        if (completion != null) return completion;
        if (parent != null) return parent.getCompletion();
        return null;
    }

    public function getElement():HaxeCompilerElement {
        if (element != null) return element;
        if (parent != null) return parent.getElement();
        return null;
    }

    public function addChild(item:GrammarNode<T>) {
        if (item == null) return;
        if (item == this) return;
        children.push(item);
        item.parent = this;
    }
    
    public function locateIndex(index:Int):GrammarNode<T> {
        for (child in children) {
            if (child.pos.contains(index)) return child.locateIndex(index);
        }
        return this;
    }
    
    static public function isValid<T>(node:GrammarNode<T>):Bool {
        return node != null && node.node != null;
    }
    public function toString() return '$node@$pos';
}
