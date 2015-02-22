/// <reference path="./ace.d.ts" />
/// <reference path="./ts/typescriptServices.d.ts" />
var editor = ace.edit("editorIn");
editor.setTheme("ace/theme/xcode");
editor.getSession().setMode("ace/mode/typescript");
/*
var editor2 = ace.edit("editorOut");
editor2.setTheme("ace/theme/xcode");
editor2.getSession().setMode("ace/mode/javascript");
*/
var AceRange = ace.require("ace/range").Range;
var ScriptSnapshot = (function () {
    function ScriptSnapshot(text) {
        this.text = text;
    }
    ScriptSnapshot.prototype.getText = function (start, end) {
        return this.text.slice(start, end);
    };
    ScriptSnapshot.prototype.getLength = function () {
        return this.text.length;
    };
    ScriptSnapshot.prototype.getLineStartPositions = function () {
        var pos = [];
        var offset = 0;
        return this.text.split('\n').map(function (v) {
            var result = offset;
            offset += v.length + 1;
            return result;
        });
    };
    ScriptSnapshot.prototype.getChangeRange = function (oldSnapshot) {
        return undefined;
    };
    return ScriptSnapshot;
})();
var LanguageServiceHost = (function () {
    function LanguageServiceHost() {
    }
    LanguageServiceHost.prototype.log = function (s) {
        //console.log(s);
    };
    LanguageServiceHost.prototype.trace = function (s) {
        //console.info(s);
    };
    LanguageServiceHost.prototype.error = function (s) {
        //console.error(s);
    };
    LanguageServiceHost.prototype.getCompilationSettings = function () {
        //console.log('getCompilationSettings');
        return {};
    };
    LanguageServiceHost.prototype.getScriptFileNames = function () {
        //console.log('getScriptFileNames');
        return ['test.ts'];
    };
    LanguageServiceHost.prototype.getScriptVersion = function (fileName) {
        //console.log('getScriptVersion');
        return '1';
    };
    LanguageServiceHost.prototype.getScriptIsOpen = function (fileName) {
        //console.log('getScriptIsOpen');
        return false;
    };
    LanguageServiceHost.prototype.getScriptSnapshot = function (fileName) {
        //console.log('getScriptSnapshot');
        return new ScriptSnapshot(editor.session.getValue());
    };
    /*
    getLocalizedDiagnosticMessages(): any {

    }
    */
    LanguageServiceHost.prototype.getCancellationToken = function () {
        //console.log('getCancellationToken');
        return {
            isCancellationRequested: function () { return false; }
        };
    };
    LanguageServiceHost.prototype.getCurrentDirectory = function () {
        console.log('getCurrentDirectory');
        return '/';
    };
    LanguageServiceHost.prototype.getDefaultLibFilename = function (options) {
        console.log('getDefaultLibFilename');
        return '';
    };
    return LanguageServiceHost;
})();
var markerIds = [];
var gutters = [];
function updateCode() {
    var host = new LanguageServiceHost();
    var documentRegistry = ts.createDocumentRegistry();
    window.localStorage.setItem('program', editor.session.getValue());
    var lhost = ts.createLanguageService(host, documentRegistry);
    var cursor = editor.session.selection.getCursor();
    var index = editor.session.doc.positionToIndex(cursor, 0);
    var wordRange = editor.session.selection.getWordRange();
    var wordInCursor = editor.session.getTextRange(wordRange).replace(/^\s+/, '').replace(/\s+$/, '');
    var size = editor.renderer.textToScreenCoordinates(cursor.row, cursor.column);
    var autocompletionElement = document.getElementById('autocompletion');
    var signaturecompletionElement = document.getElementById('signaturecompletion');
    console.info(wordInCursor, wordRange.start, wordRange.end);
    var def = lhost.getDefinitionAtPosition('test.ts', index);
    if (def) {
        def.forEach(function (d) {
            console.info(d);
        });
    }
    var sign = lhost.getSignatureHelpItems('test.ts', index);
    if (sign) {
        signaturecompletionElement.style.top = (size.pageY + document.body.scrollTop) + 'px';
        signaturecompletionElement.style.left = size.pageX + 'px';
        signaturecompletionElement.innerHTML = '';
        //sign.argumentIndex
        sign.items.forEach(function (item) {
            for (var n = 0; n < item.parameters.length; n++) {
                var param = item.parameters[n];
                if (n == sign.argumentIndex) {
                    signaturecompletionElement.innerHTML += '<strong>' + param.name + '</strong>,';
                }
                else {
                    signaturecompletionElement.innerHTML += param.name + ',';
                }
            }
        });
        signaturecompletionElement.style.visibility = 'visible';
    }
    else {
        signaturecompletionElement.style.visibility = 'hidden';
    }
    var refs = lhost.getReferencesAtPosition('test.ts', index);
    var markers = [];
    if (refs) {
        refs.forEach(function (ref) {
            if (ref.fileName == 'test.ts') {
                var start = ref.textSpan.start();
                //var end = ref.textSpan.end();
                //var start2 = editor.session.doc.indexToPosition(start, 0);
                //var end2 = editor.session.doc.indexToPosition(end, 0);
                var start2 = editor.session.doc.indexToPosition(start, 0);
                var range = editor.session.getWordRange(start2.row, start2.column);
                markers.push([range, ref.isWriteAccess ? 'refwrite' : 'refread']);
            }
            //ref.textSpan.
        });
    }
    markerIds.forEach(function (markerId) {
        editor.session.removeMarker(markerId);
    });
    markerIds = [];
    markers.forEach(function (v) {
        var range = v[0];
        var clazz = v[1];
        var markerId = editor.session.addMarker(range, clazz, clazz, false);
        //editor.session.addDynamicMarker(markerId, true);
        markerIds.push(markerId);
    });
    //console.error(document.body.scrollTop);
    autocompletionElement.style.top = (size.pageY + document.body.scrollTop) + 'px';
    autocompletionElement.style.left = size.pageX + 'px';
    autocompletionElement.innerHTML = '';
    var count = 0;
    var completion = lhost.getCompletionsAtPosition('test.ts', index);
    completion.entries.forEach(function (entry) {
        var details = lhost.getCompletionEntryDetails('test.ts', index, entry.name);
        var name = entry.name;
        var selector = new RegExp(wordInCursor, 'ig');
        if (!name.match(selector))
            return;
        var e = document.createElement('div');
        if (details.displayParts) {
            details.displayParts.forEach(function (part) {
                switch (part.kind) {
                    case 'className':
                    case 'localName':
                    case 'propertyName':
                    case 'methodName':
                    case 'keyword':
                        if (wordInCursor == '') {
                            e.innerHTML += part.text;
                        }
                        else {
                            e.innerHTML += part.text.replace(selector, function (a) {
                                return '<span class="matching">' + a + '</span>';
                            });
                        }
                        break;
                    default:
                        e.innerHTML += part.text;
                        break;
                }
                //e.innerHTML += '<em style="color:#777;">' + part.kind + '</em>';
            });
        }
        else {
            if (wordInCursor == '') {
                e.innerHTML = name;
            }
            else {
                e.innerHTML = name.replace(selector, function (a) {
                    return '<span class="matching">' + a + '</span>';
                });
            }
        }
        if (details.documentation && details.documentation.length) {
            e.innerHTML += details.documentation[0].text;
        }
        count++;
        autocompletionElement.appendChild(e);
    });
    autocompletionElement.style.visibility = count ? 'visible' : 'hidden';
    var result = lhost.getEmitOutput('test.ts');
    //((documentRegistry.updateDocument('test.ts', 'test.ts', {}, new ScriptSnapshot(editor.session.getValue())));
    //console.log(result);
    console.log(result.emitOutputStatus);
    console.log(ts.EmitReturnStatus[result.emitOutputStatus]);
    switch (result.emitOutputStatus) {
        case 0 /* Succeeded */:
            break;
    }
    gutters.forEach(function (gutter) {
        editor.session.removeGutterDecoration(gutter[0], gutter[1]);
    });
    gutters = [];
    var annotations = [];
    //editor.session.highlight('function');
    [].concat(lhost.getSemanticDiagnostics('test.ts'), lhost.getSyntacticDiagnostics('test.ts')).forEach(function (v) {
        var pos = editor.session.doc.indexToPosition(v.start, 0);
        annotations.push({
            row: pos.row,
            column: pos.column,
            text: v.messageText,
            type: "error"
        });
    });
    editor.session.setAnnotations(annotations);
    try {
    }
    catch (e) {
        console.error(e);
    }
}
var updateTimer = -1;
editor.session.on('change', function () {
    clearTimeout(updateTimer);
    updateTimer = setTimeout(function () {
        updateCode();
        updateTimer = -1;
    }, 20);
});
editor.selection.on('changeCursor', function () {
    document.getElementById('autocompletion').style.visibility = 'hidden';
    clearTimeout(updateTimer);
    updateTimer = setTimeout(function () {
        updateCode();
        updateTimer = -1;
    }, 20);
});
function getRangeForStartEnd(start, end) {
    var start2 = editor.session.doc.indexToPosition(start, 0);
    var end2 = editor.session.doc.indexToPosition(end, 0);
    return new AceRange(start2.row, start2.column, end2.row, end2.column);
}
editor.commands.addCommand({
    name: "rename",
    bindKey: { win: "Shift-F6", mac: "Shift-F6" },
    exec: function (editor) {
        var host = new LanguageServiceHost();
        var documentRegistry = ts.createDocumentRegistry();
        var lhost = ts.createLanguageService(host, documentRegistry);
        var wordRange = editor.session.selection.getWordRange();
        var wordInCursor = editor.session.getTextRange(wordRange).replace(/^\s+/, '').replace(/\s+$/, '');
        var cursor = editor.session.selection.getCursor();
        var index = editor.session.doc.positionToIndex(cursor, 0);
        var oldName = wordInCursor;
        var newName = prompt('new name', oldName);
        var locs = lhost.findRenameLocations('test.ts', index, false, false);
        var offsetinc = newName.length - oldName.length;
        var offset = 0;
        if (locs) {
            locs.forEach(function (loc) {
                //loc.fileName
                editor.session.replace(getRangeForStartEnd(loc.textSpan.start(), loc.textSpan.end()), newName);
                offset += offsetinc;
            });
        }
    }
});
editor.commands.addCommand({
    name: "reformat",
    bindKey: { win: "Shift-F7", mac: "Shift-F7" },
    exec: function (editor) {
        var host = new LanguageServiceHost();
        var documentRegistry = ts.createDocumentRegistry();
        var lhost = ts.createLanguageService(host, documentRegistry);
        var edits = lhost.getFormattingEditsForDocument('test.ts', {
            IndentSize: 4,
            TabSize: 4,
            NewLineCharacter: "\n",
            ConvertTabsToSpaces: false,
            InsertSpaceAfterCommaDelimiter: true,
            InsertSpaceAfterSemicolonInForStatements: false,
            InsertSpaceBeforeAndAfterBinaryOperators: true,
            InsertSpaceAfterKeywordsInControlFlowStatements: true,
            InsertSpaceAfterFunctionKeywordForAnonymousFunctions: false,
            InsertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis: false,
            PlaceOpenBraceOnNewLineForFunctions: false,
            PlaceOpenBraceOnNewLineForControlBlocks: false
        });
        var offset = 0;
        edits.forEach(function (edit) {
            var range = getRangeForStartEnd(edit.span.start() + offset, edit.span.end() + offset);
            var length = edit.span.length();
            editor.session.doc.replace(range, edit.newText);
            offset += edit.newText.length - length;
        });
    }
});
editor.session.setValue(window.localStorage.getItem('program'));
editor.session.selection.moveCursorFileEnd();
updateCode();
