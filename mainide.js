(function () { "use strict";
var $hxClasses = {},$estr = function() { return js.Boot.__string_rec(this,''); };
function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var AceTools = function() { };
$hxClasses["AceTools"] = AceTools;
AceTools.__name__ = ["AceTools"];
AceTools._createRange = function(startRow,startColumn,endRow,endColumn) {
	var vv = ace.require("ace/range").Range;
	return Type.createInstance(vv,[startRow,startColumn,endRow,endColumn]);
};
AceTools.createRange = function(start,end) {
	return AceTools._createRange(start.row,start.column,end.row,end.column);
};
var EReg = function(r,opt) {
	opt = opt.split("u").join("");
	this.r = new RegExp(r,opt);
};
$hxClasses["EReg"] = EReg;
EReg.__name__ = ["EReg"];
EReg.prototype = {
	r: null
	,match: function(s) {
		if(this.r.global) this.r.lastIndex = 0;
		this.r.m = this.r.exec(s);
		this.r.s = s;
		return this.r.m != null;
	}
	,matched: function(n) {
		if(this.r.m != null && n >= 0 && n < this.r.m.length) return this.r.m[n]; else throw "EReg::matched";
	}
	,matchedLeft: function() {
		if(this.r.m == null) throw "No string matched";
		return this.r.s.substr(0,this.r.m.index);
	}
	,matchedRight: function() {
		if(this.r.m == null) throw "No string matched";
		var sz = this.r.m.index + this.r.m[0].length;
		return this.r.s.substr(sz,this.r.s.length - sz);
	}
	,matchedPos: function() {
		if(this.r.m == null) throw "No string matched";
		return { pos : this.r.m.index, len : this.r.m[0].length};
	}
	,matchSub: function(s,pos,len) {
		if(len == null) len = -1;
		if(this.r.global) {
			this.r.lastIndex = pos;
			this.r.m = this.r.exec(len < 0?s:HxOverrides.substr(s,0,pos + len));
			var b = this.r.m != null;
			if(b) this.r.s = s;
			return b;
		} else {
			var b1 = this.match(len < 0?HxOverrides.substr(s,pos,null):HxOverrides.substr(s,pos,len));
			if(b1) {
				this.r.s = s;
				this.r.m.index += pos;
			}
			return b1;
		}
	}
	,split: function(s) {
		var d = "#__delim__#";
		return s.replace(this.r,d).split(d);
	}
	,replace: function(s,by) {
		return s.replace(this.r,by);
	}
	,map: function(s,f) {
		var offset = 0;
		var buf = new StringBuf();
		do {
			if(offset >= s.length) break; else if(!this.matchSub(s,offset)) {
				buf.add(HxOverrides.substr(s,offset,null));
				break;
			}
			var p = this.matchedPos();
			buf.add(HxOverrides.substr(s,offset,p.pos - offset));
			buf.add(f(this));
			if(p.len == 0) {
				buf.add(HxOverrides.substr(s,p.pos,1));
				offset = p.pos + 1;
			} else offset = p.pos + p.len;
		} while(this.r.global);
		if(!this.r.global && offset > 0 && offset < s.length) buf.add(HxOverrides.substr(s,offset,null));
		return buf.b;
	}
	,__class__: EReg
};
var HxOverrides = function() { };
$hxClasses["HxOverrides"] = HxOverrides;
HxOverrides.__name__ = ["HxOverrides"];
HxOverrides.dateStr = function(date) {
	var m = date.getMonth() + 1;
	var d = date.getDate();
	var h = date.getHours();
	var mi = date.getMinutes();
	var s = date.getSeconds();
	return date.getFullYear() + "-" + (m < 10?"0" + m:"" + m) + "-" + (d < 10?"0" + d:"" + d) + " " + (h < 10?"0" + h:"" + h) + ":" + (mi < 10?"0" + mi:"" + mi) + ":" + (s < 10?"0" + s:"" + s);
};
HxOverrides.strDate = function(s) {
	var _g = s.length;
	switch(_g) {
	case 8:
		var k = s.split(":");
		var d = new Date();
		d.setTime(0);
		d.setUTCHours(k[0]);
		d.setUTCMinutes(k[1]);
		d.setUTCSeconds(k[2]);
		return d;
	case 10:
		var k1 = s.split("-");
		return new Date(k1[0],k1[1] - 1,k1[2],0,0,0);
	case 19:
		var k2 = s.split(" ");
		var y = k2[0].split("-");
		var t = k2[1].split(":");
		return new Date(y[0],y[1] - 1,y[2],t[0],t[1],t[2]);
	default:
		throw "Invalid date format : " + s;
	}
};
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
};
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
};
HxOverrides.indexOf = function(a,obj,i) {
	var len = a.length;
	if(i < 0) {
		i += len;
		if(i < 0) i = 0;
	}
	while(i < len) {
		if(a[i] === obj) return i;
		i++;
	}
	return -1;
};
HxOverrides.lastIndexOf = function(a,obj,i) {
	var len = a.length;
	if(i >= len) i = len - 1; else if(i < 0) i += len;
	while(i >= 0) {
		if(a[i] === obj) return i;
		i--;
	}
	return -1;
};
HxOverrides.remove = function(a,obj) {
	var i = HxOverrides.indexOf(a,obj,0);
	if(i == -1) return false;
	a.splice(i,1);
	return true;
};
HxOverrides.iter = function(a) {
	return { cur : 0, arr : a, hasNext : function() {
		return this.cur < this.arr.length;
	}, next : function() {
		return this.arr[this.cur++];
	}};
};
var IntIterator = function(min,max) {
	this.min = min;
	this.max = max;
};
$hxClasses["IntIterator"] = IntIterator;
IntIterator.__name__ = ["IntIterator"];
IntIterator.prototype = {
	min: null
	,max: null
	,hasNext: function() {
		return this.min < this.max;
	}
	,next: function() {
		return this.min++;
	}
	,__class__: IntIterator
};
var MainIde = function() {
	this.errors = new Array();
	this.markerIds = new Array();
	this.references = [];
	this.updateTimeout = -1;
};
$hxClasses["MainIde"] = MainIde;
MainIde.__name__ = ["MainIde"];
MainIde.main = function() {
	new MainIde().run();
};
MainIde.prototype = {
	editor: null
	,vfs: null
	,services: null
	,getProgram: function() {
		var item = window.localStorage.getItem("hxprogram");
		if(item == null) item = "class Test {";
		return item;
	}
	,setProgram: function() {
		window.localStorage.setItem("hxprogram",this.editor.session.getValue());
	}
	,run: function() {
		var _g = this;
		this.vfs = new haxe.languageservices.util.MemoryVfs();
		this.vfs.set("live.hx",this.getProgram());
		this.services = new haxe.languageservices.HaxeLanguageServices(this.vfs);
		var langTools = ace.require("ace/ext/language_tools");
		this.editor = ace.edit("editorIn");
		this.editor.setOptions({ enableBasicAutocompletion : true});
		this.editor.setTheme("ace/theme/xcode");
		this.editor.getSession().setMode("ace/mode/haxe");
		this.editor.completers = [{ getCompletions : function(editor,session,pos,prefix,callback) {
			callback(null,_g.getAutocompletion());
		}}];
		this.editor.session.setValue(this.vfs.readString("live.hx"));
		this.editor.session.selection.moveCursorFileEnd();
		this.editor.session.selection.on("changeCursor",function(e) {
			_g.updateIde();
			return null;
		});
		this.editor.session.on("change",function(e1) {
			_g.queueUpdateContentLive();
			return null;
		});
		this.updateFile();
	}
	,getAutocompletion: function() {
		var comp = new Array();
		var _g = 0;
		var _g1 = this.services.getCompletionAt("live.hx",this.getCursorIndex()).items;
		while(_g < _g1.length) {
			var item = _g1[_g];
			++_g;
			comp.push({ name : item.name, value : item.name, score : 1000, meta : item.type.toString()});
		}
		return comp;
	}
	,updateTimeout: null
	,queueUpdateContentLive: function() {
		var _g = this;
		if(this.updateTimeout >= 0) {
			window.clearTimeout(this.updateTimeout);
			this.updateTimeout = -1;
		}
		this.updateTimeout = window.setTimeout(function() {
			_g.updateTimeout = -1;
			_g.vfs.set("live.hx",_g.editor.session.getValue());
			_g.setProgram();
			_g.updateFile();
		},100);
	}
	,getCursorIndex: function() {
		var cursor = this.editor.session.selection.getCursor();
		return this.editor.session.doc.positionToIndex(cursor,0);
	}
	,references: null
	,markerIds: null
	,errors: null
	,updateFile: function() {
		this.errors = [];
		try {
			this.services.updateHaxeFile("live.hx");
			this.errors = this.services.getErrors("live.hx");
		} catch( $e0 ) {
			if( js.Boot.__instanceof($e0,haxe.languageservices.CompError) ) {
				var e = $e0;
				this.errors.push(e);
			} else {
			var e1 = $e0;
			haxe.Log.trace(e1,{ fileName : "MainIde.hx", lineNumber : 122, className : "MainIde", methodName : "updateFile"});
			}
		}
		this.updateIde();
	}
	,updateIde: function() {
		var _g = this;
		var document = window.document;
		var _g1 = 0;
		var _g11 = this.markerIds;
		while(_g1 < _g11.length) {
			var id = _g11[_g1];
			++_g1;
			this.editor.session.removeMarker(id);
		}
		var annotations = new Array();
		var errorsOverlay = document.getElementById("errorsOverlay");
		var autocompletionOverlay = document.getElementById("autocompletionOverlay");
		errorsOverlay.innerText = "";
		var addError = function(e) {
			var min = e.pos.min;
			var max = e.pos.max;
			if(max == min) max++;
			var pos1 = _g.editor.session.doc.indexToPosition(min,0);
			var pos2 = _g.editor.session.doc.indexToPosition(max,0);
			annotations.push({ row : pos1.row, column : pos1.column, text : e.text, type : "error"});
			errorsOverlay.innerText += "" + Std.string(e.pos) + ":" + e.text + "\n";
			_g.markerIds.push(_g.editor.session.addMarker(AceTools.createRange(pos1,pos2),"mark_error","mark_error",true));
		};
		var cursorIndex = this.getCursorIndex();
		var cursor = this.editor.session.selection.getCursor();
		var index = this.editor.session.doc.positionToIndex(cursor,0);
		var size = this.editor.renderer.textToScreenCoordinates(cursor.row,cursor.column);
		var autocompletionElement = document.getElementById("autocompletion");
		autocompletionElement.style.visibility = "hidden";
		autocompletionElement.style.top = size.pageY + document.body.scrollTop + "px";
		autocompletionElement.style.left = size.pageX + "px";
		autocompletionElement.innerHTML = "";
		var show = false;
		var file = "live.hx";
		try {
			var items = this.services.getCompletionAt(file,cursorIndex);
			var _g2 = 0;
			var _g12 = items.items;
			while(_g2 < _g12.length) {
				var item = _g12[_g2];
				++_g2;
				var divitem = document.createElement("div");
				divitem.innerText = item.name;
				autocompletionElement.appendChild(divitem);
				show = true;
			}
			if(items.items.length == 0) autocompletionOverlay.innerText = "no autocompletion info"; else autocompletionOverlay.innerText = items.items.join("\n");
			var id1 = this.services.getIdAt(file,cursorIndex);
			this.references = [];
			if(id1 != null) {
				var refs = this.services.getReferencesAt(file,cursorIndex);
				if(refs != null) {
					var _g3 = 0;
					while(_g3 < refs.length) {
						var ref = refs[_g3];
						++_g3;
						this.references.push(ref);
					}
				} else this.references.push({ pos : id1.pos, type : haxe.languageservices.CompReferenceType.Read});
			}
		} catch( e1 ) {
			haxe.Log.trace(e1,{ fileName : "MainIde.hx", lineNumber : 193, className : "MainIde", methodName : "updateIde"});
			addError(new haxe.languageservices.CompError(new haxe.languageservices.CompPosition(0,0),"" + Std.string(e1)));
		}
		if(show) {
		}
		var _g4 = 0;
		var _g13 = this.references;
		while(_g4 < _g13.length) {
			var reference = _g13[_g4];
			++_g4;
			var pos11 = this.editor.session.doc.indexToPosition(reference.pos.min,0);
			var pos21 = this.editor.session.doc.indexToPosition(reference.pos.max,0);
			var str;
			var _g21 = reference.type;
			switch(_g21[1]) {
			case 0:case 1:
				str = "mark_refwrite";
				break;
			case 2:
				str = "mark_refread";
				break;
			}
			this.markerIds.push(this.editor.session.addMarker(AceTools.createRange(pos11,pos21),str,str,false));
		}
		var _g5 = 0;
		var _g14 = this.errors;
		while(_g5 < _g14.length) {
			var error = _g14[_g5];
			++_g5;
			addError(error);
		}
		this.editor.session.setAnnotations(annotations);
	}
	,__class__: MainIde
};
var _Map = {};
_Map.Map_Impl_ = function() { };
$hxClasses["_Map.Map_Impl_"] = _Map.Map_Impl_;
_Map.Map_Impl_.__name__ = ["_Map","Map_Impl_"];
_Map.Map_Impl_._new = null;
_Map.Map_Impl_.set = function(this1,key,value) {
	this1.set(key,value);
};
_Map.Map_Impl_.get = function(this1,key) {
	return this1.get(key);
};
_Map.Map_Impl_.exists = function(this1,key) {
	return this1.exists(key);
};
_Map.Map_Impl_.remove = function(this1,key) {
	return this1.remove(key);
};
_Map.Map_Impl_.keys = function(this1) {
	return this1.keys();
};
_Map.Map_Impl_.iterator = function(this1) {
	return this1.iterator();
};
_Map.Map_Impl_.toString = function(this1) {
	return this1.toString();
};
_Map.Map_Impl_.arrayWrite = function(this1,k,v) {
	this1.set(k,v);
	return v;
};
_Map.Map_Impl_.toStringMap = function(t) {
	return new haxe.ds.StringMap();
};
_Map.Map_Impl_.toIntMap = function(t) {
	return new haxe.ds.IntMap();
};
_Map.Map_Impl_.toEnumValueMapMap = function(t) {
	return new haxe.ds.EnumValueMap();
};
_Map.Map_Impl_.toObjectMap = function(t) {
	return new haxe.ds.ObjectMap();
};
_Map.Map_Impl_.fromStringMap = function(map) {
	return map;
};
_Map.Map_Impl_.fromIntMap = function(map) {
	return map;
};
_Map.Map_Impl_.fromObjectMap = function(map) {
	return map;
};
var IMap = function() { };
$hxClasses["IMap"] = IMap;
IMap.__name__ = ["IMap"];
IMap.prototype = {
	get: null
	,set: null
	,exists: null
	,remove: null
	,keys: null
	,iterator: null
	,toString: null
	,__class__: IMap
};
Math.__name__ = ["Math"];
var Reflect = function() { };
$hxClasses["Reflect"] = Reflect;
Reflect.__name__ = ["Reflect"];
Reflect.hasField = function(o,field) {
	return Object.prototype.hasOwnProperty.call(o,field);
};
Reflect.field = function(o,field) {
	try {
		return o[field];
	} catch( e ) {
		return null;
	}
};
Reflect.setField = function(o,field,value) {
	o[field] = value;
};
Reflect.getProperty = function(o,field) {
	var tmp;
	if(o == null) return null; else if(o.__properties__ && (tmp = o.__properties__["get_" + field])) return o[tmp](); else return o[field];
};
Reflect.setProperty = function(o,field,value) {
	var tmp;
	if(o.__properties__ && (tmp = o.__properties__["set_" + field])) o[tmp](value); else o[field] = value;
};
Reflect.callMethod = function(o,func,args) {
	return func.apply(o,args);
};
Reflect.fields = function(o) {
	var a = [];
	if(o != null) {
		var hasOwnProperty = Object.prototype.hasOwnProperty;
		for( var f in o ) {
		if(f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o,f)) a.push(f);
		}
	}
	return a;
};
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && !(f.__name__ || f.__ename__);
};
Reflect.compare = function(a,b) {
	if(a == b) return 0; else if(a > b) return 1; else return -1;
};
Reflect.compareMethods = function(f1,f2) {
	if(f1 == f2) return true;
	if(!Reflect.isFunction(f1) || !Reflect.isFunction(f2)) return false;
	return f1.scope == f2.scope && f1.method == f2.method && f1.method != null;
};
Reflect.isObject = function(v) {
	if(v == null) return false;
	var t = typeof(v);
	return t == "string" || t == "object" && v.__enum__ == null || t == "function" && (v.__name__ || v.__ename__) != null;
};
Reflect.isEnumValue = function(v) {
	return v != null && v.__enum__ != null;
};
Reflect.deleteField = function(o,field) {
	if(!Object.prototype.hasOwnProperty.call(o,field)) return false;
	delete(o[field]);
	return true;
};
Reflect.copy = function(o) {
	var o2 = { };
	var _g = 0;
	var _g1 = Reflect.fields(o);
	while(_g < _g1.length) {
		var f = _g1[_g];
		++_g;
		Reflect.setField(o2,f,Reflect.field(o,f));
	}
	return o2;
};
Reflect.makeVarArgs = function(f) {
	return function() {
		var a = Array.prototype.slice.call(arguments);
		return f(a);
	};
};
var Std = function() { };
$hxClasses["Std"] = Std;
Std.__name__ = ["Std"];
Std["is"] = function(v,t) {
	return js.Boot.__instanceof(v,t);
};
Std.instance = function(value,c) {
	if((value instanceof c)) return value; else return null;
};
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
};
Std["int"] = function(x) {
	return x | 0;
};
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
};
Std.parseFloat = function(x) {
	return parseFloat(x);
};
Std.random = function(x) {
	if(x <= 0) return 0; else return Math.floor(Math.random() * x);
};
var StringBuf = function() {
	this.b = "";
};
$hxClasses["StringBuf"] = StringBuf;
StringBuf.__name__ = ["StringBuf"];
StringBuf.prototype = {
	b: null
	,get_length: function() {
		return this.b.length;
	}
	,add: function(x) {
		this.b += Std.string(x);
	}
	,addChar: function(c) {
		this.b += String.fromCharCode(c);
	}
	,addSub: function(s,pos,len) {
		if(len == null) this.b += HxOverrides.substr(s,pos,null); else this.b += HxOverrides.substr(s,pos,len);
	}
	,toString: function() {
		return this.b;
	}
	,__class__: StringBuf
	,__properties__: {get_length:"get_length"}
};
var StringTools = function() { };
$hxClasses["StringTools"] = StringTools;
StringTools.__name__ = ["StringTools"];
StringTools.urlEncode = function(s) {
	return encodeURIComponent(s);
};
StringTools.urlDecode = function(s) {
	return decodeURIComponent(s.split("+").join(" "));
};
StringTools.htmlEscape = function(s,quotes) {
	s = s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
	if(quotes) return s.split("\"").join("&quot;").split("'").join("&#039;"); else return s;
};
StringTools.htmlUnescape = function(s) {
	return s.split("&gt;").join(">").split("&lt;").join("<").split("&quot;").join("\"").split("&#039;").join("'").split("&amp;").join("&");
};
StringTools.startsWith = function(s,start) {
	return s.length >= start.length && HxOverrides.substr(s,0,start.length) == start;
};
StringTools.endsWith = function(s,end) {
	var elen = end.length;
	var slen = s.length;
	return slen >= elen && HxOverrides.substr(s,slen - elen,elen) == end;
};
StringTools.isSpace = function(s,pos) {
	var c = HxOverrides.cca(s,pos);
	return c > 8 && c < 14 || c == 32;
};
StringTools.ltrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,r)) r++;
	if(r > 0) return HxOverrides.substr(s,r,l - r); else return s;
};
StringTools.rtrim = function(s) {
	var l = s.length;
	var r = 0;
	while(r < l && StringTools.isSpace(s,l - r - 1)) r++;
	if(r > 0) return HxOverrides.substr(s,0,l - r); else return s;
};
StringTools.trim = function(s) {
	return StringTools.ltrim(StringTools.rtrim(s));
};
StringTools.lpad = function(s,c,l) {
	if(c.length <= 0) return s;
	while(s.length < l) s = c + s;
	return s;
};
StringTools.rpad = function(s,c,l) {
	if(c.length <= 0) return s;
	while(s.length < l) s = s + c;
	return s;
};
StringTools.replace = function(s,sub,by) {
	return s.split(sub).join(by);
};
StringTools.hex = function(n,digits) {
	var s = "";
	var hexChars = "0123456789ABCDEF";
	do {
		s = hexChars.charAt(n & 15) + s;
		n >>>= 4;
	} while(n > 0);
	if(digits != null) while(s.length < digits) s = "0" + s;
	return s;
};
StringTools.fastCodeAt = function(s,index) {
	return s.charCodeAt(index);
};
StringTools.isEof = function(c) {
	return c != c;
};
var ValueType = $hxClasses["ValueType"] = { __ename__ : ["ValueType"], __constructs__ : ["TNull","TInt","TFloat","TBool","TObject","TFunction","TClass","TEnum","TUnknown"] };
ValueType.TNull = ["TNull",0];
ValueType.TNull.toString = $estr;
ValueType.TNull.__enum__ = ValueType;
ValueType.TInt = ["TInt",1];
ValueType.TInt.toString = $estr;
ValueType.TInt.__enum__ = ValueType;
ValueType.TFloat = ["TFloat",2];
ValueType.TFloat.toString = $estr;
ValueType.TFloat.__enum__ = ValueType;
ValueType.TBool = ["TBool",3];
ValueType.TBool.toString = $estr;
ValueType.TBool.__enum__ = ValueType;
ValueType.TObject = ["TObject",4];
ValueType.TObject.toString = $estr;
ValueType.TObject.__enum__ = ValueType;
ValueType.TFunction = ["TFunction",5];
ValueType.TFunction.toString = $estr;
ValueType.TFunction.__enum__ = ValueType;
ValueType.TClass = function(c) { var $x = ["TClass",6,c]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; };
ValueType.TEnum = function(e) { var $x = ["TEnum",7,e]; $x.__enum__ = ValueType; $x.toString = $estr; return $x; };
ValueType.TUnknown = ["TUnknown",8];
ValueType.TUnknown.toString = $estr;
ValueType.TUnknown.__enum__ = ValueType;
ValueType.__empty_constructs__ = [ValueType.TNull,ValueType.TInt,ValueType.TFloat,ValueType.TBool,ValueType.TObject,ValueType.TFunction,ValueType.TUnknown];
var Type = function() { };
$hxClasses["Type"] = Type;
Type.__name__ = ["Type"];
Type.getClass = function(o) {
	if(o == null) return null;
	if((o instanceof Array) && o.__enum__ == null) return Array; else return o.__class__;
};
Type.getEnum = function(o) {
	if(o == null) return null;
	return o.__enum__;
};
Type.getSuperClass = function(c) {
	return c.__super__;
};
Type.getClassName = function(c) {
	var a = c.__name__;
	return a.join(".");
};
Type.getEnumName = function(e) {
	var a = e.__ename__;
	return a.join(".");
};
Type.resolveClass = function(name) {
	var cl = $hxClasses[name];
	if(cl == null || !cl.__name__) return null;
	return cl;
};
Type.resolveEnum = function(name) {
	var e = $hxClasses[name];
	if(e == null || !e.__ename__) return null;
	return e;
};
Type.createInstance = function(cl,args) {
	var _g = args.length;
	switch(_g) {
	case 0:
		return new cl();
	case 1:
		return new cl(args[0]);
	case 2:
		return new cl(args[0],args[1]);
	case 3:
		return new cl(args[0],args[1],args[2]);
	case 4:
		return new cl(args[0],args[1],args[2],args[3]);
	case 5:
		return new cl(args[0],args[1],args[2],args[3],args[4]);
	case 6:
		return new cl(args[0],args[1],args[2],args[3],args[4],args[5]);
	case 7:
		return new cl(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
	case 8:
		return new cl(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
	default:
		throw "Too many arguments";
	}
	return null;
};
Type.createEmptyInstance = function(cl) {
	function empty() {}; empty.prototype = cl.prototype;
	return new empty();
};
Type.createEnum = function(e,constr,params) {
	var f = Reflect.field(e,constr);
	if(f == null) throw "No such constructor " + constr;
	if(Reflect.isFunction(f)) {
		if(params == null) throw "Constructor " + constr + " need parameters";
		return f.apply(e,params);
	}
	if(params != null && params.length != 0) throw "Constructor " + constr + " does not need parameters";
	return f;
};
Type.createEnumIndex = function(e,index,params) {
	var c = e.__constructs__[index];
	if(c == null) throw index + " is not a valid enum constructor index";
	return Type.createEnum(e,c,params);
};
Type.getInstanceFields = function(c) {
	var a = [];
	for(var i in c.prototype) a.push(i);
	HxOverrides.remove(a,"__class__");
	HxOverrides.remove(a,"__properties__");
	return a;
};
Type.getClassFields = function(c) {
	var a = Reflect.fields(c);
	HxOverrides.remove(a,"__name__");
	HxOverrides.remove(a,"__interfaces__");
	HxOverrides.remove(a,"__properties__");
	HxOverrides.remove(a,"__super__");
	HxOverrides.remove(a,"prototype");
	return a;
};
Type.getEnumConstructs = function(e) {
	var a = e.__constructs__;
	return a.slice();
};
Type["typeof"] = function(v) {
	var _g = typeof(v);
	switch(_g) {
	case "boolean":
		return ValueType.TBool;
	case "string":
		return ValueType.TClass(String);
	case "number":
		if(Math.ceil(v) == v % 2147483648.0) return ValueType.TInt;
		return ValueType.TFloat;
	case "object":
		if(v == null) return ValueType.TNull;
		var e = v.__enum__;
		if(e != null) return ValueType.TEnum(e);
		var c;
		if((v instanceof Array) && v.__enum__ == null) c = Array; else c = v.__class__;
		if(c != null) return ValueType.TClass(c);
		return ValueType.TObject;
	case "function":
		if(v.__name__ || v.__ename__) return ValueType.TObject;
		return ValueType.TFunction;
	case "undefined":
		return ValueType.TNull;
	default:
		return ValueType.TUnknown;
	}
};
Type.enumEq = function(a,b) {
	if(a == b) return true;
	try {
		if(a[0] != b[0]) return false;
		var _g1 = 2;
		var _g = a.length;
		while(_g1 < _g) {
			var i = _g1++;
			if(!Type.enumEq(a[i],b[i])) return false;
		}
		var e = a.__enum__;
		if(e != b.__enum__ || e == null) return false;
	} catch( e1 ) {
		return false;
	}
	return true;
};
Type.enumConstructor = function(e) {
	return e[0];
};
Type.enumParameters = function(e) {
	return e.slice(2);
};
Type.enumIndex = function(e) {
	return e[1];
};
Type.allEnums = function(e) {
	return e.__empty_constructs__;
};
var haxe = {};
haxe.Log = function() { };
$hxClasses["haxe.Log"] = haxe.Log;
haxe.Log.__name__ = ["haxe","Log"];
haxe.Log.trace = function(v,infos) {
	js.Boot.__trace(v,infos);
};
haxe.Log.clear = function() {
	js.Boot.__clear_trace();
};
haxe.ds = {};
haxe.ds.BalancedTree = function() {
};
$hxClasses["haxe.ds.BalancedTree"] = haxe.ds.BalancedTree;
haxe.ds.BalancedTree.__name__ = ["haxe","ds","BalancedTree"];
haxe.ds.BalancedTree.prototype = {
	root: null
	,set: function(key,value) {
		this.root = this.setLoop(key,value,this.root);
	}
	,get: function(key) {
		var node = this.root;
		while(node != null) {
			var c = this.compare(key,node.key);
			if(c == 0) return node.value;
			if(c < 0) node = node.left; else node = node.right;
		}
		return null;
	}
	,remove: function(key) {
		try {
			this.root = this.removeLoop(key,this.root);
			return true;
		} catch( e ) {
			if( js.Boot.__instanceof(e,String) ) {
				return false;
			} else throw(e);
		}
	}
	,exists: function(key) {
		var node = this.root;
		while(node != null) {
			var c = this.compare(key,node.key);
			if(c == 0) return true; else if(c < 0) node = node.left; else node = node.right;
		}
		return false;
	}
	,iterator: function() {
		var ret = [];
		this.iteratorLoop(this.root,ret);
		return HxOverrides.iter(ret);
	}
	,keys: function() {
		var ret = [];
		this.keysLoop(this.root,ret);
		return HxOverrides.iter(ret);
	}
	,setLoop: function(k,v,node) {
		if(node == null) return new haxe.ds.TreeNode(null,k,v,null);
		var c = this.compare(k,node.key);
		if(c == 0) return new haxe.ds.TreeNode(node.left,k,v,node.right,node == null?0:node._height); else if(c < 0) {
			var nl = this.setLoop(k,v,node.left);
			return this.balance(nl,node.key,node.value,node.right);
		} else {
			var nr = this.setLoop(k,v,node.right);
			return this.balance(node.left,node.key,node.value,nr);
		}
	}
	,removeLoop: function(k,node) {
		if(node == null) throw "Not_found";
		var c = this.compare(k,node.key);
		if(c == 0) return this.merge(node.left,node.right); else if(c < 0) return this.balance(this.removeLoop(k,node.left),node.key,node.value,node.right); else return this.balance(node.left,node.key,node.value,this.removeLoop(k,node.right));
	}
	,iteratorLoop: function(node,acc) {
		if(node != null) {
			this.iteratorLoop(node.left,acc);
			acc.push(node.value);
			this.iteratorLoop(node.right,acc);
		}
	}
	,keysLoop: function(node,acc) {
		if(node != null) {
			this.keysLoop(node.left,acc);
			acc.push(node.key);
			this.keysLoop(node.right,acc);
		}
	}
	,merge: function(t1,t2) {
		if(t1 == null) return t2;
		if(t2 == null) return t1;
		var t = this.minBinding(t2);
		return this.balance(t1,t.key,t.value,this.removeMinBinding(t2));
	}
	,minBinding: function(t) {
		if(t == null) throw "Not_found"; else if(t.left == null) return t; else return this.minBinding(t.left);
	}
	,removeMinBinding: function(t) {
		if(t.left == null) return t.right; else return this.balance(this.removeMinBinding(t.left),t.key,t.value,t.right);
	}
	,balance: function(l,k,v,r) {
		var hl;
		if(l == null) hl = 0; else hl = l._height;
		var hr;
		if(r == null) hr = 0; else hr = r._height;
		if(hl > hr + 2) {
			if((function($this) {
				var $r;
				var _this = l.left;
				$r = _this == null?0:_this._height;
				return $r;
			}(this)) >= (function($this) {
				var $r;
				var _this1 = l.right;
				$r = _this1 == null?0:_this1._height;
				return $r;
			}(this))) return new haxe.ds.TreeNode(l.left,l.key,l.value,new haxe.ds.TreeNode(l.right,k,v,r)); else return new haxe.ds.TreeNode(new haxe.ds.TreeNode(l.left,l.key,l.value,l.right.left),l.right.key,l.right.value,new haxe.ds.TreeNode(l.right.right,k,v,r));
		} else if(hr > hl + 2) {
			if((function($this) {
				var $r;
				var _this2 = r.right;
				$r = _this2 == null?0:_this2._height;
				return $r;
			}(this)) > (function($this) {
				var $r;
				var _this3 = r.left;
				$r = _this3 == null?0:_this3._height;
				return $r;
			}(this))) return new haxe.ds.TreeNode(new haxe.ds.TreeNode(l,k,v,r.left),r.key,r.value,r.right); else return new haxe.ds.TreeNode(new haxe.ds.TreeNode(l,k,v,r.left.left),r.left.key,r.left.value,new haxe.ds.TreeNode(r.left.right,r.key,r.value,r.right));
		} else return new haxe.ds.TreeNode(l,k,v,r,(hl > hr?hl:hr) + 1);
	}
	,compare: function(k1,k2) {
		return Reflect.compare(k1,k2);
	}
	,toString: function() {
		return "{" + this.root.toString() + "}";
	}
	,__class__: haxe.ds.BalancedTree
};
haxe.ds.TreeNode = function(l,k,v,r,h) {
	if(h == null) h = -1;
	this.left = l;
	this.key = k;
	this.value = v;
	this.right = r;
	if(h == -1) this._height = ((function($this) {
		var $r;
		var _this = $this.left;
		$r = _this == null?0:_this._height;
		return $r;
	}(this)) > (function($this) {
		var $r;
		var _this1 = $this.right;
		$r = _this1 == null?0:_this1._height;
		return $r;
	}(this))?(function($this) {
		var $r;
		var _this2 = $this.left;
		$r = _this2 == null?0:_this2._height;
		return $r;
	}(this)):(function($this) {
		var $r;
		var _this3 = $this.right;
		$r = _this3 == null?0:_this3._height;
		return $r;
	}(this))) + 1; else this._height = h;
};
$hxClasses["haxe.ds.TreeNode"] = haxe.ds.TreeNode;
haxe.ds.TreeNode.__name__ = ["haxe","ds","TreeNode"];
haxe.ds.TreeNode.prototype = {
	left: null
	,right: null
	,key: null
	,value: null
	,_height: null
	,toString: function() {
		return (this.left == null?"":this.left.toString() + ", ") + ("" + Std.string(this.key) + "=" + Std.string(this.value)) + (this.right == null?"":", " + this.right.toString());
	}
	,__class__: haxe.ds.TreeNode
};
haxe.ds.EnumValueMap = function() {
	haxe.ds.BalancedTree.call(this);
};
$hxClasses["haxe.ds.EnumValueMap"] = haxe.ds.EnumValueMap;
haxe.ds.EnumValueMap.__name__ = ["haxe","ds","EnumValueMap"];
haxe.ds.EnumValueMap.__interfaces__ = [IMap];
haxe.ds.EnumValueMap.__super__ = haxe.ds.BalancedTree;
haxe.ds.EnumValueMap.prototype = $extend(haxe.ds.BalancedTree.prototype,{
	compare: function(k1,k2) {
		var d = k1[1] - k2[1];
		if(d != 0) return d;
		var p1 = k1.slice(2);
		var p2 = k2.slice(2);
		if(p1.length == 0 && p2.length == 0) return 0;
		return this.compareArgs(p1,p2);
	}
	,compareArgs: function(a1,a2) {
		var ld = a1.length - a2.length;
		if(ld != 0) return ld;
		var _g1 = 0;
		var _g = a1.length;
		while(_g1 < _g) {
			var i = _g1++;
			var d = this.compareArg(a1[i],a2[i]);
			if(d != 0) return d;
		}
		return 0;
	}
	,compareArg: function(v1,v2) {
		if(Reflect.isEnumValue(v1) && Reflect.isEnumValue(v2)) return this.compare(v1,v2); else if((v1 instanceof Array) && v1.__enum__ == null && ((v2 instanceof Array) && v2.__enum__ == null)) return this.compareArgs(v1,v2); else return Reflect.compare(v1,v2);
	}
	,__class__: haxe.ds.EnumValueMap
});
haxe.ds._HashMap = {};
haxe.ds._HashMap.HashMap_Impl_ = function() { };
$hxClasses["haxe.ds._HashMap.HashMap_Impl_"] = haxe.ds._HashMap.HashMap_Impl_;
haxe.ds._HashMap.HashMap_Impl_.__name__ = ["haxe","ds","_HashMap","HashMap_Impl_"];
haxe.ds._HashMap.HashMap_Impl_._new = function() {
	return { keys : new haxe.ds.IntMap(), values : new haxe.ds.IntMap()};
};
haxe.ds._HashMap.HashMap_Impl_.set = function(this1,k,v) {
	this1.keys.set(k.hashCode(),k);
	this1.values.set(k.hashCode(),v);
};
haxe.ds._HashMap.HashMap_Impl_.get = function(this1,k) {
	return this1.values.get(k.hashCode());
};
haxe.ds._HashMap.HashMap_Impl_.exists = function(this1,k) {
	return this1.values.exists(k.hashCode());
};
haxe.ds._HashMap.HashMap_Impl_.remove = function(this1,k) {
	this1.values.remove(k.hashCode());
	return this1.keys.remove(k.hashCode());
};
haxe.ds._HashMap.HashMap_Impl_.keys = function(this1) {
	return this1.keys.iterator();
};
haxe.ds._HashMap.HashMap_Impl_.iterator = function(this1) {
	return this1.values.iterator();
};
haxe.ds.IntMap = function() {
	this.h = { };
};
$hxClasses["haxe.ds.IntMap"] = haxe.ds.IntMap;
haxe.ds.IntMap.__name__ = ["haxe","ds","IntMap"];
haxe.ds.IntMap.__interfaces__ = [IMap];
haxe.ds.IntMap.prototype = {
	h: null
	,set: function(key,value) {
		this.h[key] = value;
	}
	,get: function(key) {
		return this.h[key];
	}
	,exists: function(key) {
		return this.h.hasOwnProperty(key);
	}
	,remove: function(key) {
		if(!this.h.hasOwnProperty(key)) return false;
		delete(this.h[key]);
		return true;
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key | 0);
		}
		return HxOverrides.iter(a);
	}
	,iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref[i];
		}};
	}
	,toString: function() {
		var s = new StringBuf();
		s.b += "{";
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			if(i == null) s.b += "null"; else s.b += "" + i;
			s.b += " => ";
			s.add(Std.string(this.get(i)));
			if(it.hasNext()) s.b += ", ";
		}
		s.b += "}";
		return s.b;
	}
	,__class__: haxe.ds.IntMap
};
haxe.ds.ObjectMap = function() {
	this.h = { };
	this.h.__keys__ = { };
};
$hxClasses["haxe.ds.ObjectMap"] = haxe.ds.ObjectMap;
haxe.ds.ObjectMap.__name__ = ["haxe","ds","ObjectMap"];
haxe.ds.ObjectMap.__interfaces__ = [IMap];
haxe.ds.ObjectMap.assignId = function(obj) {
	return obj.__id__ = ++haxe.ds.ObjectMap.count;
};
haxe.ds.ObjectMap.getId = function(obj) {
	return obj.__id__;
};
haxe.ds.ObjectMap.prototype = {
	h: null
	,set: function(key,value) {
		var id = key.__id__ || (key.__id__ = ++haxe.ds.ObjectMap.count);
		this.h[id] = value;
		this.h.__keys__[id] = key;
	}
	,get: function(key) {
		return this.h[key.__id__];
	}
	,exists: function(key) {
		return this.h.__keys__[key.__id__] != null;
	}
	,remove: function(key) {
		var id = key.__id__;
		if(this.h.__keys__[id] == null) return false;
		delete(this.h[id]);
		delete(this.h.__keys__[id]);
		return true;
	}
	,keys: function() {
		var a = [];
		for( var key in this.h.__keys__ ) {
		if(this.h.hasOwnProperty(key)) a.push(this.h.__keys__[key]);
		}
		return HxOverrides.iter(a);
	}
	,iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref[i.__id__];
		}};
	}
	,toString: function() {
		var s = new StringBuf();
		s.b += "{";
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			s.add(Std.string(i));
			s.b += " => ";
			s.add(Std.string(this.h[i.__id__]));
			if(it.hasNext()) s.b += ", ";
		}
		s.b += "}";
		return s.b;
	}
	,__class__: haxe.ds.ObjectMap
};
haxe.ds.StringMap = function() {
	this.h = { };
};
$hxClasses["haxe.ds.StringMap"] = haxe.ds.StringMap;
haxe.ds.StringMap.__name__ = ["haxe","ds","StringMap"];
haxe.ds.StringMap.__interfaces__ = [IMap];
haxe.ds.StringMap.prototype = {
	h: null
	,set: function(key,value) {
		this.h["$" + key] = value;
	}
	,get: function(key) {
		return this.h["$" + key];
	}
	,exists: function(key) {
		return this.h.hasOwnProperty("$" + key);
	}
	,remove: function(key) {
		key = "$" + key;
		if(!this.h.hasOwnProperty(key)) return false;
		delete(this.h[key]);
		return true;
	}
	,keys: function() {
		var a = [];
		for( var key in this.h ) {
		if(this.h.hasOwnProperty(key)) a.push(key.substr(1));
		}
		return HxOverrides.iter(a);
	}
	,iterator: function() {
		return { ref : this.h, it : this.keys(), hasNext : function() {
			return this.it.hasNext();
		}, next : function() {
			var i = this.it.next();
			return this.ref["$" + i];
		}};
	}
	,toString: function() {
		var s = new StringBuf();
		s.b += "{";
		var it = this.keys();
		while( it.hasNext() ) {
			var i = it.next();
			if(i == null) s.b += "null"; else s.b += "" + i;
			s.b += " => ";
			s.add(Std.string(this.get(i)));
			if(it.hasNext()) s.b += ", ";
		}
		s.b += "}";
		return s.b;
	}
	,__class__: haxe.ds.StringMap
};
haxe.ds.WeakMap = function() {
	throw "Not implemented for this platform";
};
$hxClasses["haxe.ds.WeakMap"] = haxe.ds.WeakMap;
haxe.ds.WeakMap.__name__ = ["haxe","ds","WeakMap"];
haxe.ds.WeakMap.__interfaces__ = [IMap];
haxe.ds.WeakMap.prototype = {
	set: function(key,value) {
	}
	,get: function(key) {
		return null;
	}
	,exists: function(key) {
		return false;
	}
	,remove: function(key) {
		return false;
	}
	,keys: function() {
		return null;
	}
	,iterator: function() {
		return null;
	}
	,toString: function() {
		return null;
	}
	,__class__: haxe.ds.WeakMap
};
haxe.languageservices = {};
haxe.languageservices.HaxeLanguageServices = function(vfs) {
	this.classPaths = ["."];
	this.contexts = new haxe.ds.StringMap();
	this.types = new haxe.languageservices.type.HaxeTypes();
	this.vfs = vfs;
};
$hxClasses["haxe.languageservices.HaxeLanguageServices"] = haxe.languageservices.HaxeLanguageServices;
haxe.languageservices.HaxeLanguageServices.__name__ = ["haxe","languageservices","HaxeLanguageServices"];
haxe.languageservices.HaxeLanguageServices.convToEntry = function(name,result) {
	return new haxe.languageservices.CompEntry(name,haxe.languageservices.HaxeLanguageServices.convToType(result.type),result.hasValue,result.value);
};
haxe.languageservices.HaxeLanguageServices.convToType = function(type) {
	return new haxe.languageservices.CompType(type.type.fqName,type.parameters != null?(function($this) {
		var $r;
		var _g = [];
		{
			var _g1 = 0;
			var _g2 = type.parameters;
			while(_g1 < _g2.length) {
				var i = _g2[_g1];
				++_g1;
				_g.push(haxe.languageservices.HaxeLanguageServices.convToType(i));
			}
		}
		$r = _g;
		return $r;
	}(this)):null);
};
haxe.languageservices.HaxeLanguageServices.convUsageType = function(type) {
	switch(type[1]) {
	case 0:
		return haxe.languageservices.CompReferenceType.Declaration;
	case 2:
		return haxe.languageservices.CompReferenceType.Read;
	case 1:
		return haxe.languageservices.CompReferenceType.Update;
	}
};
haxe.languageservices.HaxeLanguageServices.convertPos = function(pos) {
	return new haxe.languageservices.CompPosition(pos.min,pos.max);
};
haxe.languageservices.HaxeLanguageServices.prototype = {
	vfs: null
	,types: null
	,contexts: null
	,classPaths: null
	,updateHaxeFile: function(path) {
		try {
			var context;
			if(!this.contexts.exists(path)) {
				var v = new haxe.languageservices.CompFileContext(this.types);
				this.contexts.set(path,v);
				v;
			}
			context = this.contexts.get(path);
			var fileContent = this.vfs.readString(path);
			context.setFile(fileContent,path);
			context.update();
		} catch( e ) {
			throw new haxe.languageservices.CompError(new haxe.languageservices.CompPosition(0,0),"unexpected error: " + Std.string(e));
		}
	}
	,getCompletionAt: function(path,offset) {
		var context = this.getContext(path);
		var locals = context.completionScope.locateIndex(offset).getLocals();
		return new haxe.languageservices.CompList((function($this) {
			var $r;
			var _g = [];
			{
				var _g1 = 0;
				while(_g1 < locals.length) {
					var l = locals[_g1];
					++_g1;
					_g.push(haxe.languageservices.HaxeLanguageServices.convToEntry(l.name,l.getResult()));
				}
			}
			$r = _g;
			return $r;
		}(this)));
	}
	,getReferencesAt: function(path,offset) {
		var context = this.getContext(path);
		var id = this.getIdAt(path,offset);
		if(id == null) return null;
		var entry = context.completionScope.locateIndex(offset).getLocal(id.name);
		if(entry == null) return null;
		var _g = [];
		var _g1 = 0;
		var _g2 = entry.usages;
		while(_g1 < _g2.length) {
			var usage = _g2[_g1];
			++_g1;
			_g.push({ pos : haxe.languageservices.HaxeLanguageServices.convertPos(usage.node.pos), type : haxe.languageservices.HaxeLanguageServices.convUsageType(usage.type)});
		}
		return _g;
	}
	,getIdAt: function(path,offset) {
		var context = this.getContext(path);
		var id = context.completionScope.getIdentifierAt(offset);
		if(id == null) return null;
		return { pos : haxe.languageservices.HaxeLanguageServices.convertPos(id.pos), name : id.name};
	}
	,getCallInfoAt: function(path,offset) {
		return null;
	}
	,getErrors: function(path) {
		var context = this.getContext(path);
		var _g = [];
		var _g1 = 0;
		var _g2 = context.errors.errors;
		while(_g1 < _g2.length) {
			var error = _g2[_g1];
			++_g1;
			_g.push(new haxe.languageservices.CompError(haxe.languageservices.HaxeLanguageServices.convertPos(error.pos),error.message));
		}
		return _g;
	}
	,getContext: function(path) {
		var context = this.contexts.get(path);
		if(context == null) throw "Can't find context for file " + path;
		return context;
	}
	,__class__: haxe.languageservices.HaxeLanguageServices
};
haxe.languageservices.grammar = {};
haxe.languageservices.grammar.Grammar = function() { };
$hxClasses["haxe.languageservices.grammar.Grammar"] = haxe.languageservices.grammar.Grammar;
haxe.languageservices.grammar.Grammar.__name__ = ["haxe","languageservices","grammar","Grammar"];
haxe.languageservices.grammar.Grammar.prototype = {
	term: function(z,conv) {
		if(typeof(z) == "string") return haxe.languageservices.grammar.Term.TLit(js.Boot.__cast(z , String),conv);
		if(js.Boot.__instanceof(z,EReg)) throw "unsupported " + Std.string(z);
		if(js.Boot.__instanceof(z,haxe.languageservices.grammar.TermRef)) return haxe.languageservices.grammar.Term.TRef(z);
		return js.Boot.__cast(z , haxe.languageservices.grammar.Term);
	}
	,_term: function(z) {
		return this.term(z);
	}
	,createRef: function() {
		return haxe.languageservices.grammar.Term.TRef(new haxe.languageservices.grammar.TermRef());
	}
	,setRef: function(ref,value) {
		switch(ref[1]) {
		case 2:
			var t = ref[2];
			t.term = value;
			break;
		default:
			throw "Invalid ref";
		}
	}
	,simplify: function(znode,term) {
		return znode;
	}
	,identity: function(v) {
		return v;
	}
	,sure: function() {
		return haxe.languageservices.grammar.Term.TSure;
	}
	,seq: function(v,conv) {
		return haxe.languageservices.grammar.Term.TSeq(v.map($bind(this,this._term)),conv);
	}
	,seqi: function(v) {
		return this.seq(v,function(v1) {
			return v1[0];
		});
	}
	,any: function(v) {
		return haxe.languageservices.grammar.Term.TAny(v.map($bind(this,this._term)),null);
	}
	,anyRecover: function(v,recover) {
		return haxe.languageservices.grammar.Term.TAny(v.map($bind(this,this._term)),recover.map($bind(this,this._term)));
	}
	,opt: function(v) {
		return haxe.languageservices.grammar.Term.TOpt(this.term(v),null);
	}
	,optError: function(v,message) {
		return haxe.languageservices.grammar.Term.TOpt(this.term(v),message);
	}
	,list: function(item,separator,minCount,allowExtraSeparator,conv) {
		return haxe.languageservices.grammar.Term.TList(this.term(item),this.term(separator),minCount,allowExtraSeparator,conv);
	}
	,list2: function(item,minCount,conv) {
		return haxe.languageservices.grammar.Term.TList(this.term(item),null,minCount,true,conv);
	}
	,skipNonGrammar: function(str) {
	}
	,parseStringNode: function(t,str,file,errors) {
		var result = this.parseString(t,str,file,errors);
		switch(result[1]) {
		case 1:case 0:
			return null;
		case 2:
			var v = result[2];
			return v;
		}
	}
	,parseString: function(t,str,file,errors) {
		return this.parse(t,new haxe.languageservices.node.Reader(str,file),errors);
	}
	,describe: function(t) {
		switch(t[1]) {
		case 0:
			var lit = t[2];
			return "\"" + lit + "\"";
		case 1:
			var name = t[2];
			return "" + name;
		case 2:
			var ref = t[2];
			return this.describe(ref.term);
		case 6:
			var item = t[2];
			return this.describe(item);
		case 5:
			var items = t[2];
			return this.describe(items[0]);
		case 7:
			var item1 = t[2];
			return this.describe(item1);
		case 3:
			var items1 = t[2];
			return ((function($this) {
				var $r;
				var _g = [];
				{
					var _g1 = 0;
					while(_g1 < items1.length) {
						var item2 = items1[_g1];
						++_g1;
						_g.push($this.describe(item2));
					}
				}
				$r = _g;
				return $r;
			}(this))).join(" or ");
		default:
			return "???";
		}
	}
	,parse: function(t,reader,errors) {
		if(errors == null) errors = new haxe.languageservices.grammar.HaxeErrors();
		var result = this._parse(t,reader,errors);
		if(!reader.eof()) errors.add(new haxe.languageservices.grammar.ParserError(reader.createPos(),"unexpected end of file"));
		return result;
	}
	,_parse: function(t,reader,errors) {
		var _g = this;
		this.skipNonGrammar(reader);
		var start = reader.pos;
		var gen = function(result,conv) {
			if(result == null) return haxe.languageservices.grammar.Result.RUnmatched(0,start);
			if(conv == null) return haxe.languageservices.grammar.Result.RMatched;
			var rresult = conv(result);
			if(js.Boot.__instanceof(rresult,haxe.languageservices.grammar.NNode)) return haxe.languageservices.grammar.Result.RMatchedValue(_g.simplify(rresult,t));
			return haxe.languageservices.grammar.Result.RMatchedValue(_g.simplify(new haxe.languageservices.grammar.NNode(reader.createPos(start,reader.pos),rresult),t));
		};
		switch(t[1]) {
		case 0:
			var conv1 = t[3];
			var lit = t[2];
			return gen(reader.matchLit(lit),conv1);
		case 1:
			var conv2 = t[4];
			var reg = t[3];
			var name = t[2];
			return gen(reader.matchEReg(reg),conv2);
		case 2:
			var ref = t[2];
			return this._parse(ref.term,reader,errors);
		case 6:
			var error = t[3];
			var item = t[2];
			{
				var _g1 = this._parse(item,reader,errors);
				switch(_g1[1]) {
				case 2:
					var v = _g1[2];
					return haxe.languageservices.grammar.Result.RMatchedValue(v);
				case 1:
					if(error != null) errors.add(new haxe.languageservices.grammar.ParserError(reader.createPos(start,reader.pos),error));
					return haxe.languageservices.grammar.Result.RMatchedValue(null);
				default:
					return haxe.languageservices.grammar.Result.RMatchedValue(null);
				}
			}
			break;
		case 3:
			var recover = t[3];
			var items = t[2];
			var maxValidCount = 0;
			var maxValidPos = start;
			var maxTerm = null;
			var _g2 = 0;
			while(_g2 < items.length) {
				var item1 = items[_g2];
				++_g2;
				var r = this._parse(item1,reader,errors);
				switch(r[1]) {
				case 1:
					var lastPos = r[3];
					var validCount = r[2];
					if(validCount > maxValidCount) {
						maxTerm = item1;
						maxValidCount = validCount;
						maxValidPos = lastPos;
					}
					break;
				default:
					return r;
				}
			}
			if(maxValidCount > 0) {
			}
			return haxe.languageservices.grammar.Result.RUnmatched(maxValidCount,maxValidPos);
		case 5:
			var conv3 = t[3];
			var items1 = t[2];
			var results = [];
			var count = 0;
			var sure = false;
			var lastItemIndex = reader.pos;
			var _g3 = 0;
			try {
				while(_g3 < items1.length) {
					var item2 = items1[_g3];
					++_g3;
					if(Type.enumEq(item2,haxe.languageservices.grammar.Term.TSure)) {
						sure = true;
						continue;
					}
					var itemIndex = reader.pos;
					var r1 = this._parse(item2,reader,errors);
					switch(r1[1]) {
					case 1:
						var lastPos1 = r1[3];
						var validCount1 = r1[2];
						if(sure) {
							errors.add(new haxe.languageservices.grammar.ParserError(reader.createPos(lastItemIndex,lastItemIndex),"expected " + this.describe(item2)));
							reader.pos = lastPos1;
							throw "__break__";
						} else {
							reader.pos = start;
							return haxe.languageservices.grammar.Result.RUnmatched(validCount1 + count,lastPos1);
						}
						break;
					case 0:
						break;
					case 2:
						var v1 = r1[2];
						results.push(v1);
						if(v1 != null) lastItemIndex = v1.pos.max;
						break;
					}
					count++;
				}
			} catch( e ) { if( e != "__break__" ) throw e; }
			return gen(results,conv3);
		case 7:
			var conv4 = t[6];
			var allowExtraSeparator = t[5];
			var minCount = t[4];
			var separator = t[3];
			var item3 = t[2];
			var items2 = [];
			var count1 = 0;
			var separatorCount = 0;
			try {
				while(true) {
					var resultItem = this._parse(item3,reader,errors);
					switch(resultItem[1]) {
					case 1:
						throw "__break__";
						break;
					case 0:
						break;
					case 2:
						var value = resultItem[2];
						items2.push(value);
						break;
					}
					count1++;
					if(separator != null) {
						var resultSep = this._parse(separator,reader,errors);
						switch(resultSep[1]) {
						case 1:
							throw "__break__";
							break;
						default:
						}
						separatorCount++;
					}
				}
			} catch( e ) { if( e != "__break__" ) throw e; }
			var unmatched = false;
			if(count1 < minCount) unmatched = true;
			if(!allowExtraSeparator) {
				if(separatorCount >= count1) unmatched = true;
			}
			if(unmatched) {
				var lastPos2 = reader.pos;
				return haxe.languageservices.grammar.Result.RUnmatched(count1,lastPos2);
			}
			return gen(items2,conv4);
		default:
			throw "Unmatched " + Std.string(t);
		}
	}
	,__class__: haxe.languageservices.grammar.Grammar
};
haxe.languageservices.grammar.HaxeGrammar = function() {
	this.singleLineComments = new EReg("^//(.*?)(\n|$)","");
	this.spaces = new EReg("^\\s+","");
	if(haxe.languageservices.grammar.HaxeGrammar.opsPriority == null) {
		haxe.languageservices.grammar.HaxeGrammar.opsPriority = new haxe.ds.StringMap();
		var oops = [["%"],["*","/"],["+","-"],["<<",">>",">>>"],["|","&","^"],["==","!=",">","<",">=","<="],["..."],["&&"],["||"],["=","+=","-=","*=","/=","%=","<<=",">>=",">>>=","|=","&=","^="]];
		var _g1 = 0;
		var _g = oops.length;
		while(_g1 < _g) {
			var priority = _g1++;
			var _g2 = 0;
			var _g3 = oops[priority];
			while(_g2 < _g3.length) {
				var i = _g3[_g2];
				++_g2;
				haxe.languageservices.grammar.HaxeGrammar.opsPriority.set(i,priority);
				priority;
			}
		}
	}
	var rlist = function(v) {
		return haxe.languageservices.node.Node.NList(v);
	};
	var $int = haxe.languageservices.grammar.Term.TReg("int",new EReg("^\\d+",""),function(v1) {
		return haxe.languageservices.node.Node.NConst(haxe.languageservices.node.Const.CInt(Std.parseInt(v1)));
	});
	var identifier = haxe.languageservices.grammar.Term.TReg("identifier",new EReg("^[a-zA-Z]\\w*",""),function(v2) {
		return haxe.languageservices.node.Node.NId(v2);
	});
	this.fqName = this.list(identifier,".",1,false,function(v3) {
		return haxe.languageservices.node.Node.NIdList(v3);
	});
	this.ints = this.list($int,",",1,false,function(v4) {
		return haxe.languageservices.node.Node.NConstList(v4);
	});
	this.packageDecl = this.seq(["package",this.sure(),this.fqName,";"],this.buildNode("NPackage"));
	this.importDecl = this.seq(["import",this.sure(),this.fqName,";"],this.buildNode("NImport"));
	this.usingDecl = this.seq(["using",this.sure(),this.fqName,";"],this.buildNode("NUsing"));
	this.expr = this.createRef();
	this.stm = this.createRef();
	var ifStm = this.seq(["if",this.sure(),"(",this.expr,")",this.stm,this.opt(this.seqi(["else",this.stm]))],this.buildNode("NIf"));
	var forStm = this.seq(["for",this.sure(),"(",identifier,"in",this.expr,")",this.stm],this.buildNode("NFor"));
	var whileStm = this.seq(["while",this.sure(),"(",this.expr,")",this.stm],this.buildNode("NWhile"));
	var doWhileStm = this.seq(["do",this.sure(),this.stm,"while","(",this.expr,")",this.optError2(";")],this.buildNode("NDoWhile"));
	var breakStm = this.seq(["break",this.sure(),";"],this.buildNode("NBreak"));
	var continueStm = this.seq(["continue",this.sure(),";"],this.buildNode("NContinue"));
	var returnStm = this.seq(["return",this.sure(),this.opt(this.expr),";"],this.buildNode("NReturn"));
	var blockStm = this.seq(["{",this.list2(this.stm,0,rlist),"}"],this.buildNode2("NBlock"));
	var switchCaseStm = this.seq(["case",this.sure(),identifier,":"],this.buildNode2("NCase"));
	var switchDefaultStm = this.seq(["default",this.sure(),":"],this.buildNode2("NDefault"));
	var switchStm = this.seq(["switch",this.sure(),"(",this.expr,")","{",this.list2(this.any([switchCaseStm,switchDefaultStm,this.stm]),0),"}"],this.buildNode2("NSwitch"));
	var parenExpr = this.seqi(["(",this.sure(),this.expr,")"]);
	var constant = this.any([$int,identifier]);
	var type = this.createRef();
	var typeParamItem = type;
	var typeParamDecl = this.seq(["<",this.sure(),this.list(typeParamItem,",",1,false,rlist),">"],this.buildNode2("NTypeParams"));
	var optType = this.opt(this.seq([":",this.sure(),type],this.buildNode("NWrapper")));
	var typeName = this.seq([identifier,optType],this.buildNode("NIdWithType"));
	var typeNameList = this.list(typeName,",",0,false,rlist);
	var typeBase = this.seq([identifier,this.opt(typeParamDecl)],rlist);
	this.setRef(type,this.any([this.list(typeBase,"->",1,false,rlist),this.seq(["{",typeNameList,"}"],rlist)]));
	var propertyDecl = this.seq(["(",this.sure(),identifier,",",identifier,")"],this.buildNode("NProperty"));
	var varStm = this.seq(["var",this.sure(),identifier,this.opt(propertyDecl),optType,this.opt(this.seqi(["=",this.expr])),this.optError(";","expected semicolon")],this.buildNode("NVar"));
	var objectItem = this.seq([identifier,":",this.sure(),this.expr],this.buildNode("NObjectItem"));
	var arrayExpr = this.seq(["[",this.list(this.expr,",",0,true,rlist),"]"],this.buildNode2("NArray"));
	var objectExpr = this.seq(["{",this.list(objectItem,",",0,true,rlist),"}"],this.buildNode2("NObject"));
	var literal = this.any([constant,arrayExpr,objectExpr]);
	var unaryOp = this.any([this.operator("++"),this.operator("--"),this.operator("+"),this.operator("-")]);
	var binaryOp = this.any((function($this) {
		var $r;
		var _g4 = [];
		{
			var _g11 = 0;
			var _g21 = ["...","<=",">=","&&","||","==","!=","+","?",":","-","*","/","%","<",">","="];
			while(_g11 < _g21.length) {
				var i1 = _g21[_g11];
				++_g11;
				_g4.push($this.operator(i1));
			}
		}
		$r = _g4;
		return $r;
	}(this)));
	var primaryExpr = this.createRef();
	var unaryExpr = this.seq([unaryOp,primaryExpr],this.buildNode("NUnary"));
	var exprCommaList = this.list(this.expr,",",1,false,rlist);
	var arrayAccess = this.seq(["[",this.expr,"]"],this.buildNode("NAccessPart"));
	var fieldAccess = this.seq([".",identifier],this.buildNode("NAccessPart"));
	var callPart = this.seq(["(",exprCommaList,")"],this.buildNode("NCallPart"));
	var binaryPart = this.seq([binaryOp,this.expr],this.buildNode("NBinOpPart"));
	this.setRef(primaryExpr,this.any([parenExpr,unaryExpr,this.seq(["new",this.sure(),identifier,callPart],this.buildNode("NNew")),this.seq([constant,this.list2(this.any([fieldAccess,arrayAccess,callPart,binaryPart]),0,rlist)],this.buildNode("NAccessList"))]));
	this.setRef(this.expr,this.any([primaryExpr,literal]));
	this.setRef(this.stm,this.anyRecover([varStm,blockStm,ifStm,switchStm,forStm,whileStm,doWhileStm,breakStm,continueStm,returnStm,this.seq([primaryExpr,this.sure(),";"],rlist)],[";","}"]));
	var memberModifier = this.any([this.litK("static"),this.litK("public"),this.litK("private"),this.litK("override"),this.litK("inline")]);
	var argDecl = this.seq([this.opt(this.litK("?")),identifier,optType,this.opt(this.seqi(["=",this.expr]))],this.buildNode("NFunctionArg"));
	var functionDecl = this.seq(["function",this.sure(),identifier,"(",this.opt(this.list(argDecl,",",0,false,rlist)),")",optType,this.stm],this.buildNode("NFunction"));
	var memberDecl = this.seq([this.opt(this.list2(memberModifier,0,rlist)),this.any([varStm,functionDecl])],this.buildNode("NMember"));
	var extendsDecl = this.seq(["extends",this.sure(),this.fqName,this.opt(typeParamDecl)],this.buildNode("NExtends"));
	var implementsDecl = this.seq(["implements",this.sure(),this.fqName,this.opt(typeParamDecl)],this.buildNode("NImplements"));
	var extendsImplementsList = this.list2(this.any([extendsDecl,implementsDecl]),0,rlist);
	var classDecl = this.seq(["class",this.sure(),identifier,this.opt(typeParamDecl),this.opt(extendsImplementsList),"{",this.list2(memberDecl,0,rlist),"}"],this.buildNode("NClass"));
	var interfaceDecl = this.seq(["interface",this.sure(),identifier,this.opt(typeParamDecl),this.opt(extendsImplementsList),"{",this.list2(memberDecl,0,rlist),"}"],this.buildNode("NInterface"));
	var typedefDecl = this.seq(["typedef",this.sure(),identifier,"=",type],this.buildNode("NTypedef"));
	var enumDecl = this.seq(["enum",this.sure(),identifier,"{","}"],this.buildNode("NEnum"));
	var abstractDecl = this.seq(["abstract",this.sure(),identifier,"{","}"],this.buildNode("NAbstract"));
	var typeDecl = this.any([classDecl,interfaceDecl,typedefDecl,enumDecl,abstractDecl]);
	this.program = this.list2(this.any([this.packageDecl,this.importDecl,this.usingDecl,typeDecl]),0,this.buildNode2("NFile"));
};
$hxClasses["haxe.languageservices.grammar.HaxeGrammar"] = haxe.languageservices.grammar.HaxeGrammar;
haxe.languageservices.grammar.HaxeGrammar.__name__ = ["haxe","languageservices","grammar","HaxeGrammar"];
haxe.languageservices.grammar.HaxeGrammar.opsPriority = null;
haxe.languageservices.grammar.HaxeGrammar.__super__ = haxe.languageservices.grammar.Grammar;
haxe.languageservices.grammar.HaxeGrammar.prototype = $extend(haxe.languageservices.grammar.Grammar.prototype,{
	ints: null
	,fqName: null
	,packageDecl: null
	,importDecl: null
	,usingDecl: null
	,expr: null
	,stm: null
	,program: null
	,buildNode: function(name) {
		return function(v) {
			return Type.createEnum(haxe.languageservices.node.Node,name,v);
		};
	}
	,buildNode2: function(name) {
		return function(v) {
			return Type.createEnum(haxe.languageservices.node.Node,name,[v]);
		};
	}
	,simplify: function(znode,term) {
		if(!js.Boot.__instanceof(znode.node,haxe.languageservices.node.Node)) throw "Invalid simplify: " + Std.string(znode) + ": " + Std.string(term) + " : " + znode.pos.get_text();
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 29:
				var n = _g[2];
				return this.simplify(n,term);
			case 42:
				var accessors = _g[3];
				var node = _g[2];
				{
					var _g1 = accessors.node;
					switch(_g1[1]) {
					case 4:
						var items = _g1[2];
						switch(_g1[2].length) {
						case 0:
							return node;
						default:
							var lnode = node;
							var _g2 = 0;
							while(_g2 < items.length) {
								var item = items[_g2];
								++_g2;
								var lpos = haxe.languageservices.node.Position.combine(lnode.pos,item.pos);
								{
									var _g3 = item.node;
									switch(_g3[1]) {
									case 38:
										var rnode = _g3[2];
										lnode = this.simplify(new haxe.languageservices.grammar.NNode(lpos,haxe.languageservices.node.Node.NCall(lnode,rnode)),term);
										break;
									case 39:
										var rnode1 = _g3[3];
										var op = _g3[2];
										var opp = haxe.languageservices.node.NodeTools.getId(op);
										{
											var _g4 = rnode1.node;
											switch(_g4[1]) {
											case 41:
												var r = _g4[4];
												var o = _g4[3];
												var l = _g4[2];
												var oldPriority = haxe.languageservices.grammar.HaxeGrammar.opsPriority.get(o);
												var newPriority = haxe.languageservices.grammar.HaxeGrammar.opsPriority.get(opp);
												if(oldPriority < newPriority) lnode = this.simplify(new haxe.languageservices.grammar.NNode(lpos,haxe.languageservices.node.Node.NBinOp(lnode,opp,rnode1)),term); else lnode = this.simplify(new haxe.languageservices.grammar.NNode(lpos,haxe.languageservices.node.Node.NBinOp(new haxe.languageservices.grammar.NNode(lpos,haxe.languageservices.node.Node.NBinOp(lnode,opp,l)),opp,r)),term);
												break;
											default:
												lnode = this.simplify(new haxe.languageservices.grammar.NNode(lpos,haxe.languageservices.node.Node.NBinOp(lnode,opp,rnode1)),term);
											}
										}
										break;
									default:
										throw "simplify (I): " + Std.string(item);
									}
								}
							}
							return lnode;
						}
						break;
					default:
						throw "simplify (II): " + Std.string(accessors);
					}
				}
				break;
			default:
			}
		}
		return znode;
	}
	,operator: function(v) {
		return this.term(v,this.buildNode2("NOp"));
	}
	,optError2: function(tok) {
		return this.optError(tok,"expected " + tok);
	}
	,litS: function(z) {
		return haxe.languageservices.grammar.Term.TLit(z,function(v) {
			return haxe.languageservices.node.Node.NId(z);
		});
	}
	,litK: function(z) {
		return haxe.languageservices.grammar.Term.TLit(z,function(v) {
			return haxe.languageservices.node.Node.NKeyword(z);
		});
	}
	,spaces: null
	,singleLineComments: null
	,skipNonGrammar: function(str) {
		str.matchEReg(this.spaces);
		str.matchStartEnd("/*","*/");
		str.matchEReg(this.spaces);
		str.matchEReg(this.singleLineComments);
		str.matchEReg(this.spaces);
	}
	,__class__: haxe.languageservices.grammar.HaxeGrammar
});
haxe.languageservices.node = {};
haxe.languageservices.node.Node = $hxClasses["haxe.languageservices.node.Node"] = { __ename__ : ["haxe","languageservices","node","Node"], __constructs__ : ["NId","NKeyword","NOp","NConst","NList","NListDummy","NIdList","NConstList","NIf","NArray","NObjectItem","NObject","NBlock","NFor","NWhile","NDoWhile","NSwitch","NCase","NDefault","NPackage","NImport","NUsing","NClass","NInterface","NTypedef","NEnum","NAbstract","NExtends","NImplements","NWrapper","NProperty","NVar","NFunctionArg","NFunction","NContinue","NBreak","NReturn","NAccessPath","NCallPart","NBinOpPart","NCall","NBinOp","NAccessList","NMember","NNew","NUnary","NIdWithType","NTypeParams","NFile"] };
haxe.languageservices.node.Node.NId = function(value) { var $x = ["NId",0,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NKeyword = function(value) { var $x = ["NKeyword",1,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NOp = function(value) { var $x = ["NOp",2,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NConst = function(value) { var $x = ["NConst",3,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NList = function(value) { var $x = ["NList",4,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NListDummy = function(value) { var $x = ["NListDummy",5,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NIdList = function(value) { var $x = ["NIdList",6,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NConstList = function(items) { var $x = ["NConstList",7,items]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NIf = function(cond,trueExpr,falseExpr) { var $x = ["NIf",8,cond,trueExpr,falseExpr]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NArray = function(items) { var $x = ["NArray",9,items]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NObjectItem = function(key,value) { var $x = ["NObjectItem",10,key,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NObject = function(items) { var $x = ["NObject",11,items]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NBlock = function(items) { var $x = ["NBlock",12,items]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NFor = function(iteratorName,iteratorExpr,body) { var $x = ["NFor",13,iteratorName,iteratorExpr,body]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NWhile = function(cond,body) { var $x = ["NWhile",14,cond,body]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NDoWhile = function(body,cond) { var $x = ["NDoWhile",15,body,cond]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NSwitch = function(subject,cases) { var $x = ["NSwitch",16,subject,cases]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NCase = function(item) { var $x = ["NCase",17,item]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NDefault = ["NDefault",18];
haxe.languageservices.node.Node.NDefault.toString = $estr;
haxe.languageservices.node.Node.NDefault.__enum__ = haxe.languageservices.node.Node;
haxe.languageservices.node.Node.NPackage = function(fqName) { var $x = ["NPackage",19,fqName]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NImport = function(fqName) { var $x = ["NImport",20,fqName]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NUsing = function(fqName) { var $x = ["NUsing",21,fqName]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NClass = function(name,typeParams,extendsImplementsList,decls) { var $x = ["NClass",22,name,typeParams,extendsImplementsList,decls]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NInterface = function(name,typeParams,extendsImplementsList,decls) { var $x = ["NInterface",23,name,typeParams,extendsImplementsList,decls]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NTypedef = function(name) { var $x = ["NTypedef",24,name]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NEnum = function(name) { var $x = ["NEnum",25,name]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NAbstract = function(name) { var $x = ["NAbstract",26,name]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NExtends = function(fqName,params) { var $x = ["NExtends",27,fqName,params]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NImplements = function(fqName,params) { var $x = ["NImplements",28,fqName,params]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NWrapper = function(node) { var $x = ["NWrapper",29,node]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NProperty = function(a,b) { var $x = ["NProperty",30,a,b]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NVar = function(name,propertyInfo,type,value) { var $x = ["NVar",31,name,propertyInfo,type,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NFunctionArg = function(opt,id,type,value) { var $x = ["NFunctionArg",32,opt,id,type,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NFunction = function(name,args,ret,expr) { var $x = ["NFunction",33,name,args,ret,expr]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NContinue = ["NContinue",34];
haxe.languageservices.node.Node.NContinue.toString = $estr;
haxe.languageservices.node.Node.NContinue.__enum__ = haxe.languageservices.node.Node;
haxe.languageservices.node.Node.NBreak = ["NBreak",35];
haxe.languageservices.node.Node.NBreak.toString = $estr;
haxe.languageservices.node.Node.NBreak.__enum__ = haxe.languageservices.node.Node;
haxe.languageservices.node.Node.NReturn = function(expr) { var $x = ["NReturn",36,expr]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NAccessPath = function(node) { var $x = ["NAccessPath",37,node]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NCallPart = function(node) { var $x = ["NCallPart",38,node]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NBinOpPart = function(op,expr) { var $x = ["NBinOpPart",39,op,expr]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NCall = function(left,args) { var $x = ["NCall",40,left,args]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NBinOp = function(left,op,right) { var $x = ["NBinOp",41,left,op,right]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NAccessList = function(node,accessors) { var $x = ["NAccessList",42,node,accessors]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NMember = function(modifiers,decl) { var $x = ["NMember",43,modifiers,decl]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NNew = function(id,call) { var $x = ["NNew",44,id,call]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NUnary = function(op,value) { var $x = ["NUnary",45,op,value]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NIdWithType = function(id,type) { var $x = ["NIdWithType",46,id,type]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NTypeParams = function(items) { var $x = ["NTypeParams",47,items]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.NFile = function(decls) { var $x = ["NFile",48,decls]; $x.__enum__ = haxe.languageservices.node.Node; $x.toString = $estr; return $x; };
haxe.languageservices.node.Node.__empty_constructs__ = [haxe.languageservices.node.Node.NDefault,haxe.languageservices.node.Node.NContinue,haxe.languageservices.node.Node.NBreak];
haxe.languageservices.grammar.Term = $hxClasses["haxe.languageservices.grammar.Term"] = { __ename__ : ["haxe","languageservices","grammar","Term"], __constructs__ : ["TLit","TReg","TRef","TAny","TSure","TSeq","TOpt","TList"] };
haxe.languageservices.grammar.Term.TLit = function(lit,conv) { var $x = ["TLit",0,lit,conv]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.TReg = function(name,reg,conv) { var $x = ["TReg",1,name,reg,conv]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.TRef = function(ref) { var $x = ["TRef",2,ref]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.TAny = function(items,recover) { var $x = ["TAny",3,items,recover]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.TSure = ["TSure",4];
haxe.languageservices.grammar.Term.TSure.toString = $estr;
haxe.languageservices.grammar.Term.TSure.__enum__ = haxe.languageservices.grammar.Term;
haxe.languageservices.grammar.Term.TSeq = function(items,conv) { var $x = ["TSeq",5,items,conv]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.TOpt = function(term,errorMessage) { var $x = ["TOpt",6,term,errorMessage]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.TList = function(item,separator,minCount,allowExtraSeparator,conv) { var $x = ["TList",7,item,separator,minCount,allowExtraSeparator,conv]; $x.__enum__ = haxe.languageservices.grammar.Term; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Term.__empty_constructs__ = [haxe.languageservices.grammar.Term.TSure];
haxe.languageservices.node.Const = $hxClasses["haxe.languageservices.node.Const"] = { __ename__ : ["haxe","languageservices","node","Const"], __constructs__ : ["CBool","CInt","CFloat","CString"] };
haxe.languageservices.node.Const.CBool = function(value) { var $x = ["CBool",0,value]; $x.__enum__ = haxe.languageservices.node.Const; $x.toString = $estr; return $x; };
haxe.languageservices.node.Const.CInt = function(value) { var $x = ["CInt",1,value]; $x.__enum__ = haxe.languageservices.node.Const; $x.toString = $estr; return $x; };
haxe.languageservices.node.Const.CFloat = function(value) { var $x = ["CFloat",2,value]; $x.__enum__ = haxe.languageservices.node.Const; $x.toString = $estr; return $x; };
haxe.languageservices.node.Const.CString = function(value) { var $x = ["CString",3,value]; $x.__enum__ = haxe.languageservices.node.Const; $x.toString = $estr; return $x; };
haxe.languageservices.node.Const.__empty_constructs__ = [];
haxe.languageservices.CompFileContext = function(types) {
	this.builtTypes = [];
	this.errors = new haxe.languageservices.grammar.HaxeErrors();
	this.types = types;
};
$hxClasses["haxe.languageservices.CompFileContext"] = haxe.languageservices.CompFileContext;
haxe.languageservices.CompFileContext.__name__ = ["haxe","languageservices","CompFileContext"];
haxe.languageservices.CompFileContext.prototype = {
	reader: null
	,term: null
	,types: null
	,typeBuilder: null
	,typeChecker: null
	,completion: null
	,completionScope: null
	,grammarResult: null
	,rootNode: null
	,errors: null
	,builtTypes: null
	,removeOldTypes: function() {
		var _g = 0;
		var _g1 = this.builtTypes;
		while(_g < _g1.length) {
			var type = _g1[_g];
			++_g;
			type.remove();
		}
		this.builtTypes = [];
	}
	,setFile: function(str,file) {
		this.reader = new haxe.languageservices.node.Reader(str,file);
		this.term = haxe.languageservices.CompFileContext.grammar.program;
	}
	,update: function() {
		this.removeOldTypes();
		this.reader.reset();
		this.errors.reset();
		this.grammarResult = haxe.languageservices.CompFileContext.grammar.parse(this.term,this.reader,this.errors);
		this.typeBuilder = new haxe.languageservices.grammar.HaxeTypeBuilder(this.types,this.errors);
		this.typeChecker = new haxe.languageservices.grammar.HaxeTypeChecker(this.types,this.errors);
		this.completion = new haxe.languageservices.grammar.HaxeCompletion(this.types,this.errors);
		this.completionScope = null;
		{
			var _g = this.grammarResult;
			switch(_g[1]) {
			case 1:case 0:
				this.rootNode = null;
				break;
			case 2:
				var value = _g[2];
				this.rootNode = value;
				break;
			}
		}
		if(this.rootNode != null) {
			this.builtTypes = [];
			this.typeBuilder.process(this.rootNode,this.builtTypes);
			var _g1 = 0;
			var _g11 = this.builtTypes;
			while(_g1 < _g11.length) {
				var type = _g11[_g1];
				++_g1;
				this.typeChecker.checkType(type);
			}
			this.completionScope = this.completion.processCompletion(this.rootNode);
		}
	}
	,__class__: haxe.languageservices.CompFileContext
};
haxe.languageservices.CompReferenceType = $hxClasses["haxe.languageservices.CompReferenceType"] = { __ename__ : ["haxe","languageservices","CompReferenceType"], __constructs__ : ["Declaration","Update","Read"] };
haxe.languageservices.CompReferenceType.Declaration = ["Declaration",0];
haxe.languageservices.CompReferenceType.Declaration.toString = $estr;
haxe.languageservices.CompReferenceType.Declaration.__enum__ = haxe.languageservices.CompReferenceType;
haxe.languageservices.CompReferenceType.Update = ["Update",1];
haxe.languageservices.CompReferenceType.Update.toString = $estr;
haxe.languageservices.CompReferenceType.Update.__enum__ = haxe.languageservices.CompReferenceType;
haxe.languageservices.CompReferenceType.Read = ["Read",2];
haxe.languageservices.CompReferenceType.Read.toString = $estr;
haxe.languageservices.CompReferenceType.Read.__enum__ = haxe.languageservices.CompReferenceType;
haxe.languageservices.CompReferenceType.__empty_constructs__ = [haxe.languageservices.CompReferenceType.Declaration,haxe.languageservices.CompReferenceType.Update,haxe.languageservices.CompReferenceType.Read];
haxe.languageservices.CompPosition = function(min,max) {
	this.min = min;
	this.max = max;
};
$hxClasses["haxe.languageservices.CompPosition"] = haxe.languageservices.CompPosition;
haxe.languageservices.CompPosition.__name__ = ["haxe","languageservices","CompPosition"];
haxe.languageservices.CompPosition.prototype = {
	min: null
	,max: null
	,toString: function() {
		return "" + this.min + ":" + this.max;
	}
	,__class__: haxe.languageservices.CompPosition
};
haxe.languageservices.CompError = function(pos,text) {
	this.pos = pos;
	this.text = text;
};
$hxClasses["haxe.languageservices.CompError"] = haxe.languageservices.CompError;
haxe.languageservices.CompError.__name__ = ["haxe","languageservices","CompError"];
haxe.languageservices.CompError.prototype = {
	pos: null
	,text: null
	,toString: function() {
		return "" + Std.string(this.pos) + ":" + this.text;
	}
	,__class__: haxe.languageservices.CompError
};
haxe.languageservices.CompArgument = function(name,type,optional,doc) {
	this.name = name;
	this.type = type;
	this.optional = optional;
	this.doc = doc;
};
$hxClasses["haxe.languageservices.CompArgument"] = haxe.languageservices.CompArgument;
haxe.languageservices.CompArgument.__name__ = ["haxe","languageservices","CompArgument"];
haxe.languageservices.CompArgument.prototype = {
	name: null
	,type: null
	,optional: null
	,doc: null
	,__class__: haxe.languageservices.CompArgument
};
haxe.languageservices.CompReturn = function(type,doc) {
	this.type = type;
	this.doc = doc;
};
$hxClasses["haxe.languageservices.CompReturn"] = haxe.languageservices.CompReturn;
haxe.languageservices.CompReturn.__name__ = ["haxe","languageservices","CompReturn"];
haxe.languageservices.CompReturn.prototype = {
	type: null
	,doc: null
	,__class__: haxe.languageservices.CompReturn
};
haxe.languageservices.CompCall = function(baseType,name,args,ret,argIndex,doc) {
	this.baseType = baseType;
	this.name = name;
	this.args = args;
	this.ret = ret;
	this.argIndex = argIndex;
	this.doc = doc;
};
$hxClasses["haxe.languageservices.CompCall"] = haxe.languageservices.CompCall;
haxe.languageservices.CompCall.__name__ = ["haxe","languageservices","CompCall"];
haxe.languageservices.CompCall.prototype = {
	baseType: null
	,name: null
	,args: null
	,ret: null
	,argIndex: null
	,doc: null
	,__class__: haxe.languageservices.CompCall
};
haxe.languageservices.CompList = function(items) {
	this.items = items;
};
$hxClasses["haxe.languageservices.CompList"] = haxe.languageservices.CompList;
haxe.languageservices.CompList.__name__ = ["haxe","languageservices","CompList"];
haxe.languageservices.CompList.prototype = {
	items: null
	,toString: function() {
		return ((function($this) {
			var $r;
			var _g = [];
			{
				var _g1 = 0;
				var _g2 = $this.items;
				while(_g1 < _g2.length) {
					var completion = _g2[_g1];
					++_g1;
					_g.push("" + completion.name + ":" + Std.string(completion.type));
				}
			}
			$r = _g;
			return $r;
		}(this))).toString();
	}
	,__class__: haxe.languageservices.CompList
};
haxe.languageservices.CompEntry = function(name,type,hasValue,value) {
	this.name = name;
	this.type = type;
	this.hasValue = hasValue;
	this.value = value;
};
$hxClasses["haxe.languageservices.CompEntry"] = haxe.languageservices.CompEntry;
haxe.languageservices.CompEntry.__name__ = ["haxe","languageservices","CompEntry"];
haxe.languageservices.CompEntry.prototype = {
	name: null
	,type: null
	,hasValue: null
	,value: null
	,toString: function() {
		if(this.hasValue) return "" + this.name + ":" + Std.string(this.type) + " = " + Std.string(this.value);
		return "" + this.name + ":" + Std.string(this.type);
	}
	,__class__: haxe.languageservices.CompEntry
};
haxe.languageservices.CompType = function(str,types) {
	this.str = str;
	this.types = types;
};
$hxClasses["haxe.languageservices.CompType"] = haxe.languageservices.CompType;
haxe.languageservices.CompType.__name__ = ["haxe","languageservices","CompType"];
haxe.languageservices.CompType.prototype = {
	str: null
	,types: null
	,toString: function() {
		if(this.types != null && this.types.length > 0) return this.str + "<" + this.types.join(",") + ">";
		return this.str;
	}
	,__class__: haxe.languageservices.CompType
};
haxe.languageservices.grammar.TermRef = function() {
};
$hxClasses["haxe.languageservices.grammar.TermRef"] = haxe.languageservices.grammar.TermRef;
haxe.languageservices.grammar.TermRef.__name__ = ["haxe","languageservices","grammar","TermRef"];
haxe.languageservices.grammar.TermRef.prototype = {
	term: null
	,__class__: haxe.languageservices.grammar.TermRef
};
haxe.languageservices.grammar.NNode = function(pos,node) {
	this.pos = pos;
	this.node = node;
};
$hxClasses["haxe.languageservices.grammar.NNode"] = haxe.languageservices.grammar.NNode;
haxe.languageservices.grammar.NNode.__name__ = ["haxe","languageservices","grammar","NNode"];
haxe.languageservices.grammar.NNode.staticLocateIndex = function(item,index) {
	if(js.Boot.__instanceof(item,haxe.languageservices.grammar.NNode)) {
		var result = haxe.languageservices.grammar.NNode.staticLocateIndex(item.node,index);
		if(result != null) return result;
		return item;
	}
	if((item instanceof Array) && item.__enum__ == null) {
		var array = Std.instance(item,Array);
		var _g = 0;
		while(_g < array.length) {
			var item1 = array[_g];
			++_g;
			var result1 = haxe.languageservices.grammar.NNode.staticLocateIndex(item1,index);
			if(result1 != null && result1.pos.contains(index)) return result1;
		}
	}
	if(Type.getEnum(item) != null) {
		var params = Type.enumParameters(item);
		var _g1 = 0;
		while(_g1 < params.length) {
			var param = params[_g1];
			++_g1;
			var result2 = haxe.languageservices.grammar.NNode.staticLocateIndex(param,index);
			if(result2 != null && result2.pos.contains(index)) return result2;
		}
	}
	return null;
};
haxe.languageservices.grammar.NNode.isValid = function(node) {
	return node != null && node.node != null;
};
haxe.languageservices.grammar.NNode.prototype = {
	pos: null
	,node: null
	,locateIndex: function(index) {
		return haxe.languageservices.grammar.NNode.staticLocateIndex(this,index);
	}
	,toString: function() {
		return "" + Std.string(this.node) + "@" + Std.string(this.pos);
	}
	,__class__: haxe.languageservices.grammar.NNode
};
haxe.languageservices.grammar.Result = $hxClasses["haxe.languageservices.grammar.Result"] = { __ename__ : ["haxe","languageservices","grammar","Result"], __constructs__ : ["RMatched","RUnmatched","RMatchedValue"] };
haxe.languageservices.grammar.Result.RMatched = ["RMatched",0];
haxe.languageservices.grammar.Result.RMatched.toString = $estr;
haxe.languageservices.grammar.Result.RMatched.__enum__ = haxe.languageservices.grammar.Result;
haxe.languageservices.grammar.Result.RUnmatched = function(validCount,lastPos) { var $x = ["RUnmatched",1,validCount,lastPos]; $x.__enum__ = haxe.languageservices.grammar.Result; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Result.RMatchedValue = function(value) { var $x = ["RMatchedValue",2,value]; $x.__enum__ = haxe.languageservices.grammar.Result; $x.toString = $estr; return $x; };
haxe.languageservices.grammar.Result.__empty_constructs__ = [haxe.languageservices.grammar.Result.RMatched];
haxe.languageservices.grammar.HaxeCompletion = function(types,errors) {
	this.types = types;
	if(errors != null) this.errors = errors; else this.errors = new haxe.languageservices.grammar.HaxeErrors();
};
$hxClasses["haxe.languageservices.grammar.HaxeCompletion"] = haxe.languageservices.grammar.HaxeCompletion;
haxe.languageservices.grammar.HaxeCompletion.__name__ = ["haxe","languageservices","grammar","HaxeCompletion"];
haxe.languageservices.grammar.HaxeCompletion.prototype = {
	errors: null
	,types: null
	,processCompletion: function(znode) {
		return this.process(znode,new haxe.languageservices.grammar.CompletionScope(this,znode));
	}
	,process: function(znode,scope) {
		if(znode == null || znode.node == null) return scope;
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 48:
				var items = _g[2];
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					this.process(item,scope.createChild(item));
				}
				break;
			case 12:
				var items = _g[2];
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					this.process(item,scope.createChild(item));
				}
				break;
			case 4:
				var items1 = _g[2];
				var _g11 = 0;
				while(_g11 < items1.length) {
					var item1 = items1[_g11];
					++_g11;
					this.process(item1,scope);
				}
				break;
			case 9:
				var items1 = _g[2];
				var _g11 = 0;
				while(_g11 < items1.length) {
					var item1 = items1[_g11];
					++_g11;
					this.process(item1,scope);
				}
				break;
			case 31:
				var value = _g[5];
				var type = _g[4];
				var propertyInfo = _g[3];
				var name = _g[2];
				var local = new haxe.languageservices.grammar.CompletionEntry(scope,name.pos,type,value,haxe.languageservices.node.NodeTools.getId(name));
				scope.addLocal(local);
				local.usages.push(new haxe.languageservices.grammar.CompletionUsage(name,haxe.languageservices.grammar.CompletionUsageType.Declaration));
				this.process(value,scope);
				break;
			case 0:
				var value1 = _g[2];
				switch(value1) {
				case "true":case "false":case "null":
					break;
				default:
					var local1 = scope.getLocal(value1);
					if(local1 == null) this.errors.add(new haxe.languageservices.grammar.ParserError(znode.pos,"Can't find local \"" + value1 + "\"")); else local1.usages.push(new haxe.languageservices.grammar.CompletionUsage(znode,haxe.languageservices.grammar.CompletionUsageType.Read));
				}
				break;
			case 45:
				var value2 = _g[3];
				var op = _g[2];
				this.process(value2,scope);
				break;
			case 8:
				var falseExpr = _g[4];
				var trueExpr = _g[3];
				var condExpr = _g[2];
				var condType = scope.getNodeType(condExpr,new haxe.languageservices.node.ProcessNodeContext());
				if(condType.type.fqName != "Bool") this.errors.add(new haxe.languageservices.grammar.ParserError(condExpr.pos,"If condition must be Bool but was " + Std.string(condType)));
				this.process(condExpr,scope);
				this.process(trueExpr,scope);
				this.process(falseExpr,scope);
				break;
			case 13:
				var body = _g[4];
				var iteratorExpr = _g[3];
				var iteratorName = _g[2];
				var fullForScope = scope.createChild(znode);
				var forScope = fullForScope.createChild(body);
				this.process(iteratorExpr,fullForScope);
				var local2 = new haxe.languageservices.grammar.CompletionEntryArrayElement(fullForScope,iteratorName.pos,null,iteratorExpr,haxe.languageservices.node.NodeTools.getId(iteratorName));
				local2.usages.push(new haxe.languageservices.grammar.CompletionUsage(iteratorName,haxe.languageservices.grammar.CompletionUsageType.Declaration));
				fullForScope.addLocal(local2);
				this.process(body,fullForScope);
				break;
			case 14:
				var body1 = _g[3];
				var cond = _g[2];
				this.process(cond,scope);
				this.process(body1,scope);
				break;
			case 15:
				var cond = _g[3];
				var body1 = _g[2];
				this.process(cond,scope);
				this.process(body1,scope);
				break;
			case 3:
				break;
			case 40:
				break;
			case 41:
				var right = _g[4];
				var op1 = _g[3];
				var left = _g[2];
				this.process(left,scope);
				this.process(right,scope);
				var ltype = scope.getNodeType(left);
				var rtype = scope.getNodeType(right);
				break;
			case 19:
				var fqName = _g[2];
				break;
			case 20:
				var fqName1 = _g[2];
				break;
			case 21:
				var fqName2 = _g[2];
				break;
			case 22:
				var decls = _g[5];
				var extendsImplementsList = _g[4];
				var typeParams = _g[3];
				var name1 = _g[2];
				this.process(decls,scope.createChild(decls));
				break;
			case 23:
				var decls1 = _g[5];
				var extendsImplementsList1 = _g[4];
				var typeParams1 = _g[3];
				var name2 = _g[2];
				this.process(decls1,scope.createChild(decls1));
				break;
			case 16:
				var cases = _g[3];
				var subject = _g[2];
				this.process(subject,scope);
				this.process(cases,scope);
				break;
			case 25:
				var name3 = _g[2];
				break;
			case 26:
				var name4 = _g[2];
				break;
			case 43:
				var decl = _g[3];
				var modifiers = _g[2];
				this.process(decl,scope);
				break;
			case 33:
				var expr = _g[5];
				var ret = _g[4];
				var args = _g[3];
				var name5 = _g[2];
				var funcScope = scope.createChild(expr);
				var local3 = new haxe.languageservices.grammar.CompletionEntryFunctionElement(scope,name5.pos,ret,expr,haxe.languageservices.node.NodeTools.getId(name5));
				scope.addLocal(local3);
				local3.usages.push(new haxe.languageservices.grammar.CompletionUsage(name5,haxe.languageservices.grammar.CompletionUsageType.Declaration));
				var bodyScope = funcScope.createChild(expr);
				bodyScope.addLocal(new haxe.languageservices.grammar.CompletionEntryThis(scope,new haxe.languageservices.node.Position(0,0,new haxe.languageservices.node.Reader("")),null,null,"this"));
				this.processFunctionArgs(args,funcScope,funcScope);
				this.process(expr,bodyScope);
				break;
			case 36:
				var expr1 = _g[2];
				this.process(expr1,scope);
				break;
			default:
				this.errors.add(new haxe.languageservices.grammar.ParserError(znode.pos,"Unhandled completion (II) " + Std.string(znode)));
			}
		}
		return scope;
	}
	,processFunctionArgs: function(znode,scope,scope2) {
		if(znode == null || znode.node == null) return;
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 4:
				var items = _g[2];
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					this.processFunctionArgs(item,scope,scope2);
				}
				break;
			case 32:
				var value = _g[5];
				var type = _g[4];
				var id = _g[3];
				var opt = _g[2];
				var e = new haxe.languageservices.grammar.CompletionEntry(scope2,id.pos,type,value,haxe.languageservices.node.NodeTools.getId(id));
				scope.addLocal(e);
				e.usages.push(new haxe.languageservices.grammar.CompletionUsage(id,haxe.languageservices.grammar.CompletionUsageType.Declaration));
				break;
			default:
				throw "Unhandled completion (I) " + Std.string(znode);
				this.errors.add(new haxe.languageservices.grammar.ParserError(znode.pos,"Unhandled completion (I) " + Std.string(znode)));
			}
		}
	}
	,__class__: haxe.languageservices.grammar.HaxeCompletion
};
haxe.languageservices.grammar.CompletionUsageType = $hxClasses["haxe.languageservices.grammar.CompletionUsageType"] = { __ename__ : ["haxe","languageservices","grammar","CompletionUsageType"], __constructs__ : ["Declaration","Write","Read"] };
haxe.languageservices.grammar.CompletionUsageType.Declaration = ["Declaration",0];
haxe.languageservices.grammar.CompletionUsageType.Declaration.toString = $estr;
haxe.languageservices.grammar.CompletionUsageType.Declaration.__enum__ = haxe.languageservices.grammar.CompletionUsageType;
haxe.languageservices.grammar.CompletionUsageType.Write = ["Write",1];
haxe.languageservices.grammar.CompletionUsageType.Write.toString = $estr;
haxe.languageservices.grammar.CompletionUsageType.Write.__enum__ = haxe.languageservices.grammar.CompletionUsageType;
haxe.languageservices.grammar.CompletionUsageType.Read = ["Read",2];
haxe.languageservices.grammar.CompletionUsageType.Read.toString = $estr;
haxe.languageservices.grammar.CompletionUsageType.Read.__enum__ = haxe.languageservices.grammar.CompletionUsageType;
haxe.languageservices.grammar.CompletionUsageType.__empty_constructs__ = [haxe.languageservices.grammar.CompletionUsageType.Declaration,haxe.languageservices.grammar.CompletionUsageType.Write,haxe.languageservices.grammar.CompletionUsageType.Read];
haxe.languageservices.grammar.CompletionUsage = function(node,type) {
	this.node = node;
	this.type = type;
};
$hxClasses["haxe.languageservices.grammar.CompletionUsage"] = haxe.languageservices.grammar.CompletionUsage;
haxe.languageservices.grammar.CompletionUsage.__name__ = ["haxe","languageservices","grammar","CompletionUsage"];
haxe.languageservices.grammar.CompletionUsage.prototype = {
	node: null
	,type: null
	,toString: function() {
		return "" + Std.string(this.node) + ":" + Std.string(this.type);
	}
	,__class__: haxe.languageservices.grammar.CompletionUsage
};
haxe.languageservices.grammar.CompletionEntry = function(scope,pos,type,expr,name) {
	this.usages = new Array();
	this.scope = scope;
	this.pos = pos;
	this.type = type;
	this.expr = expr;
	this.name = name;
};
$hxClasses["haxe.languageservices.grammar.CompletionEntry"] = haxe.languageservices.grammar.CompletionEntry;
haxe.languageservices.grammar.CompletionEntry.__name__ = ["haxe","languageservices","grammar","CompletionEntry"];
haxe.languageservices.grammar.CompletionEntry.prototype = {
	scope: null
	,pos: null
	,name: null
	,type: null
	,expr: null
	,usages: null
	,getResult: function(context) {
		var ctype = null;
		if(this.type != null) ctype = haxe.languageservices.grammar.ExpressionResult.withoutValue(new haxe.languageservices.type.SpecificHaxeType(this.scope.types,this.scope.types.getType(this.type.pos.get_text())));
		if(this.expr != null) ctype = this.scope.getNodeResult(this.expr,context);
		if(ctype == null) ctype = haxe.languageservices.grammar.ExpressionResult.withoutValue(this.scope.types.specTypeDynamic);
		return ctype;
	}
	,toString: function() {
		return "" + this.name + "@" + Std.string(this.pos);
	}
	,__class__: haxe.languageservices.grammar.CompletionEntry
};
haxe.languageservices.grammar.CompletionEntryArrayElement = function(scope,pos,type,expr,name) {
	haxe.languageservices.grammar.CompletionEntry.call(this,scope,pos,type,expr,name);
};
$hxClasses["haxe.languageservices.grammar.CompletionEntryArrayElement"] = haxe.languageservices.grammar.CompletionEntryArrayElement;
haxe.languageservices.grammar.CompletionEntryArrayElement.__name__ = ["haxe","languageservices","grammar","CompletionEntryArrayElement"];
haxe.languageservices.grammar.CompletionEntryArrayElement.__super__ = haxe.languageservices.grammar.CompletionEntry;
haxe.languageservices.grammar.CompletionEntryArrayElement.prototype = $extend(haxe.languageservices.grammar.CompletionEntry.prototype,{
	getResult: function(context) {
		return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.scope.types.getArrayElement(haxe.languageservices.grammar.CompletionEntry.prototype.getResult.call(this).type));
	}
	,__class__: haxe.languageservices.grammar.CompletionEntryArrayElement
});
haxe.languageservices.grammar.CompletionEntryFunctionElement = function(scope,pos,type,expr,name) {
	haxe.languageservices.grammar.CompletionEntry.call(this,scope,pos,type,expr,name);
};
$hxClasses["haxe.languageservices.grammar.CompletionEntryFunctionElement"] = haxe.languageservices.grammar.CompletionEntryFunctionElement;
haxe.languageservices.grammar.CompletionEntryFunctionElement.__name__ = ["haxe","languageservices","grammar","CompletionEntryFunctionElement"];
haxe.languageservices.grammar.CompletionEntryFunctionElement.__super__ = haxe.languageservices.grammar.CompletionEntry;
haxe.languageservices.grammar.CompletionEntryFunctionElement.prototype = $extend(haxe.languageservices.grammar.CompletionEntry.prototype,{
	getResult: function(context) {
		return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.scope.types.specTypeDynamic);
	}
	,__class__: haxe.languageservices.grammar.CompletionEntryFunctionElement
});
haxe.languageservices.grammar.CompletionEntryThis = function(scope,pos,type,expr,name) {
	haxe.languageservices.grammar.CompletionEntry.call(this,scope,pos,type,expr,name);
};
$hxClasses["haxe.languageservices.grammar.CompletionEntryThis"] = haxe.languageservices.grammar.CompletionEntryThis;
haxe.languageservices.grammar.CompletionEntryThis.__name__ = ["haxe","languageservices","grammar","CompletionEntryThis"];
haxe.languageservices.grammar.CompletionEntryThis.__super__ = haxe.languageservices.grammar.CompletionEntry;
haxe.languageservices.grammar.CompletionEntryThis.prototype = $extend(haxe.languageservices.grammar.CompletionEntry.prototype,{
	getResult: function(context) {
		return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.scope.types.specTypeDynamic);
	}
	,__class__: haxe.languageservices.grammar.CompletionEntryThis
});
haxe.languageservices.grammar.ExpressionResult = function(type,hasValue,value) {
	this.type = type;
	this.hasValue = hasValue;
	this.value = value;
};
$hxClasses["haxe.languageservices.grammar.ExpressionResult"] = haxe.languageservices.grammar.ExpressionResult;
haxe.languageservices.grammar.ExpressionResult.__name__ = ["haxe","languageservices","grammar","ExpressionResult"];
haxe.languageservices.grammar.ExpressionResult.withoutValue = function(type) {
	return new haxe.languageservices.grammar.ExpressionResult(type,false,null);
};
haxe.languageservices.grammar.ExpressionResult.withValue = function(type,value) {
	return new haxe.languageservices.grammar.ExpressionResult(type,true,value);
};
haxe.languageservices.grammar.ExpressionResult.prototype = {
	type: null
	,hasValue: null
	,value: null
	,toString: function() {
		if(this.hasValue) return "" + Std.string(this.type) + " = " + Std.string(this.value);
		return "" + Std.string(this.type);
	}
	,__class__: haxe.languageservices.grammar.ExpressionResult
};
haxe.languageservices.grammar.CompletionScope = function(completion,node,parent) {
	this.children = new Array();
	this.uid = haxe.languageservices.grammar.CompletionScope.lastUid++;
	this.node = node;
	this.completion = completion;
	this.types = completion.types;
	if(parent != null) {
		this.parent = parent;
		this.parent.children.push(this);
		this.locals = parent.locals.createChild();
	} else {
		this.parent = null;
		this.locals = new haxe.languageservices.util.Scope();
	}
};
$hxClasses["haxe.languageservices.grammar.CompletionScope"] = haxe.languageservices.grammar.CompletionScope;
haxe.languageservices.grammar.CompletionScope.__name__ = ["haxe","languageservices","grammar","CompletionScope"];
haxe.languageservices.grammar.CompletionScope.prototype = {
	uid: null
	,node: null
	,completion: null
	,types: null
	,parent: null
	,children: null
	,locals: null
	,getIdentifierAt: function(index) {
		var znode = this.node.locateIndex(index);
		if(znode != null) {
			var _g = znode.node;
			switch(_g[1]) {
			case 0:
				var v = _g[2];
				return { pos : znode.pos, name : v};
			default:
			}
		}
		return null;
	}
	,getNodeAt: function(index) {
		return this.locateIndex(index).node.locateIndex(index);
	}
	,locateIndex: function(index) {
		var _g = 0;
		var _g1 = this.children;
		while(_g < _g1.length) {
			var child = _g1[_g];
			++_g;
			if(child.node.pos.contains(index)) return child.locateIndex(index);
		}
		return this;
	}
	,getNodeType: function(znode,context) {
		return this.getNodeResult(znode,context).type;
	}
	,getNodeResult: function(znode,context) {
		if(context == null) context = new haxe.languageservices.node.ProcessNodeContext();
		return this._getNodeResult(znode,context);
	}
	,_getNodeResult: function(znode,context) {
		var _g1 = this;
		if(context.isExplored(znode)) {
			context.recursionDetected();
			return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.specTypeDynamic);
		}
		context.markExplored(znode);
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 12:
				var values = _g[2];
				return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.specTypeDynamic);
			case 41:
				var right = _g[4];
				var op = _g[3];
				var left = _g[2];
				var lv = this._getNodeResult(left,context);
				var rv = this._getNodeResult(right,context);
				var operator = function(doOp) {
					if(lv.hasValue && rv.hasValue) return haxe.languageservices.grammar.ExpressionResult.withValue(lv.type,doOp(lv.value,rv.value));
					return haxe.languageservices.grammar.ExpressionResult.withoutValue(_g1.types.specTypeInt);
				};
				switch(op) {
				case "==":case "!=":
					return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.specTypeBool);
				case "+":
					return operator(function(a,b) {
						return a + b;
					});
				case "-":
					return operator(function(a1,b1) {
						return a1 - b1;
					});
				case "%":
					return operator(function(a2,b2) {
						return a2 % b2;
					});
				case "/":
					return operator(function(a3,b3) {
						return a3 / b3;
					});
				case "*":
					return operator(function(a4,b4) {
						return a4 * b4;
					});
				default:
					throw "Unknown operator " + op;
				}
				return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.specTypeDynamic);
			case 4:
				var values1 = _g[2];
				return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.unify((function($this) {
					var $r;
					var _g11 = [];
					{
						var _g2 = 0;
						while(_g2 < values1.length) {
							var value = values1[_g2];
							++_g2;
							_g11.push($this._getNodeResult(value,context).type);
						}
					}
					$r = _g11;
					return $r;
				}(this))));
			case 9:
				var values2 = _g[2];
				var elementType = this.types.unify((function($this) {
					var $r;
					var _g12 = [];
					{
						var _g21 = 0;
						while(_g21 < values2.length) {
							var value1 = values2[_g21];
							++_g21;
							_g12.push($this._getNodeResult(value1,context).type);
						}
					}
					$r = _g12;
					return $r;
				}(this)));
				return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.createArray(elementType));
			case 3:
				switch(Type.enumIndex(_g[2])) {
				case 1:
					var value2 = _g[2][2];
					return haxe.languageservices.grammar.ExpressionResult.withValue(this.types.specTypeInt,value2);
				case 2:
					var value3 = _g[2][2];
					return haxe.languageservices.grammar.ExpressionResult.withValue(this.types.specTypeFloat,value3);
				default:
					throw new Error("Not implemented getNodeResult() " + Std.string(znode));
				}
				break;
			case 8:
				var falseExpr = _g[4];
				var trueExpr = _g[3];
				var code = _g[2];
				return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.unify([this._getNodeResult(trueExpr,context).type,this._getNodeResult(falseExpr,context).type]));
			case 0:
				var str = _g[2];
				switch(str) {
				case "true":
					return haxe.languageservices.grammar.ExpressionResult.withValue(this.types.specTypeBool,true);
				case "false":
					return haxe.languageservices.grammar.ExpressionResult.withValue(this.types.specTypeBool,false);
				case "null":
					return haxe.languageservices.grammar.ExpressionResult.withValue(this.types.specTypeDynamic,null);
				default:
					var local = this.getLocal(str);
					if(local != null) return local.getResult(context);
					return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.specTypeDynamic);
				}
				break;
			default:
				throw new Error("Not implemented getNodeResult() " + Std.string(znode));
			}
		}
		return haxe.languageservices.grammar.ExpressionResult.withoutValue(this.types.specTypeDynamic);
	}
	,getLocals: function() {
		return this.locals.values();
	}
	,getLocalAt: function(index) {
		var id = this.getIdentifierAt(index);
		if(id == null) return null;
		return this.locals.get(id.name);
	}
	,getLocal: function(name) {
		return this.locals.get(name);
	}
	,addLocal: function(entry) {
		this.locals.set(entry.name,entry);
	}
	,createChild: function(node) {
		return new haxe.languageservices.grammar.CompletionScope(this.completion,node,this);
	}
	,__class__: haxe.languageservices.grammar.CompletionScope
};
haxe.languageservices.grammar.HaxeErrors = function() {
	this.errors = new Array();
};
$hxClasses["haxe.languageservices.grammar.HaxeErrors"] = haxe.languageservices.grammar.HaxeErrors;
haxe.languageservices.grammar.HaxeErrors.__name__ = ["haxe","languageservices","grammar","HaxeErrors"];
haxe.languageservices.grammar.HaxeErrors.prototype = {
	errors: null
	,reset: function() {
		this.errors.splice(0,this.errors.length);
	}
	,add: function(error) {
		this.errors.push(error);
	}
	,__class__: haxe.languageservices.grammar.HaxeErrors
};
haxe.languageservices.grammar.HaxeTypeBuilder = function(types,errors) {
	this.types = types;
	this.errors = errors;
};
$hxClasses["haxe.languageservices.grammar.HaxeTypeBuilder"] = haxe.languageservices.grammar.HaxeTypeBuilder;
haxe.languageservices.grammar.HaxeTypeBuilder.__name__ = ["haxe","languageservices","grammar","HaxeTypeBuilder"];
haxe.languageservices.grammar.HaxeTypeBuilder.prototype = {
	errors: null
	,types: null
	,processResult: function(result) {
		switch(result[1]) {
		case 2:
			var v = result[2];
			return this.process(v);
		default:
			throw "Can't process";
		}
		return null;
	}
	,error: function(pos,text) {
		this.errors.add(new haxe.languageservices.grammar.ParserError(pos,text));
	}
	,checkPackage: function(nidList2) {
		var parts = [];
		{
			var _g = nidList2.node;
			switch(_g[1]) {
			case 6:
				var nidList = _g[2];
				var _g1 = 0;
				while(_g1 < nidList.length) {
					var nid = nidList[_g1];
					++_g1;
					{
						var _g2 = nid.node;
						switch(_g2[1]) {
						case 0:
							var c = _g2[2];
							if(!haxe.languageservices.util.StringUtils.isLowerCase(c)) this.error(nidList2.pos,"package should be lowercase");
							parts.push(c);
							break;
						default:
							throw "Invalid";
						}
					}
				}
				break;
			default:
				throw "Invalid";
			}
		}
		return parts;
	}
	,getId: function(znode) {
		return haxe.languageservices.node.NodeTools.getId(znode);
	}
	,process: function(znode,builtTypes) {
		if(builtTypes == null) builtTypes = [];
		if(!haxe.languageservices.grammar.NNode.isValid(znode)) return builtTypes;
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 48:
				var items = _g[2];
				var index = 0;
				var packag = this.types.rootPackage;
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					{
						var _g2 = item.node;
						switch(_g2[1]) {
						case 19:
							var name = _g2[2];
							if(index != 0) this.error(item.pos,"Package should be first element in the file"); else {
								var pathParts = this.checkPackage(name);
								packag = this.types.rootPackage.access(pathParts.join("."),true);
							}
							break;
						case 20:
							var name1 = _g2[2];
							if(builtTypes.length > 0) this.error(item.pos,"Import should appear before any type decl");
							break;
						case 21:
							var name1 = _g2[2];
							if(builtTypes.length > 0) this.error(item.pos,"Import should appear before any type decl");
							break;
						case 22:
							var decls = _g2[5];
							var extendsImplementsList = _g2[4];
							var typeParams = _g2[3];
							var name2 = _g2[2];
							var typeName = this.getId(name2);
							this.checkClassName(name2.pos,typeName);
							if(packag.accessType(typeName) != null) this.error(item.pos,"Type name " + typeName + " is already defined in this module");
							var type = packag.accessTypeCreate(typeName,item.pos,haxe.languageservices.type.ClassHaxeType);
							builtTypes.push(type);
							if(haxe.languageservices.grammar.NNode.isValid(extendsImplementsList)) {
								var _g3 = extendsImplementsList.node;
								switch(_g3[1]) {
								case 4:
									var items1 = _g3[2];
									var _g4 = 0;
									while(_g4 < items1.length) {
										var item1 = items1[_g4];
										++_g4;
										{
											var _g5 = item1.node;
											switch(_g5[1]) {
											case 27:
												var params2 = _g5[3];
												var type2 = _g5[2];
												if(type.extending != null) this.error(item1.pos,"multiple inheritance not supported in haxe");
												var className2 = StringTools.trim(type2.pos.get_text());
												type.extending = new haxe.languageservices.type.TypeReference(this.types,className2,item1);
												break;
											case 28:
												var params21 = _g5[3];
												var type21 = _g5[2];
												var className21 = StringTools.trim(type21.pos.get_text());
												type.implementing.push(new haxe.languageservices.type.TypeReference(this.types,className21,item1));
												break;
											default:
												throw "Invalid";
											}
										}
									}
									break;
								default:
									throw "Invalid";
								}
							}
							type.node = item;
							this.processClass(type,decls);
							break;
						case 23:
							var decls1 = _g2[5];
							var extendsImplementsList1 = _g2[4];
							var typeParams1 = _g2[3];
							var name3 = _g2[2];
							var typeName1 = this.getId(name3);
							if(packag.accessType(typeName1) != null) this.error(item.pos,"Type name " + typeName1 + " is already defined in this module");
							var type1 = packag.accessTypeCreate(typeName1,item.pos,haxe.languageservices.type.InterfaceHaxeType);
							builtTypes.push(type1);
							this.processClass(type1,decls1);
							break;
						case 24:
							var name4 = _g2[2];
							var typeName2 = this.getId(name4);
							if(packag.accessType(typeName2) != null) this.error(item.pos,"Type name " + typeName2 + " is already defined in this module");
							var type3 = packag.accessTypeCreate(typeName2,item.pos,haxe.languageservices.type.TypedefHaxeType);
							builtTypes.push(type3);
							break;
						case 26:
							var name5 = _g2[2];
							var typeName3 = this.getId(name5);
							if(packag.accessType(typeName3) != null) this.error(item.pos,"Type name " + typeName3 + " is already defined in this module");
							var type4 = packag.accessTypeCreate(typeName3,item.pos,haxe.languageservices.type.AbstractHaxeType);
							builtTypes.push(type4);
							break;
						case 25:
							var name6 = _g2[2];
							var typeName4 = this.getId(name6);
							if(packag.accessType(typeName4) != null) this.error(item.pos,"Type name " + typeName4 + " is already defined in this module");
							var type5 = packag.accessTypeCreate(typeName4,item.pos,haxe.languageservices.type.EnumHaxeType);
							builtTypes.push(type5);
							break;
						default:
							this.error(item.pos,"invalid node");
						}
					}
					index++;
				}
				break;
			default:
				throw "Expected haxe file";
			}
		}
		return builtTypes;
	}
	,processClass: function(type,decls) {
		{
			var _g = decls.node;
			switch(_g[1]) {
			case 4:
				var members = _g[2];
				var _g1 = 0;
				while(_g1 < members.length) {
					var member = members[_g1];
					++_g1;
					{
						var _g2 = member.node;
						switch(_g2[1]) {
						case 43:
							var decl = _g2[3];
							var modifiers = _g2[2];
							var mods = new haxe.languageservices.type.HaxeModifiers();
							if(haxe.languageservices.grammar.NNode.isValid(modifiers)) {
								var _g3 = modifiers.node;
								switch(_g3[1]) {
								case 4:
									var parts = _g3[2];
									var _g4 = 0;
									while(_g4 < parts.length) {
										var part = parts[_g4];
										++_g4;
										if(haxe.languageservices.grammar.NNode.isValid(part)) {
											var _g5 = part.node;
											switch(_g5[1]) {
											case 1:
												var z = _g5[2];
												mods.add(z);
												break;
											default:
												throw "Invalid (I) " + Std.string(part);
											}
										}
									}
									break;
								default:
									throw "Invalid (II) " + Std.string(modifiers);
								}
							}
							if(haxe.languageservices.grammar.NNode.isValid(decl)) {
								var _g31 = decl.node;
								switch(_g31[1]) {
								case 31:
									var vvalue = _g31[5];
									var vtype = _g31[4];
									var propInfo = _g31[3];
									var vname = _g31[2];
									this.checkType(vtype);
									var field = new haxe.languageservices.type.FieldHaxeMember(member.pos,this.getId(vname));
									field.modifiers = mods;
									if(type.existsMember(field.name)) this.error(vname.pos,"redefined member " + field.name);
									type.addMember(field);
									break;
								case 33:
									var vexpr = _g31[5];
									var vret = _g31[4];
									var vargs = _g31[3];
									var vname1 = _g31[2];
									this.checkFunctionDeclArgs(vargs);
									this.checkType(vret);
									var method = new haxe.languageservices.type.MethodHaxeMember(member.pos,this.getId(vname1));
									method.modifiers = mods;
									if(type.existsMember(method.name)) this.error(vname1.pos,"redefined member " + method.name);
									type.addMember(method);
									this.processMethodBody(type,method,vexpr);
									break;
								default:
									throw "Invalid (III) " + Std.string(decl);
								}
							}
							break;
						default:
							throw "Invalid (IV) " + Std.string(member);
						}
					}
				}
				break;
			default:
				throw "Invalid (V) " + Std.string(decls);
			}
		}
	}
	,checkFunctionDeclArgs: function(znode) {
		if(!haxe.languageservices.grammar.NNode.isValid(znode)) return;
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 4:
				var items = _g[2];
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					this.checkFunctionDeclArgs(item);
				}
				break;
			case 32:
				var value = _g[5];
				var type = _g[4];
				var id = _g[3];
				var opt = _g[2];
				this.checkType(type);
				break;
			default:
				throw "Invalid (VI) " + Std.string(znode);
			}
		}
	}
	,checkType: function(znode) {
		if(!haxe.languageservices.grammar.NNode.isValid(znode)) return;
		{
			var _g = znode.node;
			switch(_g[1]) {
			case 0:
				var name = _g[2];
				this.checkClassName(znode.pos,name);
				break;
			case 29:
				var item = _g[2];
				this.checkType(item);
				break;
			case 47:
				var items = _g[2];
				break;
			case 4:
				var items1 = _g[2];
				var _g1 = 0;
				while(_g1 < items1.length) {
					var item1 = items1[_g1];
					++_g1;
					this.checkType(item1);
				}
				break;
			default:
				throw "Invalid (VII) " + Std.string(znode);
			}
		}
	}
	,checkClassName: function(pos,typeName) {
		if(!haxe.languageservices.util.StringUtils.isFirstUpper(typeName)) this.error(pos,"Type name should start with an uppercase letter");
	}
	,processMethodBody: function(type,method,expr) {
		if(!haxe.languageservices.grammar.NNode.isValid(expr)) return;
		{
			var _g = expr.node;
			switch(_g[1]) {
			case 12:
				var items = _g[2];
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					this.processMethodBody(type,method,item);
				}
				break;
			case 4:
				var items = _g[2];
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					this.processMethodBody(type,method,item);
				}
				break;
			case 31:
				var vvalue = _g[5];
				var vtype = _g[4];
				var propertyInfo = _g[3];
				var vname = _g[2];
				this.checkType(vtype);
				this.processMethodBody(type,method,vvalue);
				break;
			default:
			}
		}
	}
	,__class__: haxe.languageservices.grammar.HaxeTypeBuilder
};
haxe.languageservices.grammar.HaxeTypeChecker = function(types,errors) {
	this.types = types;
	this.errors = errors;
};
$hxClasses["haxe.languageservices.grammar.HaxeTypeChecker"] = haxe.languageservices.grammar.HaxeTypeChecker;
haxe.languageservices.grammar.HaxeTypeChecker.__name__ = ["haxe","languageservices","grammar","HaxeTypeChecker"];
haxe.languageservices.grammar.HaxeTypeChecker.prototype = {
	errors: null
	,types: null
	,checkType: function(type) {
		if(js.Boot.__instanceof(type,haxe.languageservices.type.ClassHaxeType)) this.checkClass(js.Boot.__cast(type , haxe.languageservices.type.ClassHaxeType));
	}
	,checkClass: function(type) {
		var expectedImplementingMembers = type.getAllExpectedImplementingMembers();
		var allMembers = type.getThisAndAncestorMembers();
		var ancestorMembers = type.getAncestorMembers();
		var thisMembers = type.getThisMembers();
		if(type.extending != null) {
			var t2 = type.extending.getType();
			var t2p = type.extending.expr.pos;
			if(t2 == null) this.errors.add(new haxe.languageservices.grammar.ParserError(t2p,"type " + type.extending.fqName + " not defined")); else if(!js.Boot.__instanceof(t2,haxe.languageservices.type.ClassHaxeType)) this.errors.add(new haxe.languageservices.grammar.ParserError(t2p,"type " + type.extending.fqName + " is not a class")); else {
			}
		}
		var _g = 0;
		var _g1 = type.implementing;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			var t21 = i.getType();
			var t2p1 = i.expr.pos;
			if(t21 == null) this.errors.add(new haxe.languageservices.grammar.ParserError(t2p1,"type " + i.fqName + " not defined")); else if(!js.Boot.__instanceof(t21,haxe.languageservices.type.InterfaceHaxeType)) this.errors.add(new haxe.languageservices.grammar.ParserError(t2p1,"type " + i.fqName + " is not an interface")); else {
			}
		}
		var _g2 = 0;
		while(_g2 < expectedImplementingMembers.length) {
			var mem = expectedImplementingMembers[_g2];
			++_g2;
			if(!allMembers.exists(mem.name)) this.errors.add(new haxe.languageservices.grammar.ParserError(type.pos,"member " + mem.name + " not implemented"));
		}
		var $it0 = thisMembers.iterator();
		while( $it0.hasNext() ) {
			var _mem = $it0.next();
			var mem1 = _mem;
			if(ancestorMembers.exists(mem1.name)) {
				var ancestorMem = ancestorMembers.get(mem1.name);
				if(!mem1.modifiers.isOverride) this.errors.add(new haxe.languageservices.grammar.ParserError(mem1.pos,"member " + mem1.name + " must override"));
				if(ancestorMem.modifiers.isStatic) this.errors.add(new haxe.languageservices.grammar.ParserError(mem1.pos,"static member " + mem1.name + " cannot be overriden"));
			} else if(mem1.modifiers.isOverride) this.errors.add(new haxe.languageservices.grammar.ParserError(mem1.pos,"member " + mem1.name + " not overriding anything"));
		}
		var _g3 = 0;
		var _g11 = type.members;
		while(_g3 < _g11.length) {
			var member = _g11[_g3];
			++_g3;
			var expectedType = this.getType(member.typeNode);
			var expressionType = this.getType(member.valueNode);
			if(!expectedType.canAssign(expressionType)) this.errors.add(new haxe.languageservices.grammar.ParserError(member.pos,"expression cannnot be assigned to explicit type"));
		}
	}
	,getType: function(node) {
		return this.types.getType("Dynamic");
	}
	,__class__: haxe.languageservices.grammar.HaxeTypeChecker
};
haxe.languageservices.grammar.A = function() { };
$hxClasses["haxe.languageservices.grammar.A"] = haxe.languageservices.grammar.A;
haxe.languageservices.grammar.A.__name__ = ["haxe","languageservices","grammar","A"];
haxe.languageservices.grammar.A.prototype = {
	test: function() {
		1;
	}
	,__class__: haxe.languageservices.grammar.A
};
haxe.languageservices.grammar.ParserError = function(pos,message) {
	this.pos = pos;
	this.message = message;
};
$hxClasses["haxe.languageservices.grammar.ParserError"] = haxe.languageservices.grammar.ParserError;
haxe.languageservices.grammar.ParserError.__name__ = ["haxe","languageservices","grammar","ParserError"];
haxe.languageservices.grammar.ParserError.prototype = {
	pos: null
	,message: null
	,toString: function() {
		return "" + Std.string(this.pos) + ":" + this.message;
	}
	,__class__: haxe.languageservices.grammar.ParserError
};
haxe.languageservices.node.NodeTools = function() { };
$hxClasses["haxe.languageservices.node.NodeTools"] = haxe.languageservices.node.NodeTools;
haxe.languageservices.node.NodeTools.__name__ = ["haxe","languageservices","node","NodeTools"];
haxe.languageservices.node.NodeTools.getId = function(znode) {
	{
		var _g = znode.node;
		switch(_g[1]) {
		case 0:
			var v = _g[2];
			return v;
		case 1:
			var v1 = _g[2];
			return v1;
		case 2:
			var v2 = _g[2];
			return v2;
		default:
			throw "Invalid id: " + Std.string(znode);
		}
	}
};
haxe.languageservices.node.NodeTools.dump = function(znode,iw) {
	if(iw == null) iw = new haxe.languageservices.util.IndentWriter();
	haxe.languageservices.node.NodeTools._dump(znode,iw);
	return iw;
};
haxe.languageservices.node.NodeTools._dump = function(item,iw) {
	if(js.Boot.__instanceof(item,haxe.languageservices.grammar.NNode)) haxe.languageservices.node.NodeTools._dump(Std.instance(item,haxe.languageservices.grammar.NNode).node,iw); else if(js.Boot.__instanceof(item,haxe.languageservices.node.Node)) {
		iw.write(Std.string(item) + "{\n");
		iw.indentStart();
		(function() {
			var _g = 0;
			var _g1 = Type.enumParameters(item);
			while(_g < _g1.length) {
				var i = _g1[_g];
				++_g;
				haxe.languageservices.node.NodeTools._dump(i,iw);
			}
		})();
		iw.indentEnd();
		iw.write("\n}\n");
	} else iw.write("" + Std.string(item));
};
haxe.languageservices.node.Position = function(min,max,reader) {
	this.min = min;
	this.max = max;
	this.reader = reader;
};
$hxClasses["haxe.languageservices.node.Position"] = haxe.languageservices.node.Position;
haxe.languageservices.node.Position.__name__ = ["haxe","languageservices","node","Position"];
haxe.languageservices.node.Position.combine = function(a,b) {
	return new haxe.languageservices.node.Position(Std["int"](Math.min(a.min,b.min)),Std["int"](Math.max(a.max,b.max)),a.reader);
};
haxe.languageservices.node.Position.prototype = {
	min: null
	,max: null
	,reader: null
	,contains: function(index) {
		return index >= this.min && index <= this.max;
	}
	,toString: function() {
		return "" + this.min + ":" + this.max;
	}
	,get_file: function() {
		return this.reader.file;
	}
	,get_text: function() {
		return this.reader.slice(this.min,this.max);
	}
	,__class__: haxe.languageservices.node.Position
	,__properties__: {get_file:"get_file",get_text:"get_text"}
};
haxe.languageservices.node.ProcessNodeContext = function() {
	this.nodes = new haxe.ds.ObjectMap();
};
$hxClasses["haxe.languageservices.node.ProcessNodeContext"] = haxe.languageservices.node.ProcessNodeContext;
haxe.languageservices.node.ProcessNodeContext.__name__ = ["haxe","languageservices","node","ProcessNodeContext"];
haxe.languageservices.node.ProcessNodeContext.prototype = {
	nodes: null
	,isExplored: function(node) {
		return this.nodes.h.__keys__[node.__id__] != null;
	}
	,recursionDetected: function() {
	}
	,markExplored: function(node) {
		this.nodes.set(node,true);
		true;
	}
	,__class__: haxe.languageservices.node.ProcessNodeContext
};
haxe.languageservices.node.Reader = function(str,file) {
	if(file == null) file = "file.hx";
	this.str = str;
	this.file = file;
	this.pos = 0;
};
$hxClasses["haxe.languageservices.node.Reader"] = haxe.languageservices.node.Reader;
haxe.languageservices.node.Reader.__name__ = ["haxe","languageservices","node","Reader"];
haxe.languageservices.node.Reader.prototype = {
	str: null
	,file: null
	,pos: null
	,reset: function() {
		this.pos = 0;
	}
	,eof: function() {
		return this.pos >= this.str.length;
	}
	,createPos: function(start,end) {
		if(start == null) start = this.pos;
		if(end == null) end = this.pos;
		return new haxe.languageservices.node.Position(start,end,this);
	}
	,slice: function(start,end) {
		return HxOverrides.substr(this.str,start,end - start);
	}
	,peek: function(count) {
		return HxOverrides.substr(this.str,this.pos,count);
	}
	,skip: function(count) {
		this.pos++;
	}
	,matchLit: function(lit) {
		if(HxOverrides.substr(this.str,this.pos,lit.length) != lit) return null;
		this.pos += lit.length;
		return lit;
	}
	,matchEReg: function(v) {
		if(!v.match(HxOverrides.substr(this.str,this.pos,null))) return null;
		var m = v.matched(0);
		this.pos += m.length;
		return m;
	}
	,matchStartEnd: function(start,end) {
		if(HxOverrides.substr(this.str,this.pos,start.length) != start) return null;
		var startIndex = this.pos;
		var index = this.str.indexOf(end,this.pos);
		if(index < 0) return null;
		this.pos = index + end.length;
		return this.slice(startIndex,this.pos);
	}
	,__class__: haxe.languageservices.node.Reader
};
haxe.languageservices.type = {};
haxe.languageservices.type.HaxeMember = function(pos,name) {
	this.modifiers = new haxe.languageservices.type.HaxeModifiers();
	this.pos = pos;
	this.name = name;
};
$hxClasses["haxe.languageservices.type.HaxeMember"] = haxe.languageservices.type.HaxeMember;
haxe.languageservices.type.HaxeMember.__name__ = ["haxe","languageservices","type","HaxeMember"];
haxe.languageservices.type.HaxeMember.prototype = {
	pos: null
	,name: null
	,modifiers: null
	,typeNode: null
	,valueNode: null
	,typeResolver: null
	,toString: function() {
		return "Member(" + this.name + ")";
	}
	,getType: function() {
		if(this.typeResolver != null) return this.typeResolver.resolve(); else return null;
	}
	,__class__: haxe.languageservices.type.HaxeMember
};
haxe.languageservices.type.MethodHaxeMember = function(pos,name) {
	haxe.languageservices.type.HaxeMember.call(this,pos,name);
};
$hxClasses["haxe.languageservices.type.MethodHaxeMember"] = haxe.languageservices.type.MethodHaxeMember;
haxe.languageservices.type.MethodHaxeMember.__name__ = ["haxe","languageservices","type","MethodHaxeMember"];
haxe.languageservices.type.MethodHaxeMember.__super__ = haxe.languageservices.type.HaxeMember;
haxe.languageservices.type.MethodHaxeMember.prototype = $extend(haxe.languageservices.type.HaxeMember.prototype,{
	toString: function() {
		return "Method(" + this.name + ")";
	}
	,__class__: haxe.languageservices.type.MethodHaxeMember
});
haxe.languageservices.type.FieldHaxeMember = function(pos,name) {
	haxe.languageservices.type.HaxeMember.call(this,pos,name);
};
$hxClasses["haxe.languageservices.type.FieldHaxeMember"] = haxe.languageservices.type.FieldHaxeMember;
haxe.languageservices.type.FieldHaxeMember.__name__ = ["haxe","languageservices","type","FieldHaxeMember"];
haxe.languageservices.type.FieldHaxeMember.__super__ = haxe.languageservices.type.HaxeMember;
haxe.languageservices.type.FieldHaxeMember.prototype = $extend(haxe.languageservices.type.HaxeMember.prototype,{
	toString: function() {
		return "Field(" + this.name + ")";
	}
	,__class__: haxe.languageservices.type.FieldHaxeMember
});
haxe.languageservices.type.HaxeModifiers = function() {
	this.isOverride = false;
	this.isStatic = false;
	this.isPrivate = false;
	this.isPublic = false;
};
$hxClasses["haxe.languageservices.type.HaxeModifiers"] = haxe.languageservices.type.HaxeModifiers;
haxe.languageservices.type.HaxeModifiers.__name__ = ["haxe","languageservices","type","HaxeModifiers"];
haxe.languageservices.type.HaxeModifiers.prototype = {
	isPublic: null
	,isPrivate: null
	,isStatic: null
	,isOverride: null
	,reset: function() {
		this.isOverride = false;
		this.isPrivate = false;
		this.isPublic = false;
		this.isStatic = false;
	}
	,add: function(n) {
		switch(n) {
		case "public":
			this.isPublic = true;
			break;
		case "private":
			this.isPrivate = true;
			break;
		case "static":
			this.isStatic = true;
			break;
		case "override":
			this.isOverride = true;
			break;
		default:
			throw "Invalid haxe modifier";
		}
	}
	,__class__: haxe.languageservices.type.HaxeModifiers
};
haxe.languageservices.type.HaxePackage = function(base,name,parent) {
	this.types = new haxe.ds.StringMap();
	this.children = new haxe.ds.StringMap();
	this.base = base;
	this.parent = parent;
	this.name = name;
	if(parent != null) {
		parent.children.set(name,this);
		if(parent.fqName != "") this.fqName = parent.fqName + "." + name; else this.fqName = name;
		this.root = parent.root;
	} else {
		this.fqName = name;
		this.root = this;
	}
};
$hxClasses["haxe.languageservices.type.HaxePackage"] = haxe.languageservices.type.HaxePackage;
haxe.languageservices.type.HaxePackage.__name__ = ["haxe","languageservices","type","HaxePackage"];
haxe.languageservices.type.HaxePackage.prototype = {
	base: null
	,root: null
	,parent: null
	,fqName: null
	,name: null
	,children: null
	,types: null
	,isLeaf: function() {
		var $it0 = this.children.iterator();
		while( $it0.hasNext() ) {
			var child = $it0.next();
			return false;
		}
		return true;
	}
	,getAllTypes: function() {
		var _g = [];
		var _g1 = 0;
		var _g2 = this.getAll();
		while(_g1 < _g2.length) {
			var p = _g2[_g1];
			++_g1;
			var $it0 = p.types.iterator();
			while( $it0.hasNext() ) {
				var t = $it0.next();
				_g.push(t);
			}
		}
		return _g;
	}
	,getLeafs: function() {
		return this.getAll().filter(function(p) {
			return p.isLeaf();
		});
	}
	,getAll: function(out) {
		if(out == null) out = [];
		out.push(this);
		var $it0 = this.children.iterator();
		while( $it0.hasNext() ) {
			var child = $it0.next();
			child.getAll(out);
		}
		return out;
	}
	,toString: function() {
		return "Package(\"" + this.name + "\"," + Std.string((function($this) {
			var $r;
			var _g = [];
			var $it0 = $this.children.iterator();
			while( $it0.hasNext() ) {
				var child = $it0.next();
				_g.push(child);
			}
			$r = _g;
			return $r;
		}(this))) + ")";
	}
	,access: function(path,create) {
		if(path == null) return null;
		return this.accessParts(path.split("."),create);
	}
	,accessType: function(path) {
		return this._accessType(path,false,null,null);
	}
	,accessTypeCreate: function(path,pos,type) {
		return this._accessType(path,true,pos,type);
	}
	,_accessType: function(path,create,pos,type) {
		if(path == null) return null;
		var parts = path.split(".");
		var typeName = parts.pop();
		var packag = this.accessParts(parts,create);
		var exists = packag.types.exists(typeName);
		if(exists && create) haxe.Log.trace("type already exists, recreating",{ fileName : "HaxePackage.hx", lineNumber : 71, className : "haxe.languageservices.type.HaxePackage", methodName : "_accessType"});
		if(create) {
			var v = Type.createInstance(type,[packag,pos,typeName]);
			packag.types.set(typeName,v);
			return v;
		}
		if(exists) return packag.types.get(typeName);
		return null;
	}
	,accessParts: function(parts,create) {
		var node = this;
		var _g = 0;
		while(_g < parts.length) {
			var part = parts[_g];
			++_g;
			if(node.children.exists(part)) node = node.children.get(part); else {
				if(!create) return null;
				var v = new haxe.languageservices.type.HaxePackage(this.base,part,node);
				node.children.set(part,v);
				node = v;
			}
		}
		return node;
	}
	,__class__: haxe.languageservices.type.HaxePackage
};
haxe.languageservices.type.HaxeType = function(packag,pos,name) {
	this.membersByName = new haxe.ds.StringMap();
	this.members = new Array();
	this.typeParameters = new Array();
	this.packag = packag;
	this.types = packag.base;
	this.pos = pos;
	this.name = name;
	if(packag.fqName != "") this.fqName = "" + packag.fqName + "." + name; else this.fqName = name;
};
$hxClasses["haxe.languageservices.type.HaxeType"] = haxe.languageservices.type.HaxeType;
haxe.languageservices.type.HaxeType.__name__ = ["haxe","languageservices","type","HaxeType"];
haxe.languageservices.type.HaxeType.prototype = {
	pos: null
	,packag: null
	,types: null
	,name: null
	,fqName: null
	,typeParameters: null
	,members: null
	,membersByName: null
	,node: null
	,toString: function() {
		return "Type(\"" + this.fqName + "\", " + Std.string(this.members) + ")";
	}
	,existsMember: function(name) {
		return this.membersByName.exists(name);
	}
	,getMember: function(name) {
		return this.membersByName.get(name);
	}
	,addMember: function(member) {
		this.members.push(member);
		this.membersByName.set(member.name,member);
	}
	,remove: function() {
		this.packag.types.remove(this.name);
	}
	,canAssign: function(that) {
		return true;
	}
	,__class__: haxe.languageservices.type.HaxeType
};
haxe.languageservices.type.SpecificHaxeType = function(types,type,parameters) {
	if(type == null) type = types.typeDynamic;
	if(parameters == null) parameters = [];
	this.type = type;
	this.parameters = parameters;
};
$hxClasses["haxe.languageservices.type.SpecificHaxeType"] = haxe.languageservices.type.SpecificHaxeType;
haxe.languageservices.type.SpecificHaxeType.__name__ = ["haxe","languageservices","type","SpecificHaxeType"];
haxe.languageservices.type.SpecificHaxeType.prototype = {
	type: null
	,parameters: null
	,toString: function() {
		var res = "" + this.type.fqName;
		if(this.parameters.length > 0) res += "<" + this.parameters.join(",") + ">";
		return res;
	}
	,__class__: haxe.languageservices.type.SpecificHaxeType
};
haxe.languageservices.type.TypeReference = function(types,fqName,expr) {
	this.types = types;
	this.fqName = fqName;
	this.expr = expr;
};
$hxClasses["haxe.languageservices.type.TypeReference"] = haxe.languageservices.type.TypeReference;
haxe.languageservices.type.TypeReference.__name__ = ["haxe","languageservices","type","TypeReference"];
haxe.languageservices.type.TypeReference.prototype = {
	types: null
	,fqName: null
	,expr: null
	,getType: function() {
		return this.types.getType(this.fqName);
	}
	,getClass: function() {
		return this.types.getClass(this.fqName);
	}
	,getInterface: function() {
		return this.types.getInterface(this.fqName);
	}
	,__class__: haxe.languageservices.type.TypeReference
};
haxe.languageservices.type.ClassHaxeType = function(packag,pos,name) {
	this.implementing = [];
	haxe.languageservices.type.HaxeType.call(this,packag,pos,name);
};
$hxClasses["haxe.languageservices.type.ClassHaxeType"] = haxe.languageservices.type.ClassHaxeType;
haxe.languageservices.type.ClassHaxeType.__name__ = ["haxe","languageservices","type","ClassHaxeType"];
haxe.languageservices.type.ClassHaxeType.__super__ = haxe.languageservices.type.HaxeType;
haxe.languageservices.type.ClassHaxeType.prototype = $extend(haxe.languageservices.type.HaxeType.prototype,{
	extending: null
	,implementing: null
	,getExtending: function() {
		if(this.extending == null) return null;
		return this.extending.getClass();
	}
	,getAncestorMembers: function() {
		if(this.getExtending() == null) return new haxe.ds.StringMap();
		return this.getExtending().getThisAndAncestorMembers();
	}
	,getThisMembers: function() {
		return this.membersByName;
	}
	,getThisAndAncestorMembers: function(out) {
		if(out == null) out = new haxe.ds.StringMap();
		var _g = 0;
		var _g1 = this.members;
		while(_g < _g1.length) {
			var m = _g1[_g];
			++_g;
			out.set(m.name,m);
		}
		if(this.getExtending() != null) this.getExtending().getThisAndAncestorMembers(out);
		return out;
	}
	,getAllExpectedImplementingMembers: function() {
		var out = new Array();
		var _g = 0;
		var _g1 = this.implementing;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			var ii = i.getInterface();
			if(ii != null) ii.getAllImplementingMembers(out);
		}
		return out;
	}
	,__class__: haxe.languageservices.type.ClassHaxeType
});
haxe.languageservices.type.InterfaceHaxeType = function(packag,pos,name) {
	this.implementing = new Array();
	haxe.languageservices.type.HaxeType.call(this,packag,pos,name);
};
$hxClasses["haxe.languageservices.type.InterfaceHaxeType"] = haxe.languageservices.type.InterfaceHaxeType;
haxe.languageservices.type.InterfaceHaxeType.__name__ = ["haxe","languageservices","type","InterfaceHaxeType"];
haxe.languageservices.type.InterfaceHaxeType.__super__ = haxe.languageservices.type.HaxeType;
haxe.languageservices.type.InterfaceHaxeType.prototype = $extend(haxe.languageservices.type.HaxeType.prototype,{
	implementing: null
	,getAllImplementingMembers: function(out) {
		if(out == null) out = [];
		var _g = 0;
		var _g1 = this.implementing;
		while(_g < _g1.length) {
			var i = _g1[_g];
			++_g;
			i.getAllImplementingMembers(out);
		}
		var _g2 = 0;
		var _g11 = this.members;
		while(_g2 < _g11.length) {
			var m = _g11[_g2];
			++_g2;
			out.push(m);
		}
		return out;
	}
	,__class__: haxe.languageservices.type.InterfaceHaxeType
});
haxe.languageservices.type.EnumHaxeType = function(packag,pos,name) {
	haxe.languageservices.type.HaxeType.call(this,packag,pos,name);
};
$hxClasses["haxe.languageservices.type.EnumHaxeType"] = haxe.languageservices.type.EnumHaxeType;
haxe.languageservices.type.EnumHaxeType.__name__ = ["haxe","languageservices","type","EnumHaxeType"];
haxe.languageservices.type.EnumHaxeType.__super__ = haxe.languageservices.type.HaxeType;
haxe.languageservices.type.EnumHaxeType.prototype = $extend(haxe.languageservices.type.HaxeType.prototype,{
	__class__: haxe.languageservices.type.EnumHaxeType
});
haxe.languageservices.type.AbstractHaxeType = function(packag,pos,name) {
	haxe.languageservices.type.HaxeType.call(this,packag,pos,name);
};
$hxClasses["haxe.languageservices.type.AbstractHaxeType"] = haxe.languageservices.type.AbstractHaxeType;
haxe.languageservices.type.AbstractHaxeType.__name__ = ["haxe","languageservices","type","AbstractHaxeType"];
haxe.languageservices.type.AbstractHaxeType.__super__ = haxe.languageservices.type.HaxeType;
haxe.languageservices.type.AbstractHaxeType.prototype = $extend(haxe.languageservices.type.HaxeType.prototype,{
	__class__: haxe.languageservices.type.AbstractHaxeType
});
haxe.languageservices.type.TypedefHaxeType = function(packag,pos,name) {
	haxe.languageservices.type.HaxeType.call(this,packag,pos,name);
};
$hxClasses["haxe.languageservices.type.TypedefHaxeType"] = haxe.languageservices.type.TypedefHaxeType;
haxe.languageservices.type.TypedefHaxeType.__name__ = ["haxe","languageservices","type","TypedefHaxeType"];
haxe.languageservices.type.TypedefHaxeType.__super__ = haxe.languageservices.type.HaxeType;
haxe.languageservices.type.TypedefHaxeType.prototype = $extend(haxe.languageservices.type.HaxeType.prototype,{
	destType: null
	,__class__: haxe.languageservices.type.TypedefHaxeType
});
haxe.languageservices.type.HaxeTypeParameter = function(name,constraints) {
	this.name = name;
	this.constraints = constraints;
};
$hxClasses["haxe.languageservices.type.HaxeTypeParameter"] = haxe.languageservices.type.HaxeTypeParameter;
haxe.languageservices.type.HaxeTypeParameter.__name__ = ["haxe","languageservices","type","HaxeTypeParameter"];
haxe.languageservices.type.HaxeTypeParameter.prototype = {
	name: null
	,constraints: null
	,__class__: haxe.languageservices.type.HaxeTypeParameter
};
haxe.languageservices.type.HaxeTypeResolver = function() { };
$hxClasses["haxe.languageservices.type.HaxeTypeResolver"] = haxe.languageservices.type.HaxeTypeResolver;
haxe.languageservices.type.HaxeTypeResolver.__name__ = ["haxe","languageservices","type","HaxeTypeResolver"];
haxe.languageservices.type.HaxeTypeResolver.prototype = {
	resolve: null
	,__class__: haxe.languageservices.type.HaxeTypeResolver
};
haxe.languageservices.type.HaxeTypes = function() {
	this.rootPackage = new haxe.languageservices.type.HaxePackage(this,"");
	this.typeDynamic = this.rootPackage.accessTypeCreate("Dynamic",new haxe.languageservices.node.Position(0,0,new haxe.languageservices.node.Reader("","Dynamic.hx")),haxe.languageservices.type.ClassHaxeType);
	this.typeBool = this.rootPackage.accessTypeCreate("Bool",new haxe.languageservices.node.Position(0,0,new haxe.languageservices.node.Reader("","Bool.hx")),haxe.languageservices.type.ClassHaxeType);
	this.typeInt = this.rootPackage.accessTypeCreate("Int",new haxe.languageservices.node.Position(0,0,new haxe.languageservices.node.Reader("","Int.hx")),haxe.languageservices.type.ClassHaxeType);
	this.typeFloat = this.rootPackage.accessTypeCreate("Float",new haxe.languageservices.node.Position(0,0,new haxe.languageservices.node.Reader("","Float.hx")),haxe.languageservices.type.ClassHaxeType);
	this.typeArray = this.rootPackage.accessTypeCreate("Array",new haxe.languageservices.node.Position(0,0,new haxe.languageservices.node.Reader("","Array.hx")),haxe.languageservices.type.ClassHaxeType);
	this.specTypeDynamic = new haxe.languageservices.type.SpecificHaxeType(this,this.typeDynamic);
	this.specTypeBool = new haxe.languageservices.type.SpecificHaxeType(this,this.typeBool);
	this.specTypeInt = new haxe.languageservices.type.SpecificHaxeType(this,this.typeInt);
	this.specTypeFloat = new haxe.languageservices.type.SpecificHaxeType(this,this.typeFloat);
};
$hxClasses["haxe.languageservices.type.HaxeTypes"] = haxe.languageservices.type.HaxeTypes;
haxe.languageservices.type.HaxeTypes.__name__ = ["haxe","languageservices","type","HaxeTypes"];
haxe.languageservices.type.HaxeTypes.prototype = {
	rootPackage: null
	,typeDynamic: null
	,typeBool: null
	,typeInt: null
	,typeFloat: null
	,typeArray: null
	,specTypeDynamic: null
	,specTypeBool: null
	,specTypeInt: null
	,specTypeFloat: null
	,unify: function(types) {
		if(types.length == 0) return new haxe.languageservices.type.SpecificHaxeType(this,this.typeDynamic);
		return types[0];
	}
	,getType: function(path) {
		if(HxOverrides.substr(path,0,1) == ":") return this.getType(HxOverrides.substr(path,1,null));
		return this.rootPackage.accessType(path);
	}
	,getClass: function(path) {
		return Std.instance(this.getType(path),haxe.languageservices.type.ClassHaxeType);
	}
	,getInterface: function(path) {
		return Std.instance(this.getType(path),haxe.languageservices.type.InterfaceHaxeType);
	}
	,createArray: function(elementType) {
		return new haxe.languageservices.type.SpecificHaxeType(this,this.typeArray,[elementType]);
	}
	,getArrayElement: function(arrayType) {
		if(arrayType == null || arrayType.parameters.length < 1) return new haxe.languageservices.type.SpecificHaxeType(this,this.typeDynamic);
		return arrayType.parameters[0];
	}
	,getAllTypes: function() {
		return this.rootPackage.getAllTypes();
	}
	,getLeafPackageNames: function() {
		return this.rootPackage.getLeafs().map(function(p) {
			return p.fqName;
		});
	}
	,__class__: haxe.languageservices.type.HaxeTypes
};
haxe.languageservices.util = {};
haxe.languageservices.util.Vfs = function() {
};
$hxClasses["haxe.languageservices.util.Vfs"] = haxe.languageservices.util.Vfs;
haxe.languageservices.util.Vfs.__name__ = ["haxe","languageservices","util","Vfs"];
haxe.languageservices.util.Vfs.prototype = {
	_exists: function(path) {
		throw "Not implemented";
		return false;
	}
	,_listFiles: function(path) {
		throw "Not implemented";
		return null;
	}
	,_readString: function(path) {
		throw "Not implemented";
		return null;
	}
	,_exec: function(cmd,args) {
		throw "Not implemented";
		return null;
	}
	,normalizePath: function(path) {
		return haxe.languageservices.util.PathUtils.combine(path,".");
	}
	,exists: function(path) {
		return this._exists(this.normalizePath(path));
	}
	,listFiles: function(path) {
		return this._listFiles(this.normalizePath(path));
	}
	,readString: function(path) {
		return this._readString(this.normalizePath(path));
	}
	,exec: function(cmd,args) {
		return this._exec(cmd,args);
	}
	,access: function(path) {
		return new haxe.languageservices.util.AccessVfs(this,this.normalizePath(path));
	}
	,__class__: haxe.languageservices.util.Vfs
};
haxe.languageservices.util.ProxyVfs = function(parent) {
	this.parent = parent;
	haxe.languageservices.util.Vfs.call(this);
};
$hxClasses["haxe.languageservices.util.ProxyVfs"] = haxe.languageservices.util.ProxyVfs;
haxe.languageservices.util.ProxyVfs.__name__ = ["haxe","languageservices","util","ProxyVfs"];
haxe.languageservices.util.ProxyVfs.__super__ = haxe.languageservices.util.Vfs;
haxe.languageservices.util.ProxyVfs.prototype = $extend(haxe.languageservices.util.Vfs.prototype,{
	parent: null
	,transformPath: function(path) {
		return path;
	}
	,_exists: function(path) {
		return this.parent.exists(this.transformPath(path));
	}
	,_listFiles: function(path) {
		return this.parent.listFiles(this.transformPath(path));
	}
	,_readString: function(path) {
		return this.parent.readString(this.transformPath(path));
	}
	,_exec: function(cmd,args) {
		return this.parent.exec(cmd,args);
	}
	,__class__: haxe.languageservices.util.ProxyVfs
});
haxe.languageservices.util.AccessVfs = function(parent,accessPath) {
	haxe.languageservices.util.ProxyVfs.call(this,parent);
	this.accessPath = accessPath;
};
$hxClasses["haxe.languageservices.util.AccessVfs"] = haxe.languageservices.util.AccessVfs;
haxe.languageservices.util.AccessVfs.__name__ = ["haxe","languageservices","util","AccessVfs"];
haxe.languageservices.util.AccessVfs.__super__ = haxe.languageservices.util.ProxyVfs;
haxe.languageservices.util.AccessVfs.prototype = $extend(haxe.languageservices.util.ProxyVfs.prototype,{
	accessPath: null
	,transformPath: function(path) {
		return "" + this.accessPath + "/" + path;
	}
	,__class__: haxe.languageservices.util.AccessVfs
});
haxe.languageservices.util.IndentWriter = function() {
	this.startLine = true;
	this.indents = [];
	this.indentCount = 0;
	this.output = "";
};
$hxClasses["haxe.languageservices.util.IndentWriter"] = haxe.languageservices.util.IndentWriter;
haxe.languageservices.util.IndentWriter.__name__ = ["haxe","languageservices","util","IndentWriter"];
haxe.languageservices.util.IndentWriter.prototype = {
	output: null
	,indentCount: null
	,indents: null
	,startLine: null
	,write: function(text) {
		if(text.indexOf("\n") < 0) return this.writeChunk(text);
		var first = true;
		var _g = 0;
		var _g1 = text.split("\n");
		while(_g < _g1.length) {
			var chunk = _g1[_g];
			++_g;
			if(!first) this.writeEol();
			this.writeChunk(chunk);
			first = false;
		}
	}
	,writeEol: function() {
		this.output += "\n";
		this.startLine = true;
	}
	,writeChunk: function(text) {
		if(text == "") return;
		if(this.startLine && this.indents != null && this.indents.length > 0) this.output += this.indents.join("");
		this.output += text;
		this.startLine = false;
	}
	,indentStart: function() {
		this.indents.push("\t");
		this.indentCount++;
	}
	,indentEnd: function() {
		this.indentCount--;
		this.indents.pop();
	}
	,indent: function(callback) {
		this.indentStart();
		callback();
		this.indentEnd();
	}
	,toString: function() {
		return this.output;
	}
	,__class__: haxe.languageservices.util.IndentWriter
};
haxe.languageservices.util.MemoryVfs = function() {
	this.root = new haxe.languageservices.util.MemoryNode("");
	haxe.languageservices.util.Vfs.call(this);
};
$hxClasses["haxe.languageservices.util.MemoryVfs"] = haxe.languageservices.util.MemoryVfs;
haxe.languageservices.util.MemoryVfs.__name__ = ["haxe","languageservices","util","MemoryVfs"];
haxe.languageservices.util.MemoryVfs.__super__ = haxe.languageservices.util.Vfs;
haxe.languageservices.util.MemoryVfs.prototype = $extend(haxe.languageservices.util.Vfs.prototype,{
	root: null
	,_exists: function(path) {
		return this.root.access(path) != null;
	}
	,_listFiles: function(path) {
		return this.root.access(path).filenames();
	}
	,_readString: function(path) {
		return this.root.access(path).content;
	}
	,set: function(path,content) {
		this.root.access(path,true).content = content;
		return this;
	}
	,__class__: haxe.languageservices.util.MemoryVfs
});
haxe.languageservices.util.MemoryNode = function(name) {
	this.content = "";
	this.children = new haxe.ds.StringMap();
	this.name = name;
};
$hxClasses["haxe.languageservices.util.MemoryNode"] = haxe.languageservices.util.MemoryNode;
haxe.languageservices.util.MemoryNode.__name__ = ["haxe","languageservices","util","MemoryNode"];
haxe.languageservices.util.MemoryNode.prototype = {
	name: null
	,children: null
	,content: null
	,filenames: function() {
		var _g = [];
		var $it0 = this.children.iterator();
		while( $it0.hasNext() ) {
			var child = $it0.next();
			_g.push(child.name);
		}
		return _g;
	}
	,access: function(path,create) {
		if(create == null) create = false;
		var parts = path.split("/");
		var current = this;
		var _g = 0;
		while(_g < parts.length) {
			var part = parts[_g];
			++_g;
			if(current.children.get(part) == null) {
				if(create) {
					var v = new haxe.languageservices.util.MemoryNode(part);
					current.children.set(part,v);
					current = v;
				} else return null;
			} else current = current.children.get(part);
		}
		return current;
	}
	,__class__: haxe.languageservices.util.MemoryNode
};
haxe.languageservices.util.PathUtils = function() { };
$hxClasses["haxe.languageservices.util.PathUtils"] = haxe.languageservices.util.PathUtils;
haxe.languageservices.util.PathUtils.__name__ = ["haxe","languageservices","util","PathUtils"];
haxe.languageservices.util.PathUtils.isAbsolute = function(path) {
	if(StringTools.startsWith(path,"/")) return true;
	if(HxOverrides.substr(path,1,1) == ":") return true;
	return false;
};
haxe.languageservices.util.PathUtils.combine = function(p1,p2) {
	p1 = StringTools.replace(p1,"\\","/");
	p2 = StringTools.replace(p2,"\\","/");
	if(haxe.languageservices.util.PathUtils.isAbsolute(p2)) return p2;
	var parts = [];
	var _g = 0;
	var _g1 = p1.split("/").concat(p2.split("/"));
	while(_g < _g1.length) {
		var part = _g1[_g];
		++_g;
		switch(part) {
		case ".":case "":
			break;
		case "..":
			if(parts.length > 0) parts.pop();
			break;
		default:
			parts.push(part);
		}
	}
	var result = parts.join("/");
	if(StringTools.startsWith(p1,"/")) return "/" + result; else return result;
};
haxe.languageservices.util.Scope = function(parent) {
	this.parent = parent;
	this.map = new haxe.ds.StringMap();
};
$hxClasses["haxe.languageservices.util.Scope"] = haxe.languageservices.util.Scope;
haxe.languageservices.util.Scope.__name__ = ["haxe","languageservices","util","Scope"];
haxe.languageservices.util.Scope.prototype = {
	parent: null
	,map: null
	,exists: function(key) {
		if(this.map.exists(key)) return true;
		if(this.parent != null) return this.parent.exists(key);
		return false;
	}
	,get: function(key) {
		if(this.map.exists(key)) return this.map.get(key);
		if(this.parent != null) return this.parent.get(key);
		return null;
	}
	,set: function(key,value) {
		return this.map.set(key,value);
	}
	,keys: function(out) {
		if(out == null) out = [];
		var $it0 = this.map.keys();
		while( $it0.hasNext() ) {
			var key = $it0.next();
			if(HxOverrides.indexOf(out,key,0) < 0) out.push(key);
		}
		if(this.parent != null) this.parent.keys(out);
		return out;
	}
	,values: function(out) {
		if(out == null) out = [];
		var _g = 0;
		var _g1 = this.keys();
		while(_g < _g1.length) {
			var key = _g1[_g];
			++_g;
			out.push(this.get(key));
		}
		return out;
	}
	,createChild: function() {
		return new haxe.languageservices.util.Scope(this);
	}
	,toString: function() {
		return "Scope(" + Std.string((function($this) {
			var $r;
			var _g = [];
			var $it0 = $this.map.keys();
			while( $it0.hasNext() ) {
				var key = $it0.next();
				_g.push(key);
			}
			$r = _g;
			return $r;
		}(this))) + ", " + Std.string(this.parent) + ")";
	}
	,__class__: haxe.languageservices.util.Scope
};
haxe.languageservices.util.StringUtils = function() { };
$hxClasses["haxe.languageservices.util.StringUtils"] = haxe.languageservices.util.StringUtils;
haxe.languageservices.util.StringUtils.__name__ = ["haxe","languageservices","util","StringUtils"];
haxe.languageservices.util.StringUtils.compare = function(a,b) {
	if(a < b) return -1; else if(a > b) return 1; else return 0;
};
haxe.languageservices.util.StringUtils.isLowerCase = function(a) {
	return a == a.toLowerCase();
};
haxe.languageservices.util.StringUtils.isUpperCase = function(a) {
	return a == a.toUpperCase();
};
haxe.languageservices.util.StringUtils.isFirstUpper = function(a) {
	return haxe.languageservices.util.StringUtils.isUpperCase(HxOverrides.substr(a,0,1));
};
var js = {};
js.Boot = function() { };
$hxClasses["js.Boot"] = js.Boot;
js.Boot.__name__ = ["js","Boot"];
js.Boot.__unhtml = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
};
js.Boot.__trace = function(v,i) {
	var msg;
	if(i != null) msg = i.fileName + ":" + i.lineNumber + ": "; else msg = "";
	msg += js.Boot.__string_rec(v,"");
	if(i != null && i.customParams != null) {
		var _g = 0;
		var _g1 = i.customParams;
		while(_g < _g1.length) {
			var v1 = _g1[_g];
			++_g;
			msg += "," + js.Boot.__string_rec(v1,"");
		}
	}
	var d;
	if(typeof(document) != "undefined" && (d = document.getElementById("haxe:trace")) != null) d.innerHTML += js.Boot.__unhtml(msg) + "<br/>"; else if(typeof console != "undefined" && console.log != null) console.log(msg);
};
js.Boot.__clear_trace = function() {
	var d = document.getElementById("haxe:trace");
	if(d != null) d.innerHTML = "";
};
js.Boot.isClass = function(o) {
	return o.__name__;
};
js.Boot.isEnum = function(e) {
	return e.__ename__;
};
js.Boot.getClass = function(o) {
	if((o instanceof Array) && o.__enum__ == null) return Array; else return o.__class__;
};
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i1;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js.Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str2 = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str2.length != 2) str2 += ", \n";
		str2 += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str2 += "\n" + s + "}";
		return str2;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
js.Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0;
		var _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js.Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js.Boot.__interfLoop(cc.__super__,cl);
};
js.Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Array:
		return (o instanceof Array) && o.__enum__ == null;
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) return true;
				if(js.Boot.__interfLoop(js.Boot.getClass(o),cl)) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
};
js.Boot.__cast = function(o,t) {
	if(js.Boot.__instanceof(o,t)) return o; else throw "Cannot cast " + Std.string(o) + " to " + Std.string(t);
};
js.Browser = function() { };
$hxClasses["js.Browser"] = js.Browser;
js.Browser.__name__ = ["js","Browser"];
js.Browser.__properties__ = {get_supported:"get_supported",get_navigator:"get_navigator",get_location:"get_location",get_document:"get_document",get_window:"get_window"}
js.Browser.get_window = function() {
	return window;
};
js.Browser.get_document = function() {
	return window.document;
};
js.Browser.get_location = function() {
	return window.location;
};
js.Browser.get_navigator = function() {
	return window.navigator;
};
js.Browser.get_supported = function() {
	return typeof window != "undefined";
};
js.Browser.getLocalStorage = function() {
	try {
		var s = window.localStorage;
		s.getItem("");
		return s;
	} catch( e ) {
		return null;
	}
};
js.Browser.getSessionStorage = function() {
	try {
		var s = window.sessionStorage;
		s.getItem("");
		return s;
	} catch( e ) {
		return null;
	}
};
js.Browser.createXMLHttpRequest = function() {
	if(typeof XMLHttpRequest != "undefined") return new XMLHttpRequest();
	if(typeof ActiveXObject != "undefined") return new ActiveXObject("Microsoft.XMLHTTP");
	throw "Unable to create XMLHttpRequest object.";
};
js.html = {};
js.html._CanvasElement = {};
js.html._CanvasElement.CanvasUtil = function() { };
$hxClasses["js.html._CanvasElement.CanvasUtil"] = js.html._CanvasElement.CanvasUtil;
js.html._CanvasElement.CanvasUtil.__name__ = ["js","html","_CanvasElement","CanvasUtil"];
js.html._CanvasElement.CanvasUtil.getContextWebGL = function(canvas,attribs) {
	var _g = 0;
	var _g1 = ["webgl","experimental-webgl"];
	while(_g < _g1.length) {
		var name = _g1[_g];
		++_g;
		var ctx = canvas.getContext(name,attribs);
		if(ctx != null) return ctx;
	}
	return null;
};
function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; }
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
if(Array.prototype.indexOf) HxOverrides.indexOf = function(a,o,i) {
	return Array.prototype.indexOf.call(a,o,i);
};
if(Array.prototype.lastIndexOf) HxOverrides.lastIndexOf = function(a1,o1,i1) {
	return Array.prototype.lastIndexOf.call(a1,o1,i1);
};
Math.NaN = Number.NaN;
Math.NEGATIVE_INFINITY = Number.NEGATIVE_INFINITY;
Math.POSITIVE_INFINITY = Number.POSITIVE_INFINITY;
$hxClasses.Math = Math;
Math.isFinite = function(i) {
	return isFinite(i);
};
Math.isNaN = function(i1) {
	return isNaN(i1);
};
String.prototype.__class__ = $hxClasses.String = String;
String.__name__ = ["String"];
$hxClasses.Array = Array;
Array.__name__ = ["Array"];
Date.prototype.__class__ = $hxClasses.Date = Date;
Date.__name__ = ["Date"];
var Int = $hxClasses.Int = { __name__ : ["Int"]};
var Dynamic = $hxClasses.Dynamic = { __name__ : ["Dynamic"]};
var Float = $hxClasses.Float = Number;
Float.__name__ = ["Float"];
var Bool = $hxClasses.Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = $hxClasses.Class = { __name__ : ["Class"]};
var Enum = { };
var Void = $hxClasses.Void = { __ename__ : ["Void"]};
if(Array.prototype.map == null) Array.prototype.map = function(f) {
	var a = [];
	var _g1 = 0;
	var _g = this.length;
	while(_g1 < _g) {
		var i = _g1++;
		a[i] = f(this[i]);
	}
	return a;
};
if(Array.prototype.filter == null) Array.prototype.filter = function(f1) {
	var a1 = [];
	var _g11 = 0;
	var _g2 = this.length;
	while(_g11 < _g2) {
		var i1 = _g11++;
		var e = this[i1];
		if(f1(e)) a1.push(e);
	}
	return a1;
};
haxe.ds.ObjectMap.count = 0;
haxe.languageservices.CompFileContext.grammar = new haxe.languageservices.grammar.HaxeGrammar();
haxe.languageservices.grammar.CompletionScope.lastUid = 0;
MainIde.main();
})();

//# sourceMappingURL=mainide.js.map