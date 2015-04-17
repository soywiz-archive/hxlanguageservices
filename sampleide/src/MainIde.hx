package;

import js.html.DivElement;
import js.html.SpanElement;
import haxe.languageservices.node.TextRange;
import haxe.languageservices.error.QuickFixAction;
import haxe.languageservices.error.QuickFix;
import js.html.ButtonElement;
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

    public function new() {
        window = Browser.window;
        document = Browser.document;
    }

    var editor:Editor;
    var vfs:MemoryVfs;
    var services:HaxeLanguageServices;
    var window:js.html.DOMWindow;
    var document:js.html.Document;
    
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

        var langTools:Dynamic = Ace.require("ace/ext/language_tools");
        editor = Ace.edit("editorIn");
        editor.setOptions({
            enableBasicAutocompletion: true
            //enableLiveAutocompletion: true,
        });
        editor.setTheme("ace/theme/xcode");
        editor.getSession().setMode("ace/mode/haxe");
        var ed:Dynamic = editor;
        ed.completers = [
            {
                getCompletions: function(editor, session, pos, prefix:String, callback) {
                    callback(null, getAutocompletion());
                }
            }
        ];

        editor.session.setValue(vfs.readString('live.hx'));
        editor.session.selection.moveCursorFileEnd();
        editor.session.selection.on('changeCursor', function(e) {

            updateIde();
            return null;
        });
        editor.commands.on("afterExec", function(e, t) {
            if (e.command.name == "insertstring" && e.args == "." ) {
                Browser.window.setTimeout(function() {
                    e.editor.execCommand("startAutocomplete");
                }, 100);
            }
        });

        function renameExec() {
            var refs = services.getReferencesAt('live.hx', getCursorIndex());
            if (refs != null && refs.list.length > 0) {
                var result = window.prompt('Rename:', refs.name);
                if (result != null) {
                    var list2:Array<CompReference> = refs.list.slice(0);
                    list2.sort(function(a:CompReference, b:CompReference) {
                        return b.pos.min - a.pos.min;
                    });
                    
                    // @TODO: Check result as a valid identifier and not collisioning with other scopes
                    // probably this should be done in the services part

                    for (item in list2) {
                        editor.session.replace(
                            AceTools.createRangeIndices(editor, item.pos.min, item.pos.max),
                            result
                        );
                    }
                    editor.focus();
                }
            } else {
                window.alert('nothing to rename!');
            }
        }

        editor.commands.addCommand({
            name: "rename",
            bindKey: { win: 'F2', mac: 'Shift+F6' },
            exec: renameExec
        });

        editor.session.on('change', function(e) {
            queueUpdateContentLive();
            /*
            cast(editor).completer.autoInsert = false;
            cast(editor).completer.autoSelect = true;
            cast(editor).completer.showPopup(editor);
            cast(editor).completer.cancelContextMenu();
            */

            return null;
        });

        updateFile();
    }
    
    private function getAutocompletion():Array<{name: String, value: String, score: Float, meta: String}> {
        var comp = new Array<{name: String, value: String, score: Float, meta: String}>();
        for (item in services.getCompletionAt('live.hx', getCursorIndex()).items) {
            comp.push({
                name: item.name,
                value: item.name,
                score: 1000,
                meta: item.type.toString()
            });
        }
        return comp;
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
        }, 80);
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
        var document:Dynamic = Browser.document;

        for (id in markerIds) editor.session.removeMarker(id);
        var annotations = new Array<Ace.Annotation>();
        var errorsOverlay = document.getElementById('errorsOverlay');
        var autocompletionOverlay = document.getElementById('autocompletionOverlay');
        var callinfoOverlay = document.getElementById('callinfoOverlay');
        var currentNodeOverlay = document.getElementById('currentNodeOverlay');
        errorsOverlay.innerText = '';
        currentNodeOverlay.innerText = '';

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
            var fixText:DivElement = cast document.createElement('div');
            var ft2:Dynamic = fixText;
            ft2.innerText = '${e.pos}:${e.text}\n';
            errorsOverlay.appendChild(fixText);

            if (e.fixes != null) Lambda.foreach(e.fixes, function(fix:QuickFix) {
                var fixButton:ButtonElement = cast document.createElement('button');
                fixButton.textContent = fix.name;
                fixButton.onclick = function(e) {
                    var actions = fix.fixer();
                    trace(actions);
                    for (action in actions) {
                        switch (action) {
                            case QuickFixAction.QFReplace(_pos, _newtext):
                                var pos:TextRange = _pos;
                                var newtext:String = _newtext;

                                editor.session.replace(
                                    AceTools.createRangeIndices(editor, pos.min, pos.max),
                                    newtext
                                );
                        }
                    }
                    editor.focus();
//trace(actions);
                }
                fixText.appendChild(fixButton);
                return true;
            });

            markerIds.push(editor.session.addMarker(AceTools.createRange(pos1, pos2), 'mark_error', 'mark_error', true));
        }


        var cursorIndex = getCursorIndex();
        var cursor = editor.session.selection.getCursor();
        var index = editor.session.doc.positionToIndex(cursor, 0);
        var size = editor.renderer.textToScreenCoordinates(cursor.row, cursor.column);

        var show = false;
        var file = 'live.hx';
        try {
            // Completion
            var curParent = services._getNodeAt(file, cursorIndex);

            currentNodeOverlay.innerText = curParent.getAncestors(4).join('\n');
            var items = services.getCompletionAt(file, cursorIndex);
            if (items.items.length == 0) {
                autocompletionOverlay.innerText = 'no autocompletion info';
            } else {
                autocompletionOverlay.innerText = items.items.join('\n');
            }
            
            // References
            var id = services.getIdAt(file, cursorIndex);
            references = [];
            if (id != null) {
                var refs = services.getReferencesAt(file, cursorIndex);
                if (refs != null) {
                    for (ref in refs.list) references.push(ref);
                } else {
                    references.push(new CompReference(id.pos, CompReferenceType.Read));
                }
            }
            
            // CallInfo
            var call = services.getCallInfoAt(file, cursorIndex);
            var signaturecompletion = document.getElementById('signaturecompletion');
            if (call != null) {
                callinfoOverlay.innerHTML = HtmlTools.callToHtml(call);
                var p = editor.session.doc.indexToPosition(call.startPos, 0);
                var p2 = editor.session.doc.indexToPosition(call.callEndPos, 0);
                var sp = editor.renderer.textToScreenCoordinates(p.row, p.column);
                var sp2 = editor.renderer.textToScreenCoordinates(p2.row, p2.column);

                signaturecompletion.style.left = Math.min(sp.pageX, sp2.pageX) + 'px';
                signaturecompletion.style.top = Math.max(sp.pageY, sp2.pageY) + 'px';
                signaturecompletion.innerHTML = HtmlTools.callToHtml(call);
                signaturecompletion.style.visibility = 'visible';
                document.body.className = 'info2';
            } else {
                callinfoOverlay.innerText = 'no call info';
                signaturecompletion.style.visibility = 'hidden';
                document.body.className = '';
            }
        } catch (e:Dynamic) {
            try { Browser.window.console.error(e.stack); } catch (e2:Dynamic) { }
            Browser.window.console.error(e);
            addError(new CompError(new CompPosition(0, 0), '' + e, []));
        }

        for (reference in references) {
            var pos1 = editor.session.doc.indexToPosition(reference.pos.min, 0);
            var pos2 = editor.session.doc.indexToPosition(reference.pos.max, 0);
            var str = switch (reference.type) {
                case CompReferenceType.Declaration | CompReferenceType.Update: 'mark_refwrite';
                case CompReferenceType.Read: 'mark_refread';
            }

            markerIds.push(editor.session.addMarker(AceTools.createRange(pos1, pos2), str, str, false));
        }
        
        for (error in errors) {
            addError(error);
        }

        editor.session.setAnnotations(annotations);
    }
}