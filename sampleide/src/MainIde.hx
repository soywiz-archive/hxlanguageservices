package;

import Ace;
import Ace.Annotation;
import Ace.Editor;
import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.util.Vfs;
import haxe.languageservices.util.MemoryVfs;
import haxe.languageservices.HaxeLanguageServices;
import js.Browser;

// @TODO: Check CodeMirror vs Ace
class MainIde {
    static public function main() {
        new MainIde().run();
    }

    public function new() { }

    var editor:Editor;
    var vfs:MemoryVfs;
    var services:HaxeLanguageServices;
    
    private function getProgram():String {
        var item = Browser.window.localStorage.getItem('hxprogram');
        if (item == null) item = 'class Test {';
        return item;
    }

    private function setProgram() {
        Browser.window.localStorage.setItem('hxprogram', editor.session.getValue());
    }

    private function run() {
        vfs = new MemoryVfs();
        vfs.set('live.hx', getProgram());
        services = new HaxeLanguageServices(vfs);

        var langTools = Ace.require("ace/ext/language_tools");
        editor = Ace.edit("editorIn");
        editor.setOptions({enableBasicAutocompletion: true});
        editor.setTheme("ace/theme/xcode");
        editor.getSession().setMode("ace/mode/haxe");

//editor.session.setValue(Browser.window.localStorage.getItem('hxprogram'));
        editor.session.setValue(vfs.readString('live.hx'));
        editor.session.selection.moveCursorFileEnd();
        editor.session.selection.on('changeCursor', function(e) {
            //updateLive();
            updateAutocompletion();
            return null;
        });
        editor.session.on('change', function(e) {
            queueUpdateContentLive();
            updateAutocompletion();
            return null;
        });

        /*
        trace(langTools);

        langTools.addCompleter({
            getCompletions: function(editor, session, pos, prefix, callback) {
                //if (prefix.length === 0) { callback(null, []); return }
                //$.getJSON(jsonUrl, function(wordList) {
                //    callback(null, wordList.map(function(ea)  {
                //        return {name: ea.word, value: ea.word, meta: "optional text"}
                //    }));
                //})
                callback(null, []);
            }
        });
        */

        updateContentLive();
    }
    
    private var updateTimeout:Int = -1;
    
    private function queueUpdateContentLive() {
        if (updateTimeout >= 0) {
            Browser.window.clearTimeout(updateTimeout);
            updateTimeout = -1;
        }
        updateTimeout = Browser.window.setTimeout(function() {
            updateTimeout = -1;
            updateContentLive();
        }, 100);
    }
    
    private function updateContentLive() {
        vfs.set('live.hx', editor.session.getValue());
        setProgram();
        updateLive();
    }
    
    private function getCursorIndex():Int {
        var cursor = editor.session.selection.getCursor();
        return editor.session.doc.positionToIndex(cursor, 0);
    }
    
    private function updateAutocompletion() {
        var cursor = editor.session.selection.getCursor();
        var index = editor.session.doc.positionToIndex(cursor, 0);
        var size = editor.renderer.textToScreenCoordinates(cursor.row, cursor.column);

        var document = Browser.document;
        var autocompletionElement = document.getElementById('autocompletion');
        autocompletionElement.style.visibility = 'hidden';
        autocompletionElement.style.top = (size.pageY + document.body.scrollTop) + 'px';
        autocompletionElement.style.left = size.pageX + 'px';
        autocompletionElement.innerHTML = '';

        var show = false;
        try {
            var items = services.getCompletionAt('live.hx', getCursorIndex());
            for (item in items.items) {
                var divitem = document.createElement('div');
                divitem.innerText = item.name;
                autocompletionElement.appendChild(divitem);
                show = true;
            }
            trace('Autocompletion:' + items);
        } catch (e:Dynamic) {
            trace(e);
        }
        if (show) {
            //autocompletionElement.style.visibility = 'visible';
            //autocompletionElement.style.opacity = '0.5';
        }
    }

    private function updateLive() {
        var annotations = new Array<Ace.Annotation>();
        function addError(e:CompError) {
            trace(e);
            var pos1 = editor.session.doc.indexToPosition(e.pos.min, 0);
            annotations.push({
            row: pos1.row,
            column: pos1.column,
            text: e.text,
            type: 'error'
            });
        }

        try {
            services.updateHaxeFile('live.hx');
            for (error in services.getErrors('live.hx')) {
                addError(error);
            }
        } catch (e:CompError) {
            addError(e);
        } catch (e:Dynamic) {
            trace(e);
        }

        editor.session.setAnnotations(annotations);
    }
}