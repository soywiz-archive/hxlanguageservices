package haxe.languageservices.grammar;

import haxe.languageservices.type.ExpressionResult;
import haxe.languageservices.completion.CallInfo;
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
    public var callInfo:CallInfo;
    
    public function new(pos:TextRange, node:T) { this.pos = pos; this.node = node; }
    
    public function getAncestors(count:Int, ?out:Array<GrammarNode<T>>):Array<GrammarNode<T>> {
        if (out == null) out = [];
        out.push(this);
        if (parent != null && count > 0) parent.getAncestors(count - 1, out);
        return out;
    }
    
    public function getCompletion():CompletionProvider {
        if (completion != null) return completion;
        if (parent != null) return parent.getCompletion();
        return null;
    }
    
    public function getResult():ExpressionResult {
        return null;
    }

    public function getElement():HaxeCompilerElement {
        if (element != null) return element;
        if (parent != null) return parent.getElement();
        return null;
    }

    public function getCallInfo():CallInfo {
        //trace(this);
        //trace(children);
        if (callInfo != null) return callInfo;
        if (parent != null) return parent.getCallInfo();
        return null;
    }

    public function getLocal():HaxeCompilerElement {
        var id = getIdentifier();
        var completion = getCompletion();
        return (id != null && completion != null) ? completion.getEntryByName(id.name) : null;
    }

    public function getCallInfoAt(index:Int):CallInfo {
        //trace('getCallInfoAt($index)');
        return locateIndex(index).getCallInfo();
    }

    public function getIdentifierAt(index:Int):{ pos: TextRange, name: String } {
        return locateIndex(index).getIdentifier();
    }

    public function getLocalAt(index:Int):HaxeCompilerElement {
        return locateIndex(index).getLocal();
    }

    public function getIdentifier():{ pos: TextRange, name: String } {
        var text = pos.text;
        if (!~/^\w+$/.match(text)) return null;
        //throw 'must implement getIdentifier : ' + pos.text + '!';
        return { pos : pos, name : text };
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
