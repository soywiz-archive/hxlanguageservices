package;

import Ace;
import Ace.Annotation;
import Ace.Editor;
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
            updateIde();
            return null;
        });
        editor.session.on('change', function(e) {
            queueUpdateContentLive();
            return null;
        });

        updateFile();
        
    }
    
    private var updateTimeout:Int = -1;
    
    private function queueUpdateContentLive() {
        if (updateTimeout >= 0) {
            Browser.window.clearTimeout(updateTimeout);
            updateTimeout = -1;
        }
        updateTimeout = Browser.window.setTimeout(function() {
            updateTimeout = -1;
            vfs.set('live.hx', editor.session.getValue());
            setProgram();
            updateFile();
        }, 100);
    }

    private function getCursorIndex():Int {
        var cursor = editor.session.selection.getCursor();
        return editor.session.doc.positionToIndex(cursor, 0);
    }
    
    private var references:Array<CompReference> = [];


    private var markerIds = new Array<Int>();
    private var errors = new Array<CompError>();
    
    private function updateFile() {
        errors = [];
        try {
            services.updateHaxeFile('live.hx');
            errors = services.getErrors('live.hx');
        } catch (e:CompError) {
            errors.push(e);
        } catch (e:Dynamic) {
            trace(e);
        }
        updateIde();
    }
    
    private function updateIde() {
        var document = Browser.document;

        for (id in markerIds) editor.session.removeMarker(id);
        var annotations = new Array<Ace.Annotation>();
        var errorsOverlay = document.getElementById('errorsOverlay');
        var autocompletionOverlay = document.getElementById('autocompletionOverlay');
        errorsOverlay.innerText = '';

        function addError(e:CompError) {
            //trace(e);
            var min = e.pos.min;
            var max = e.pos.max;
            if (max == min) max++;
            var pos1 = editor.session.doc.indexToPosition(min, 0);
            var pos2 = editor.session.doc.indexToPosition(max, 0);
            annotations.push({
                row: pos1.row, column: pos1.column,
                text: e.text, type: 'error'
            });
            errorsOverlay.innerText += '${e.pos}:${e.text}\n';
            markerIds.push(editor.session.addMarker(AceTools.createRange(pos1, pos2), 'mark_error', 'mark_error', true));
        }


        var cursorIndex = getCursorIndex();
        var cursor = editor.session.selection.getCursor();
        var index = editor.session.doc.positionToIndex(cursor, 0);
        var size = editor.renderer.textToScreenCoordinates(cursor.row, cursor.column);

        var autocompletionElement = document.getElementById('autocompletion');
        autocompletionElement.style.visibility = 'hidden';
        autocompletionElement.style.top = (size.pageY + document.body.scrollTop) + 'px';
        autocompletionElement.style.left = size.pageX + 'px';
        autocompletionElement.innerHTML = '';

        var show = false;
        var file = 'live.hx';
        try {
            var items = services.getCompletionAt(file, cursorIndex);
            for (item in items.items) {
                var divitem = document.createElement('div');
                divitem.innerText = item.name;
                autocompletionElement.appendChild(divitem);
                show = true;
            }
            if (items.items.length == 0) {
                autocompletionOverlay.innerText = 'no autocompletion info';
            } else {
                autocompletionOverlay.innerText = items.items.join('\n');
            }
            //trace('Autocompletion:' + items);
            var id = services.getIdAt(file, cursorIndex);
            references = [];
            if (id != null) {
                var refs = services.getReferencesAt(file, cursorIndex);
                if (refs != null) {
                    for (ref in refs) references.push(ref);
                } else {
                    references.push({ pos : id.pos, type: CompReferenceType.Read });
                }

//trace(references);
            }
//trace('Identifier:' + id);
        } catch (e:Dynamic) {
            trace(e);
            addError(new CompError(new CompPosition(0, 0), '' + e));
        }
        if (show) {
//autocompletionElement.style.visibility = 'visible';
//autocompletionElement.style.opacity = '0.5';
        }

        for (reference in references) {
            var pos1 = editor.session.doc.indexToPosition(reference.pos.min, 0);
            var pos2 = editor.session.doc.indexToPosition(reference.pos.max, 0);
            var str = switch (reference.type) {
                case CompReferenceType.Declaration | CompReferenceType.Update: 'mark_refwrite';
                case CompReferenceType.Read: 'mark_refread';

            }
            //trace('$pos1, $pos2');
            
            markerIds.push(editor.session.addMarker(AceTools.createRange(pos1, pos2), str, str, false));
        }
        
        for (error in errors) {
            addError(error);
        }

        editor.session.setAnnotations(annotations);
    }
}