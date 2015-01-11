(function () { "use strict";
var $hxClasses = {},$estr = function() { return js.Boot.__string_rec(this,''); };
function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
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
var List = function() {
	this.length = 0;
};
$hxClasses["List"] = List;
List.__name__ = ["List"];
List.prototype = {
	h: null
	,q: null
	,length: null
	,add: function(item) {
		var x = [item];
		if(this.h == null) this.h = x; else this.q[1] = x;
		this.q = x;
		this.length++;
	}
	,push: function(item) {
		var x = [item,this.h];
		this.h = x;
		if(this.q == null) this.q = x;
		this.length++;
	}
	,first: function() {
		if(this.h == null) return null; else return this.h[0];
	}
	,last: function() {
		if(this.q == null) return null; else return this.q[0];
	}
	,pop: function() {
		if(this.h == null) return null;
		var x = this.h[0];
		this.h = this.h[1];
		if(this.h == null) this.q = null;
		this.length--;
		return x;
	}
	,isEmpty: function() {
		return this.h == null;
	}
	,clear: function() {
		this.h = null;
		this.q = null;
		this.length = 0;
	}
	,remove: function(v) {
		var prev = null;
		var l = this.h;
		while(l != null) {
			if(l[0] == v) {
				if(prev == null) this.h = l[1]; else prev[1] = l[1];
				if(this.q == l) this.q = prev;
				this.length--;
				return true;
			}
			prev = l;
			l = l[1];
		}
		return false;
	}
	,iterator: function() {
		return { h : this.h, hasNext : function() {
			return this.h != null;
		}, next : function() {
			if(this.h == null) return null;
			var x = this.h[0];
			this.h = this.h[1];
			return x;
		}};
	}
	,toString: function() {
		var s = new StringBuf();
		var first = true;
		var l = this.h;
		s.b += "{";
		while(l != null) {
			if(first) first = false; else s.b += ", ";
			s.add(Std.string(l[0]));
			l = l[1];
		}
		s.b += "}";
		return s.b;
	}
	,join: function(sep) {
		var s = new StringBuf();
		var first = true;
		var l = this.h;
		while(l != null) {
			if(first) first = false; else if(sep == null) s.b += "null"; else s.b += "" + sep;
			s.b += Std.string(l[0]);
			l = l[1];
		}
		return s.b;
	}
	,filter: function(f) {
		var l2 = new List();
		var l = this.h;
		while(l != null) {
			var v = l[0];
			l = l[1];
			if(f(v)) l2.add(v);
		}
		return l2;
	}
	,map: function(f) {
		var b = new List();
		var l = this.h;
		while(l != null) {
			var v = l[0];
			l = l[1];
			b.add(f(v));
		}
		return b;
	}
	,__class__: List
};
var MainIde = function() {
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
		this.editor.session.setValue(this.vfs.readString("live.hx"));
		this.editor.session.selection.moveCursorFileEnd();
		this.editor.session.selection.on("changeCursor",function(e) {
			_g.updateAutocompletion();
			return null;
		});
		this.editor.session.on("change",function(e1) {
			_g.queueUpdateContentLive();
			_g.updateAutocompletion();
			return null;
		});
		this.updateContentLive();
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
			_g.updateContentLive();
		},100);
	}
	,updateContentLive: function() {
		this.vfs.set("live.hx",this.editor.session.getValue());
		this.setProgram();
		this.updateLive();
	}
	,getCursorIndex: function() {
		var cursor = this.editor.session.selection.getCursor();
		return this.editor.session.doc.positionToIndex(cursor,0);
	}
	,updateAutocompletion: function() {
		var cursor = this.editor.session.selection.getCursor();
		var index = this.editor.session.doc.positionToIndex(cursor,0);
		var size = this.editor.renderer.textToScreenCoordinates(cursor.row,cursor.column);
		var document = window.document;
		var autocompletionElement = document.getElementById("autocompletion");
		autocompletionElement.style.visibility = "hidden";
		autocompletionElement.style.top = size.pageY + document.body.scrollTop + "px";
		autocompletionElement.style.left = size.pageX + "px";
		autocompletionElement.innerHTML = "";
		var show = false;
		try {
			var items = this.services.getCompletionAt("live.hx",this.getCursorIndex());
			var _g = 0;
			var _g1 = items.items;
			while(_g < _g1.length) {
				var item = _g1[_g];
				++_g;
				var divitem = document.createElement("div");
				divitem.innerText = item.name;
				autocompletionElement.appendChild(divitem);
				show = true;
			}
			haxe.Log.trace("Autocompletion:" + Std.string(items),{ fileName : "MainIde.hx", lineNumber : 123, className : "MainIde", methodName : "updateAutocompletion"});
		} catch( e ) {
			haxe.Log.trace(e,{ fileName : "MainIde.hx", lineNumber : 125, className : "MainIde", methodName : "updateAutocompletion"});
		}
		if(show) {
		}
	}
	,updateLive: function() {
		var _g = this;
		var annotations = new Array();
		var addError = function(e) {
			haxe.Log.trace(e,{ fileName : "MainIde.hx", lineNumber : 136, className : "MainIde", methodName : "updateLive"});
			var pos1 = _g.editor.session.doc.indexToPosition(e.pmin,0);
			annotations.push({ row : pos1.row, column : pos1.column, text : e.toString(), type : "error"});
		};
		try {
			this.services.updateHaxeFile("live.hx");
			var _g1 = 0;
			var _g11 = this.services.getErrors("live.hx").errors;
			while(_g1 < _g11.length) {
				var error = _g11[_g1];
				++_g1;
				addError(error);
			}
		} catch( $e0 ) {
			if( js.Boot.__instanceof($e0,haxe.languageservices.parser.Error) ) {
				var e1 = $e0;
				addError(e1);
			} else {
			var e2 = $e0;
			haxe.Log.trace(e2,{ fileName : "MainIde.hx", lineNumber : 154, className : "MainIde", methodName : "updateLive"});
			}
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
haxe.io = {};
haxe.io.Bytes = function(length,b) {
	this.length = length;
	this.b = b;
};
$hxClasses["haxe.io.Bytes"] = haxe.io.Bytes;
haxe.io.Bytes.__name__ = ["haxe","io","Bytes"];
haxe.io.Bytes.alloc = function(length) {
	var a = new Array();
	var _g = 0;
	while(_g < length) {
		var i = _g++;
		a.push(0);
	}
	return new haxe.io.Bytes(length,a);
};
haxe.io.Bytes.ofString = function(s) {
	var a = new Array();
	var i = 0;
	while(i < s.length) {
		var c = StringTools.fastCodeAt(s,i++);
		if(55296 <= c && c <= 56319) c = c - 55232 << 10 | StringTools.fastCodeAt(s,i++) & 1023;
		if(c <= 127) a.push(c); else if(c <= 2047) {
			a.push(192 | c >> 6);
			a.push(128 | c & 63);
		} else if(c <= 65535) {
			a.push(224 | c >> 12);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		} else {
			a.push(240 | c >> 18);
			a.push(128 | c >> 12 & 63);
			a.push(128 | c >> 6 & 63);
			a.push(128 | c & 63);
		}
	}
	return new haxe.io.Bytes(a.length,a);
};
haxe.io.Bytes.ofData = function(b) {
	return new haxe.io.Bytes(b.length,b);
};
haxe.io.Bytes.fastGet = function(b,pos) {
	return b[pos];
};
haxe.io.Bytes.prototype = {
	length: null
	,b: null
	,get: function(pos) {
		return this.b[pos];
	}
	,set: function(pos,v) {
		this.b[pos] = v & 255;
	}
	,blit: function(pos,src,srcpos,len) {
		if(pos < 0 || srcpos < 0 || len < 0 || pos + len > this.length || srcpos + len > src.length) throw haxe.io.Error.OutsideBounds;
		var b1 = this.b;
		var b2 = src.b;
		if(b1 == b2 && pos > srcpos) {
			var i = len;
			while(i > 0) {
				i--;
				b1[i + pos] = b2[i + srcpos];
			}
			return;
		}
		var _g = 0;
		while(_g < len) {
			var i1 = _g++;
			b1[i1 + pos] = b2[i1 + srcpos];
		}
	}
	,fill: function(pos,len,value) {
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			this.set(pos++,value);
		}
	}
	,sub: function(pos,len) {
		if(pos < 0 || len < 0 || pos + len > this.length) throw haxe.io.Error.OutsideBounds;
		return new haxe.io.Bytes(len,this.b.slice(pos,pos + len));
	}
	,compare: function(other) {
		var b1 = this.b;
		var b2 = other.b;
		var len;
		if(this.length < other.length) len = this.length; else len = other.length;
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			if(b1[i] != b2[i]) return b1[i] - b2[i];
		}
		return this.length - other.length;
	}
	,getDouble: function(pos) {
		var b = new haxe.io.BytesInput(this,pos,8);
		return b.readDouble();
	}
	,getFloat: function(pos) {
		var b = new haxe.io.BytesInput(this,pos,4);
		return b.readFloat();
	}
	,setDouble: function(pos,v) {
		throw "Not supported";
	}
	,setFloat: function(pos,v) {
		throw "Not supported";
	}
	,getString: function(pos,len) {
		if(pos < 0 || len < 0 || pos + len > this.length) throw haxe.io.Error.OutsideBounds;
		var s = "";
		var b = this.b;
		var fcc = String.fromCharCode;
		var i = pos;
		var max = pos + len;
		while(i < max) {
			var c = b[i++];
			if(c < 128) {
				if(c == 0) break;
				s += fcc(c);
			} else if(c < 224) s += fcc((c & 63) << 6 | b[i++] & 127); else if(c < 240) {
				var c2 = b[i++];
				s += fcc((c & 31) << 12 | (c2 & 127) << 6 | b[i++] & 127);
			} else {
				var c21 = b[i++];
				var c3 = b[i++];
				var u = (c & 15) << 18 | (c21 & 127) << 12 | (c3 & 127) << 6 | b[i++] & 127;
				s += fcc((u >> 10) + 55232);
				s += fcc(u & 1023 | 56320);
			}
		}
		return s;
	}
	,readString: function(pos,len) {
		return this.getString(pos,len);
	}
	,toString: function() {
		return this.getString(0,this.length);
	}
	,toHex: function() {
		var s = new StringBuf();
		var chars = [];
		var str = "0123456789abcdef";
		var _g1 = 0;
		var _g = str.length;
		while(_g1 < _g) {
			var i = _g1++;
			chars.push(HxOverrides.cca(str,i));
		}
		var _g11 = 0;
		var _g2 = this.length;
		while(_g11 < _g2) {
			var i1 = _g11++;
			var c = this.b[i1];
			s.b += String.fromCharCode(chars[c >> 4]);
			s.b += String.fromCharCode(chars[c & 15]);
		}
		return s.b;
	}
	,getData: function() {
		return this.b;
	}
	,__class__: haxe.io.Bytes
};
haxe.io.BytesBuffer = function() {
	this.b = new Array();
};
$hxClasses["haxe.io.BytesBuffer"] = haxe.io.BytesBuffer;
haxe.io.BytesBuffer.__name__ = ["haxe","io","BytesBuffer"];
haxe.io.BytesBuffer.prototype = {
	b: null
	,get_length: function() {
		return this.b.length;
	}
	,addByte: function($byte) {
		this.b.push($byte);
	}
	,add: function(src) {
		var b1 = this.b;
		var b2 = src.b;
		var _g1 = 0;
		var _g = src.length;
		while(_g1 < _g) {
			var i = _g1++;
			this.b.push(b2[i]);
		}
	}
	,addString: function(v) {
		this.add(haxe.io.Bytes.ofString(v));
	}
	,addFloat: function(v) {
		var b = new haxe.io.BytesOutput();
		b.writeFloat(v);
		this.add(b.getBytes());
	}
	,addDouble: function(v) {
		var b = new haxe.io.BytesOutput();
		b.writeDouble(v);
		this.add(b.getBytes());
	}
	,addBytes: function(src,pos,len) {
		if(pos < 0 || len < 0 || pos + len > src.length) throw haxe.io.Error.OutsideBounds;
		var b1 = this.b;
		var b2 = src.b;
		var _g1 = pos;
		var _g = pos + len;
		while(_g1 < _g) {
			var i = _g1++;
			this.b.push(b2[i]);
		}
	}
	,getBytes: function() {
		var bytes = new haxe.io.Bytes(this.b.length,this.b);
		this.b = null;
		return bytes;
	}
	,__class__: haxe.io.BytesBuffer
	,__properties__: {get_length:"get_length"}
};
haxe.io.Input = function() { };
$hxClasses["haxe.io.Input"] = haxe.io.Input;
haxe.io.Input.__name__ = ["haxe","io","Input"];
haxe.io.Input.prototype = {
	bigEndian: null
	,readByte: function() {
		throw "Not implemented";
	}
	,readBytes: function(s,pos,len) {
		var k = len;
		var b = s.b;
		if(pos < 0 || len < 0 || pos + len > s.length) throw haxe.io.Error.OutsideBounds;
		while(k > 0) {
			b[pos] = this.readByte();
			pos++;
			k--;
		}
		return len;
	}
	,close: function() {
	}
	,set_bigEndian: function(b) {
		this.bigEndian = b;
		return b;
	}
	,readAll: function(bufsize) {
		if(bufsize == null) bufsize = 16384;
		var buf = haxe.io.Bytes.alloc(bufsize);
		var total = new haxe.io.BytesBuffer();
		try {
			while(true) {
				var len = this.readBytes(buf,0,bufsize);
				if(len == 0) throw haxe.io.Error.Blocked;
				total.addBytes(buf,0,len);
			}
		} catch( e ) {
			if( js.Boot.__instanceof(e,haxe.io.Eof) ) {
			} else throw(e);
		}
		return total.getBytes();
	}
	,readFullBytes: function(s,pos,len) {
		while(len > 0) {
			var k = this.readBytes(s,pos,len);
			pos += k;
			len -= k;
		}
	}
	,read: function(nbytes) {
		var s = haxe.io.Bytes.alloc(nbytes);
		var p = 0;
		while(nbytes > 0) {
			var k = this.readBytes(s,p,nbytes);
			if(k == 0) throw haxe.io.Error.Blocked;
			p += k;
			nbytes -= k;
		}
		return s;
	}
	,readUntil: function(end) {
		var buf = new StringBuf();
		var last;
		while((last = this.readByte()) != end) buf.b += String.fromCharCode(last);
		return buf.b;
	}
	,readLine: function() {
		var buf = new StringBuf();
		var last;
		var s;
		try {
			while((last = this.readByte()) != 10) buf.b += String.fromCharCode(last);
			s = buf.b;
			if(HxOverrides.cca(s,s.length - 1) == 13) s = HxOverrides.substr(s,0,-1);
		} catch( e ) {
			if( js.Boot.__instanceof(e,haxe.io.Eof) ) {
				s = buf.b;
				if(s.length == 0) throw e;
			} else throw(e);
		}
		return s;
	}
	,readFloat: function() {
		var bytes = [];
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		if(!this.bigEndian) bytes.reverse();
		var sign = 1 - (bytes[0] >> 7 << 1);
		var exp = (bytes[0] << 1 & 255 | bytes[1] >> 7) - 127;
		var sig = (bytes[1] & 127) << 16 | bytes[2] << 8 | bytes[3];
		if(sig == 0 && exp == -127) return 0.0;
		return sign * (1 + Math.pow(2,-23) * sig) * Math.pow(2,exp);
	}
	,readDouble: function() {
		var bytes = [];
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		bytes.push(this.readByte());
		if(!this.bigEndian) bytes.reverse();
		var sign = 1 - (bytes[0] >> 7 << 1);
		var exp = (bytes[0] << 4 & 2047 | bytes[1] >> 4) - 1023;
		var sig = this.getDoubleSig(bytes);
		if(sig == 0 && exp == -1023) return 0.0;
		return sign * (1.0 + Math.pow(2,-52) * sig) * Math.pow(2,exp);
	}
	,readInt8: function() {
		var n = this.readByte();
		if(n >= 128) return n - 256;
		return n;
	}
	,readInt16: function() {
		var ch1 = this.readByte();
		var ch2 = this.readByte();
		var n;
		if(this.bigEndian) n = ch2 | ch1 << 8; else n = ch1 | ch2 << 8;
		if((n & 32768) != 0) return n - 65536;
		return n;
	}
	,readUInt16: function() {
		var ch1 = this.readByte();
		var ch2 = this.readByte();
		if(this.bigEndian) return ch2 | ch1 << 8; else return ch1 | ch2 << 8;
	}
	,readInt24: function() {
		var ch1 = this.readByte();
		var ch2 = this.readByte();
		var ch3 = this.readByte();
		var n;
		if(this.bigEndian) n = ch3 | ch2 << 8 | ch1 << 16; else n = ch1 | ch2 << 8 | ch3 << 16;
		if((n & 8388608) != 0) return n - 16777216;
		return n;
	}
	,readUInt24: function() {
		var ch1 = this.readByte();
		var ch2 = this.readByte();
		var ch3 = this.readByte();
		if(this.bigEndian) return ch3 | ch2 << 8 | ch1 << 16; else return ch1 | ch2 << 8 | ch3 << 16;
	}
	,readInt32: function() {
		var ch1 = this.readByte();
		var ch2 = this.readByte();
		var ch3 = this.readByte();
		var ch4 = this.readByte();
		if(this.bigEndian) return ch4 | ch3 << 8 | ch2 << 16 | ch1 << 24; else return ch1 | ch2 << 8 | ch3 << 16 | ch4 << 24;
	}
	,readString: function(len) {
		var b = haxe.io.Bytes.alloc(len);
		this.readFullBytes(b,0,len);
		return b.toString();
	}
	,getDoubleSig: function(bytes) {
		return ((bytes[1] & 15) << 16 | bytes[2] << 8 | bytes[3]) * 4294967296. + (bytes[4] >> 7) * 2147483648 + ((bytes[4] & 127) << 24 | bytes[5] << 16 | bytes[6] << 8 | bytes[7]);
	}
	,__class__: haxe.io.Input
	,__properties__: {set_bigEndian:"set_bigEndian"}
};
haxe.io.BytesInput = function(b,pos,len) {
	if(pos == null) pos = 0;
	if(len == null) len = b.length - pos;
	if(pos < 0 || len < 0 || pos + len > b.length) throw haxe.io.Error.OutsideBounds;
	this.b = b.b;
	this.pos = pos;
	this.len = len;
	this.totlen = len;
};
$hxClasses["haxe.io.BytesInput"] = haxe.io.BytesInput;
haxe.io.BytesInput.__name__ = ["haxe","io","BytesInput"];
haxe.io.BytesInput.__super__ = haxe.io.Input;
haxe.io.BytesInput.prototype = $extend(haxe.io.Input.prototype,{
	b: null
	,pos: null
	,len: null
	,totlen: null
	,get_position: function() {
		return this.pos;
	}
	,get_length: function() {
		return this.totlen;
	}
	,set_position: function(p) {
		if(p < 0) p = 0; else if(p > this.totlen) p = this.totlen;
		this.len = this.totlen - p;
		return this.pos = p;
	}
	,readByte: function() {
		if(this.len == 0) throw new haxe.io.Eof();
		this.len--;
		return this.b[this.pos++];
	}
	,readBytes: function(buf,pos,len) {
		if(pos < 0 || len < 0 || pos + len > buf.length) throw haxe.io.Error.OutsideBounds;
		if(this.len == 0 && len > 0) throw new haxe.io.Eof();
		if(this.len < len) len = this.len;
		var b1 = this.b;
		var b2 = buf.b;
		var _g = 0;
		while(_g < len) {
			var i = _g++;
			b2[pos + i] = b1[this.pos + i];
		}
		this.pos += len;
		this.len -= len;
		return len;
	}
	,__class__: haxe.io.BytesInput
	,__properties__: $extend(haxe.io.Input.prototype.__properties__,{get_length:"get_length",set_position:"set_position",get_position:"get_position"})
});
haxe.io.Output = function() { };
$hxClasses["haxe.io.Output"] = haxe.io.Output;
haxe.io.Output.__name__ = ["haxe","io","Output"];
haxe.io.Output.prototype = {
	bigEndian: null
	,writeByte: function(c) {
		throw "Not implemented";
	}
	,writeBytes: function(s,pos,len) {
		var k = len;
		var b = s.b;
		if(pos < 0 || len < 0 || pos + len > s.length) throw haxe.io.Error.OutsideBounds;
		while(k > 0) {
			this.writeByte(b[pos]);
			pos++;
			k--;
		}
		return len;
	}
	,flush: function() {
	}
	,close: function() {
	}
	,set_bigEndian: function(b) {
		this.bigEndian = b;
		return b;
	}
	,write: function(s) {
		var l = s.length;
		var p = 0;
		while(l > 0) {
			var k = this.writeBytes(s,p,l);
			if(k == 0) throw haxe.io.Error.Blocked;
			p += k;
			l -= k;
		}
	}
	,writeFullBytes: function(s,pos,len) {
		while(len > 0) {
			var k = this.writeBytes(s,pos,len);
			pos += k;
			len -= k;
		}
	}
	,writeFloat: function(x) {
		if(x == 0.0) {
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			return;
		}
		var exp = Math.floor(Math.log(Math.abs(x)) / haxe.io.Output.LN2);
		var sig = Math.floor(Math.abs(x) / Math.pow(2,exp) * 8388608) & 8388607;
		var b4;
		b4 = exp + 127 >> 1 | (exp > 0?x < 0?128:64:x < 0?128:0);
		var b3 = exp + 127 << 7 & 255 | sig >> 16 & 127;
		var b2 = sig >> 8 & 255;
		var b1 = sig & 255;
		if(this.bigEndian) {
			this.writeByte(b4);
			this.writeByte(b3);
			this.writeByte(b2);
			this.writeByte(b1);
		} else {
			this.writeByte(b1);
			this.writeByte(b2);
			this.writeByte(b3);
			this.writeByte(b4);
		}
	}
	,writeDouble: function(x) {
		if(x == 0.0) {
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			this.writeByte(0);
			return;
		}
		var exp = Math.floor(Math.log(Math.abs(x)) / haxe.io.Output.LN2);
		var sig = Math.floor(Math.abs(x) / Math.pow(2,exp) * Math.pow(2,52));
		var sig_h = sig & 34359738367;
		var sig_l = Math.floor(sig / Math.pow(2,32));
		var b8;
		b8 = exp + 1023 >> 4 | (exp > 0?x < 0?128:64:x < 0?128:0);
		var b7 = exp + 1023 << 4 & 255 | sig_l >> 16 & 15;
		var b6 = sig_l >> 8 & 255;
		var b5 = sig_l & 255;
		var b4 = sig_h >> 24 & 255;
		var b3 = sig_h >> 16 & 255;
		var b2 = sig_h >> 8 & 255;
		var b1 = sig_h & 255;
		if(this.bigEndian) {
			this.writeByte(b8);
			this.writeByte(b7);
			this.writeByte(b6);
			this.writeByte(b5);
			this.writeByte(b4);
			this.writeByte(b3);
			this.writeByte(b2);
			this.writeByte(b1);
		} else {
			this.writeByte(b1);
			this.writeByte(b2);
			this.writeByte(b3);
			this.writeByte(b4);
			this.writeByte(b5);
			this.writeByte(b6);
			this.writeByte(b7);
			this.writeByte(b8);
		}
	}
	,writeInt8: function(x) {
		if(x < -128 || x >= 128) throw haxe.io.Error.Overflow;
		this.writeByte(x & 255);
	}
	,writeInt16: function(x) {
		if(x < -32768 || x >= 32768) throw haxe.io.Error.Overflow;
		this.writeUInt16(x & 65535);
	}
	,writeUInt16: function(x) {
		if(x < 0 || x >= 65536) throw haxe.io.Error.Overflow;
		if(this.bigEndian) {
			this.writeByte(x >> 8);
			this.writeByte(x & 255);
		} else {
			this.writeByte(x & 255);
			this.writeByte(x >> 8);
		}
	}
	,writeInt24: function(x) {
		if(x < -8388608 || x >= 8388608) throw haxe.io.Error.Overflow;
		this.writeUInt24(x & 16777215);
	}
	,writeUInt24: function(x) {
		if(x < 0 || x >= 16777216) throw haxe.io.Error.Overflow;
		if(this.bigEndian) {
			this.writeByte(x >> 16);
			this.writeByte(x >> 8 & 255);
			this.writeByte(x & 255);
		} else {
			this.writeByte(x & 255);
			this.writeByte(x >> 8 & 255);
			this.writeByte(x >> 16);
		}
	}
	,writeInt32: function(x) {
		if(this.bigEndian) {
			this.writeByte(x >>> 24);
			this.writeByte(x >> 16 & 255);
			this.writeByte(x >> 8 & 255);
			this.writeByte(x & 255);
		} else {
			this.writeByte(x & 255);
			this.writeByte(x >> 8 & 255);
			this.writeByte(x >> 16 & 255);
			this.writeByte(x >>> 24);
		}
	}
	,prepare: function(nbytes) {
	}
	,writeInput: function(i,bufsize) {
		if(bufsize == null) bufsize = 4096;
		var buf = haxe.io.Bytes.alloc(bufsize);
		try {
			while(true) {
				var len = i.readBytes(buf,0,bufsize);
				if(len == 0) throw haxe.io.Error.Blocked;
				var p = 0;
				while(len > 0) {
					var k = this.writeBytes(buf,p,len);
					if(k == 0) throw haxe.io.Error.Blocked;
					p += k;
					len -= k;
				}
			}
		} catch( e ) {
			if( js.Boot.__instanceof(e,haxe.io.Eof) ) {
			} else throw(e);
		}
	}
	,writeString: function(s) {
		var b = haxe.io.Bytes.ofString(s);
		this.writeFullBytes(b,0,b.length);
	}
	,__class__: haxe.io.Output
	,__properties__: {set_bigEndian:"set_bigEndian"}
};
haxe.io.BytesOutput = function() {
	this.b = new haxe.io.BytesBuffer();
};
$hxClasses["haxe.io.BytesOutput"] = haxe.io.BytesOutput;
haxe.io.BytesOutput.__name__ = ["haxe","io","BytesOutput"];
haxe.io.BytesOutput.__super__ = haxe.io.Output;
haxe.io.BytesOutput.prototype = $extend(haxe.io.Output.prototype,{
	b: null
	,get_length: function() {
		return this.b.b.length;
	}
	,writeByte: function(c) {
		this.b.b.push(c);
	}
	,writeBytes: function(buf,pos,len) {
		this.b.addBytes(buf,pos,len);
		return len;
	}
	,getBytes: function() {
		return this.b.getBytes();
	}
	,__class__: haxe.io.BytesOutput
	,__properties__: $extend(haxe.io.Output.prototype.__properties__,{get_length:"get_length"})
});
haxe.io.Eof = function() {
};
$hxClasses["haxe.io.Eof"] = haxe.io.Eof;
haxe.io.Eof.__name__ = ["haxe","io","Eof"];
haxe.io.Eof.prototype = {
	toString: function() {
		return "Eof";
	}
	,__class__: haxe.io.Eof
};
haxe.io.Error = $hxClasses["haxe.io.Error"] = { __ename__ : ["haxe","io","Error"], __constructs__ : ["Blocked","Overflow","OutsideBounds","Custom"] };
haxe.io.Error.Blocked = ["Blocked",0];
haxe.io.Error.Blocked.toString = $estr;
haxe.io.Error.Blocked.__enum__ = haxe.io.Error;
haxe.io.Error.Overflow = ["Overflow",1];
haxe.io.Error.Overflow.toString = $estr;
haxe.io.Error.Overflow.__enum__ = haxe.io.Error;
haxe.io.Error.OutsideBounds = ["OutsideBounds",2];
haxe.io.Error.OutsideBounds.toString = $estr;
haxe.io.Error.OutsideBounds.__enum__ = haxe.io.Error;
haxe.io.Error.Custom = function(e) { var $x = ["Custom",3,e]; $x.__enum__ = haxe.io.Error; $x.toString = $estr; return $x; };
haxe.io.Error.__empty_constructs__ = [haxe.io.Error.Blocked,haxe.io.Error.Overflow,haxe.io.Error.OutsideBounds];
haxe.io.StringInput = function(s) {
	haxe.io.BytesInput.call(this,haxe.io.Bytes.ofString(s));
};
$hxClasses["haxe.io.StringInput"] = haxe.io.StringInput;
haxe.io.StringInput.__name__ = ["haxe","io","StringInput"];
haxe.io.StringInput.__super__ = haxe.io.BytesInput;
haxe.io.StringInput.prototype = $extend(haxe.io.BytesInput.prototype,{
	__class__: haxe.io.StringInput
});
haxe.languageservices = {};
haxe.languageservices.HaxeLanguageServices = function(vfs) {
	this.classPaths = ["."];
	this.parsers = new haxe.ds.StringMap();
	this.typeContext = new haxe.languageservices.parser.TypeContext();
	this.vfs = vfs;
};
$hxClasses["haxe.languageservices.HaxeLanguageServices"] = haxe.languageservices.HaxeLanguageServices;
haxe.languageservices.HaxeLanguageServices.__name__ = ["haxe","languageservices","HaxeLanguageServices"];
haxe.languageservices.HaxeLanguageServices.prototype = {
	vfs: null
	,typeContext: null
	,parsers: null
	,classPaths: null
	,updateHaxeScriptFile: function(path) {
		var parser;
		var v = new haxe.languageservices.parser.Parser(this.typeContext);
		this.parsers.set(path,v);
		parser = v;
		var fileContent = this.vfs.readString(path);
		parser.setInputString(fileContent);
		var expr = parser.parseExpressions();
	}
	,updateHaxeFile: function(path) {
		var parser;
		var v = new haxe.languageservices.parser.Parser(this.typeContext);
		this.parsers.set(path,v);
		parser = v;
		var fileContent = this.vfs.readString(path);
		parser.setInputString(fileContent);
		var expr = parser.parseHaxeFile();
	}
	,getCompletionAt: function(path,offset) {
		var parser = this.parsers.get(path);
		if(parser == null) throw "Can't find parser for file " + path;
		return parser.completionsAt(offset);
	}
	,getCallInfoAt: function(path,offset) {
		var parser = this.parsers.get(path);
		return parser.callCompletionAt(offset);
	}
	,getErrors: function(path) {
		var parser = this.parsers.get(path);
		return parser.errors;
	}
	,__class__: haxe.languageservices.HaxeLanguageServices
};
haxe.languageservices.parser = {};
haxe.languageservices.parser.Completion = function() { };
$hxClasses["haxe.languageservices.parser.Completion"] = haxe.languageservices.parser.Completion;
haxe.languageservices.parser.Completion.__name__ = ["haxe","languageservices","parser","Completion"];
haxe.languageservices.parser.CompletionVariable = function(name,type) {
	this.references = [];
	this.name = name;
	this.type = type;
};
$hxClasses["haxe.languageservices.parser.CompletionVariable"] = haxe.languageservices.parser.CompletionVariable;
haxe.languageservices.parser.CompletionVariable.__name__ = ["haxe","languageservices","parser","CompletionVariable"];
haxe.languageservices.parser.CompletionVariable.prototype = {
	name: null
	,type: null
	,references: null
	,addReference: function(ref) {
		this.references.push(ref);
	}
	,__class__: haxe.languageservices.parser.CompletionVariable
};
haxe.languageservices.parser.Reference = $hxClasses["haxe.languageservices.parser.Reference"] = { __ename__ : ["haxe","languageservices","parser","Reference"], __constructs__ : ["Declaration","Write","Read"] };
haxe.languageservices.parser.Reference.Declaration = function(e) { var $x = ["Declaration",0,e]; $x.__enum__ = haxe.languageservices.parser.Reference; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Reference.Write = function(e) { var $x = ["Write",1,e]; $x.__enum__ = haxe.languageservices.parser.Reference; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Reference.Read = function(e) { var $x = ["Read",2,e]; $x.__enum__ = haxe.languageservices.parser.Reference; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Reference.__empty_constructs__ = [];
haxe.languageservices.parser.CompletionType = $hxClasses["haxe.languageservices.parser.CompletionType"] = { __ename__ : ["haxe","languageservices","parser","CompletionType"], __constructs__ : ["Unknown","Keyword","Dynamic","Void","Bool","Int","Float","String","TypeParam","Object","Type2","Array","Function"] };
haxe.languageservices.parser.CompletionType.Unknown = ["Unknown",0];
haxe.languageservices.parser.CompletionType.Unknown.toString = $estr;
haxe.languageservices.parser.CompletionType.Unknown.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Keyword = ["Keyword",1];
haxe.languageservices.parser.CompletionType.Keyword.toString = $estr;
haxe.languageservices.parser.CompletionType.Keyword.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Dynamic = ["Dynamic",2];
haxe.languageservices.parser.CompletionType.Dynamic.toString = $estr;
haxe.languageservices.parser.CompletionType.Dynamic.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Void = ["Void",3];
haxe.languageservices.parser.CompletionType.Void.toString = $estr;
haxe.languageservices.parser.CompletionType.Void.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Bool = ["Bool",4];
haxe.languageservices.parser.CompletionType.Bool.toString = $estr;
haxe.languageservices.parser.CompletionType.Bool.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Int = ["Int",5];
haxe.languageservices.parser.CompletionType.Int.toString = $estr;
haxe.languageservices.parser.CompletionType.Int.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Float = ["Float",6];
haxe.languageservices.parser.CompletionType.Float.toString = $estr;
haxe.languageservices.parser.CompletionType.Float.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.String = ["String",7];
haxe.languageservices.parser.CompletionType.String.toString = $estr;
haxe.languageservices.parser.CompletionType.String.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.TypeParam = ["TypeParam",8];
haxe.languageservices.parser.CompletionType.TypeParam.toString = $estr;
haxe.languageservices.parser.CompletionType.TypeParam.__enum__ = haxe.languageservices.parser.CompletionType;
haxe.languageservices.parser.CompletionType.Object = function(items) { var $x = ["Object",9,items]; $x.__enum__ = haxe.languageservices.parser.CompletionType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CompletionType.Type2 = function(fqName) { var $x = ["Type2",10,fqName]; $x.__enum__ = haxe.languageservices.parser.CompletionType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CompletionType.Array = function(type) { var $x = ["Array",11,type]; $x.__enum__ = haxe.languageservices.parser.CompletionType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CompletionType.Function = function(type,name,args,ret) { var $x = ["Function",12,type,name,args,ret]; $x.__enum__ = haxe.languageservices.parser.CompletionType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CompletionType.__empty_constructs__ = [haxe.languageservices.parser.CompletionType.Unknown,haxe.languageservices.parser.CompletionType.Keyword,haxe.languageservices.parser.CompletionType.Dynamic,haxe.languageservices.parser.CompletionType.Void,haxe.languageservices.parser.CompletionType.Bool,haxe.languageservices.parser.CompletionType.Int,haxe.languageservices.parser.CompletionType.Float,haxe.languageservices.parser.CompletionType.String,haxe.languageservices.parser.CompletionType.TypeParam];
haxe.languageservices.parser.CCompletion = $hxClasses["haxe.languageservices.parser.CCompletion"] = { __ename__ : ["haxe","languageservices","parser","CCompletion"], __constructs__ : ["CallCompletion"] };
haxe.languageservices.parser.CCompletion.CallCompletion = function(baseType,name,args,ret,argIndex,doc) { var $x = ["CallCompletion",0,baseType,name,args,ret,argIndex,doc]; $x.__enum__ = haxe.languageservices.parser.CCompletion; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CCompletion.__empty_constructs__ = [];
haxe.languageservices.parser.CompletionList = function(items) {
	this.items = items;
};
$hxClasses["haxe.languageservices.parser.CompletionList"] = haxe.languageservices.parser.CompletionList;
haxe.languageservices.parser.CompletionList.__name__ = ["haxe","languageservices","parser","CompletionList"];
haxe.languageservices.parser.CompletionList.prototype = {
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
					_g.push(completion.name + ":" + haxe.languageservices.parser.CompletionTypeUtils.toString(completion.type));
				}
			}
			$r = _g;
			return $r;
		}(this))).toString();
	}
	,__class__: haxe.languageservices.parser.CompletionList
};
haxe.languageservices.parser.Scope = function(parent) {
	this.parent = parent;
	this.map = new haxe.ds.StringMap();
};
$hxClasses["haxe.languageservices.parser.Scope"] = haxe.languageservices.parser.Scope;
haxe.languageservices.parser.Scope.__name__ = ["haxe","languageservices","parser","Scope"];
haxe.languageservices.parser.Scope.prototype = {
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
	,__class__: haxe.languageservices.parser.Scope
};
haxe.languageservices.parser.CompletionScope = function(context,parent) {
	this._completionTypeGen = null;
	this.keywords = new Array();
	this.children = [];
	this.context = context;
	this.parent = parent;
	this.scope = new haxe.languageservices.parser.Scope(parent != null?parent.scope:null);
	if(parent != null) parent.children.push(this);
};
$hxClasses["haxe.languageservices.parser.CompletionScope"] = haxe.languageservices.parser.CompletionScope;
haxe.languageservices.parser.CompletionScope.__name__ = ["haxe","languageservices","parser","CompletionScope"];
haxe.languageservices.parser.CompletionScope.prototype = {
	start: null
	,end: null
	,parent: null
	,children: null
	,context: null
	,scope: null
	,keywords: null
	,setBounds: function(start,end) {
		this.start = start;
		this.end = end;
		return this;
	}
	,callCompletion: null
	,setCallCompletion: function(c) {
		this.callCompletion = c;
		return this;
	}
	,_completionTypeGen: null
	,setCompletionTypeGen: function(ct) {
		this._completionTypeGen = ct;
		return this;
	}
	,createChild: function() {
		return new haxe.languageservices.parser.CompletionScope(this.context,this);
	}
	,set: function(name,v) {
		this.scope.set(name,v);
	}
	,getLocal: function(name) {
		return this.scope.get(name);
	}
	,getElementType: function(e) {
		var result = this.getType(e);
		switch(result[1]) {
		case 11:
			var type = result[2];
			return type;
		default:
		}
		return haxe.languageservices.parser.CompletionType.Unknown;
	}
	,getType: function(e) {
		{
			var _g = e.e;
			switch(_g[1]) {
			case 1:
				var v = _g[2];
				var local = this.scope.get(v);
				if(local != null) return local.type; else return haxe.languageservices.parser.CompletionType.Dynamic;
				break;
			case 0:
				switch(_g[2][1]) {
				case 0:
					return haxe.languageservices.parser.CompletionType.Int;
				case 1:
					return haxe.languageservices.parser.CompletionType.Float;
				case 2:
					return haxe.languageservices.parser.CompletionType.String;
				}
				break;
			case 5:
				var field = _g[3];
				var expr = _g[2];
				return haxe.languageservices.parser.CompletionTypeUtils.getFieldType(this.getType(expr),field);
			case 4:
				var exprs = _g[2];
				return this.getType(exprs[exprs.length - 1]);
			case 15:
				var e1 = _g[2];
				return this.getType(e1);
			case 9:
				var e2 = _g[4];
				var e11 = _g[3];
				var cond = _g[2];
				return haxe.languageservices.parser.CompletionTypeUtils.unificateTypes([this.getType(e11),this.getType(e2)]);
			case 3:
				var expr1 = _g[2];
				return this.getType(expr1);
			case 7:
				var expr2 = _g[4];
				var prefix = _g[3];
				var op = _g[2];
				var type = this.getType(expr2);
				switch(op) {
				case "-":
					switch(type[1]) {
					case 5:case 6:case 2:
						return type;
					default:
					}
					break;
				default:
				}
				throw "Unhandled unary op " + op;
				break;
			case 6:
				var right = _g[4];
				var left = _g[3];
				var op1 = _g[2];
				var ltype = this.getType(left);
				var rtype = this.getType(right);
				switch(op1) {
				case "==":
					if(ltype != rtype) this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Disctinct types"),e.pmin,e.pmax));
					return haxe.languageservices.parser.CompletionType.Bool;
				case "...":
					return haxe.languageservices.parser.CompletionType.Array(haxe.languageservices.parser.CompletionType.Int);
				case "+":
					if(js.Boot.__instanceof(ltype,haxe.languageservices.parser.CompletionType.Bool) || js.Boot.__instanceof(rtype,haxe.languageservices.parser.CompletionType.Bool)) this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Cannot add bool"),e.pmin,e.pmax));
					switch(ltype[1]) {
					case 5:
						switch(rtype[1]) {
						case 5:
							return haxe.languageservices.parser.CompletionType.Int;
						case 6:
							return haxe.languageservices.parser.CompletionType.Float;
						case 7:
							return haxe.languageservices.parser.CompletionType.String;
						case 2:
							return haxe.languageservices.parser.CompletionType.Dynamic;
						default:
							this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Unsupported op2 " + Std.string(ltype) + " " + op1 + " " + Std.string(rtype)),e.pmin,e.pmax));
							return haxe.languageservices.parser.CompletionType.Dynamic;
						}
						break;
					case 6:
						switch(rtype[1]) {
						case 5:
							return haxe.languageservices.parser.CompletionType.Float;
						case 6:
							return haxe.languageservices.parser.CompletionType.Float;
						case 7:
							return haxe.languageservices.parser.CompletionType.String;
						case 2:
							return haxe.languageservices.parser.CompletionType.Dynamic;
						default:
							this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Unsupported op2 " + Std.string(ltype) + " " + op1 + " " + Std.string(rtype)),e.pmin,e.pmax));
							return haxe.languageservices.parser.CompletionType.Dynamic;
						}
						break;
					case 7:
						switch(rtype[1]) {
						case 5:
							return haxe.languageservices.parser.CompletionType.String;
						case 6:
							return haxe.languageservices.parser.CompletionType.String;
						case 7:
							return haxe.languageservices.parser.CompletionType.String;
						case 2:
							return haxe.languageservices.parser.CompletionType.Dynamic;
						default:
							this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Unsupported op2 " + Std.string(ltype) + " " + op1 + " " + Std.string(rtype)),e.pmin,e.pmax));
							return haxe.languageservices.parser.CompletionType.Dynamic;
						}
						break;
					case 2:
						switch(rtype[1]) {
						case 2:
							return haxe.languageservices.parser.CompletionType.Dynamic;
						default:
							return haxe.languageservices.parser.CompletionType.Dynamic;
						}
						break;
					default:
						switch(rtype[1]) {
						case 2:
							return haxe.languageservices.parser.CompletionType.Dynamic;
						default:
							this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Unsupported op2 " + Std.string(ltype) + " " + op1 + " " + Std.string(rtype)),e.pmin,e.pmax));
							return haxe.languageservices.parser.CompletionType.Dynamic;
						}
					}
					ltype;
					break;
				default:
					throw "Unsupported operator " + op1;
				}
				throw "Unsupported type with " + op1;
				return ltype;
			case 14:
				var ret = _g[5];
				var name = _g[4];
				var e3 = _g[3];
				var args = _g[2];
				var rtype1;
				{
					var _g1 = e3.e;
					switch(_g1[1]) {
					case 21:
						var fl = _g1[2];
						if(fl.length == 0) rtype1 = haxe.languageservices.parser.CompletionType.Void; else rtype1 = this.getType(e3);
						break;
					default:
						rtype1 = this.getType(e3);
					}
				}
				var f = haxe.languageservices.parser.CompletionType.Function("<anonymous>",name,(function($this) {
					var $r;
					var _g11 = [];
					{
						var _g2 = 0;
						while(_g2 < args.length) {
							var arg = args[_g2];
							++_g2;
							_g11.push({ name : arg.name, type : haxe.languageservices.parser.CompletionTypeUtils.fromCType(arg.t), optional : arg.opt});
						}
					}
					$r = _g11;
					return $r;
				}(this)),rtype1);
				return f;
			case 8:
				var params = _g[3];
				var e4 = _g[2];
				{
					var _g12 = this.getType(e4);
					switch(_g12[1]) {
					case 12:
						var ret1 = _g12[5];
						var args1 = _g12[4];
						var name1 = _g12[3];
						var type1 = _g12[2];
						return ret1;
					case 2:
						return haxe.languageservices.parser.CompletionType.Dynamic;
					default:
					}
				}
				return haxe.languageservices.parser.CompletionType.Unknown;
			case 17:
				var exprs1 = _g[2];
				return haxe.languageservices.parser.CompletionType.Array(haxe.languageservices.parser.CompletionTypeUtils.unificateTypes((function($this) {
					var $r;
					var _g13 = [];
					{
						var _g21 = 0;
						while(_g21 < exprs1.length) {
							var expr3 = exprs1[_g21];
							++_g21;
							_g13.push($this.getType(expr3));
						}
					}
					$r = _g13;
					return $r;
				}(this))));
			case 21:
				var parts = _g[2];
				return haxe.languageservices.parser.CompletionType.Object((function($this) {
					var $r;
					var _g14 = [];
					{
						var _g22 = 0;
						while(_g22 < parts.length) {
							var part = parts[_g22];
							++_g22;
							_g14.push({ name : part.name, type : $this.getType(part.e)});
						}
					}
					$r = _g14;
					return $r;
				}(this)));
			case 2:
				var e5 = _g[4];
				var t = _g[3];
				var n = _g[2];
				return haxe.languageservices.parser.CompletionTypeUtils.fromCType(t);
			default:
				throw "Unhandled expression " + Std.string(e.e);
			}
		}
		haxe.Log.trace(e,{ fileName : "Completion.hx", lineNumber : 280, className : "haxe.languageservices.parser.CompletionScope", methodName : "getType"});
		return haxe.languageservices.parser.CompletionType.Unknown;
	}
	,containsIndex: function(index) {
		return index >= this.start && index <= this.end;
	}
	,addKeyword: function(name) {
		haxe.languageservices.util.ArrayUtils.pushOnce(this.keywords,name);
	}
	,addLocal: function(ident,t,e,type,exprScope) {
		if(exprScope == null) exprScope = this;
		if(type == null) {
			if(e != null) try {
				type = exprScope.getType(e);
			} catch( e1 ) {
				this.context.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknown("Error:" + Std.string(e1)),e1.pmin,e1.pmax));
				type = haxe.languageservices.parser.CompletionType.Unknown;
			} else type = haxe.languageservices.parser.CompletionTypeUtils.fromCType(t);
		}
		var v = new haxe.languageservices.parser.CompletionVariable(ident,type);
		if(e != null) v.addReference(haxe.languageservices.parser.Reference.Declaration(e));
		this.set(ident,v);
		return v;
	}
	,locateIndex: function(index) {
		var _g = 0;
		var _g1 = this.children;
		while(_g < _g1.length) {
			var child = _g1[_g];
			++_g;
			if(child.containsIndex(index)) return child.locateIndex(index);
		}
		return this;
	}
	,getCompletionType: function() {
		if(this._completionTypeGen != null) return haxe.languageservices.parser.CompletionTypeUtils.toObject(this.context.typeContext,this._completionTypeGen());
		var keys = haxe.languageservices.util.ArrayUtils.sorted(this.scope.keys());
		var locals;
		var _g = [];
		var _g1 = 0;
		while(_g1 < keys.length) {
			var key = keys[_g1];
			++_g1;
			_g.push({ name : key, type : this.getLocal(key).type});
		}
		locals = _g;
		var keywords;
		var _g11 = [];
		var _g2 = 0;
		var _g3 = this.keywords;
		while(_g2 < _g3.length) {
			var key1 = _g3[_g2];
			++_g2;
			_g11.push({ name : key1, type : haxe.languageservices.parser.CompletionType.Keyword});
		}
		keywords = _g11;
		return haxe.languageservices.parser.CompletionType.Object(locals.concat(keywords));
	}
	,__class__: haxe.languageservices.parser.CompletionScope
};
haxe.languageservices.parser.CompletionContext = function(tokenizer,errors,typeContext) {
	this.tokenizer = tokenizer;
	this.errors = errors;
	this.typeContext = typeContext;
	this.scope = this.root = new haxe.languageservices.parser.CompletionScope(this);
	this.scope.set("true",new haxe.languageservices.parser.CompletionVariable("true",haxe.languageservices.parser.CompletionType.Bool));
	this.scope.set("false",new haxe.languageservices.parser.CompletionVariable("false",haxe.languageservices.parser.CompletionType.Bool));
	this.scope.set("null",new haxe.languageservices.parser.CompletionVariable("null",haxe.languageservices.parser.CompletionType.Dynamic));
};
$hxClasses["haxe.languageservices.parser.CompletionContext"] = haxe.languageservices.parser.CompletionContext;
haxe.languageservices.parser.CompletionContext.__name__ = ["haxe","languageservices","parser","CompletionContext"];
haxe.languageservices.parser.CompletionContext.prototype = {
	root: null
	,scope: null
	,tokenizer: null
	,errors: null
	,typeContext: null
	,pushScope: function(callback) {
		var old = this.scope;
		var output = this.scope = this.scope.createChild();
		this.scope.start = this.tokenizer.tokenMax;
		callback(this.scope);
		this.scope.end = this.tokenizer.tokenMin;
		this.scope = old;
		return output;
	}
	,__class__: haxe.languageservices.parser.CompletionContext
};
haxe.languageservices.parser.CompletionTypeUtils = function() { };
$hxClasses["haxe.languageservices.parser.CompletionTypeUtils"] = haxe.languageservices.parser.CompletionTypeUtils;
haxe.languageservices.parser.CompletionTypeUtils.__name__ = ["haxe","languageservices","parser","CompletionTypeUtils"];
haxe.languageservices.parser.CompletionTypeUtils.hasField = function(typeContext,type,field) {
	switch(type[1]) {
	case 2:
		return true;
	case 9:
		var items = type[2];
		var _g = 0;
		while(_g < items.length) {
			var item = items[_g];
			++_g;
			if(item.name == field) return true;
		}
		break;
	case 10:
		var fqName = type[2];
		var type1 = typeContext.getTypeFq(fqName);
		var _g1 = 0;
		var _g11 = type1.members;
		while(_g1 < _g11.length) {
			var member = _g11[_g1];
			++_g1;
			if(member.name == field) return true;
		}
		break;
	default:
	}
	return false;
};
haxe.languageservices.parser.CompletionTypeUtils.toObject = function(typeContext,type) {
	switch(type[1]) {
	case 9:
		var items = type[2];
		return type;
	case 10:
		var fqName = type[2];
		var type2 = typeContext.getTypeFq(fqName);
		return haxe.languageservices.parser.CompletionType.Object((function($this) {
			var $r;
			var _g = [];
			{
				var _g1 = 0;
				var _g2 = type2.members;
				while(_g1 < _g2.length) {
					var member = _g2[_g1];
					++_g1;
					_g.push({ name : member.name, type : member.type});
				}
			}
			$r = _g;
			return $r;
		}(this)));
	default:
		return haxe.languageservices.parser.CompletionType.Object([]);
	}
};
haxe.languageservices.parser.CompletionTypeUtils.canAssign = function(dst,src) {
	return Type.enumEq(dst,src);
};
haxe.languageservices.parser.CompletionTypeUtils.unificateTypes = function(types) {
	if(types.length == 0) return haxe.languageservices.parser.CompletionType.Dynamic;
	return types[0];
};
haxe.languageservices.parser.CompletionTypeUtils.getFieldType = function(type,field) {
	switch(type[1]) {
	case 2:
		return haxe.languageservices.parser.CompletionType.Dynamic;
	case 9:
		var items = type[2];
		var _g = 0;
		while(_g < items.length) {
			var item = items[_g];
			++_g;
			if(item.name == field) return item.type;
		}
		break;
	default:
	}
	return haxe.languageservices.parser.CompletionType.Unknown;
};
haxe.languageservices.parser.CompletionTypeUtils.fromCType = function(type) {
	if(type == null) return haxe.languageservices.parser.CompletionType.Dynamic;
	switch(type[1]) {
	case 1:
		var path = type[2];
		switch(type[2].length) {
		case 1:
			switch(type[2][0]) {
			case "Int":
				var params = type[3];
				if(type[3] == null) return haxe.languageservices.parser.CompletionType.Int; else switch(type[3].length) {
				default:
					return haxe.languageservices.parser.CompletionType.Type2(path.join("."));
				}
				break;
			case "Float":
				var params = type[3];
				if(type[3] == null) return haxe.languageservices.parser.CompletionType.Float; else switch(type[3].length) {
				default:
					return haxe.languageservices.parser.CompletionType.Type2(path.join("."));
				}
				break;
			case "Bool":
				var params = type[3];
				if(type[3] == null) return haxe.languageservices.parser.CompletionType.Bool; else switch(type[3].length) {
				default:
					return haxe.languageservices.parser.CompletionType.Type2(path.join("."));
				}
				break;
			case "String":
				var params = type[3];
				if(type[3] == null) return haxe.languageservices.parser.CompletionType.String; else switch(type[3].length) {
				default:
					return haxe.languageservices.parser.CompletionType.Type2(path.join("."));
				}
				break;
			default:
				var params = type[3];
				return haxe.languageservices.parser.CompletionType.Type2(path.join("."));
			}
			break;
		default:
			var params = type[3];
			return haxe.languageservices.parser.CompletionType.Type2(path.join("."));
		}
		break;
	case 5:
		return haxe.languageservices.parser.CompletionType.TypeParam;
	default:
	}
	throw "Not implemented " + Std.string(type);
	return null;
};
haxe.languageservices.parser.CompletionTypeUtils.toString = function(ct) {
	if(ct == null) return "???Null";
	switch(ct[1]) {
	case 11:
		var ct1 = ct[2];
		return "Array<" + haxe.languageservices.parser.CompletionTypeUtils.toString(ct1) + ">";
	case 4:
		return "Bool";
	case 3:
		return "Void";
	case 1:
		return "Keyword";
	case 8:
		return "TypeParam";
	case 6:
		return "Float";
	case 5:
		return "Int";
	case 7:
		return "String";
	case 10:
		var fqName = ct[2];
		return "" + fqName;
	case 2:
		return "Dynamic";
	case 9:
		var items = ct[2];
		return "{" + ((function($this) {
			var $r;
			var _g = [];
			{
				var _g1 = 0;
				while(_g1 < items.length) {
					var item = items[_g1];
					++_g1;
					_g.push(item.name + ":" + haxe.languageservices.parser.CompletionTypeUtils.toString(item.type));
				}
			}
			$r = _g;
			return $r;
		}(this))).join(",") + "}";
	case 12:
		var ret = ct[5];
		var args = ct[4];
		var name = ct[3];
		var type = ct[2];
		if(args.length == 0) return "Void -> " + haxe.languageservices.parser.CompletionTypeUtils.toString(ret);
		return ((function($this) {
			var $r;
			var _g2 = [];
			{
				var _g11 = 0;
				while(_g11 < args.length) {
					var arg = args[_g11];
					++_g11;
					_g2.push(haxe.languageservices.parser.CompletionTypeUtils.toString(arg.type));
				}
			}
			$r = _g2;
			return $r;
		}(this))).concat([haxe.languageservices.parser.CompletionTypeUtils.toString(ret)]).join(" -> ");
	default:
	}
	return "???" + Std.string(ct);
};
haxe.languageservices.parser.Errors = function() {
};
$hxClasses["haxe.languageservices.parser.Errors"] = haxe.languageservices.parser.Errors;
haxe.languageservices.parser.Errors.__name__ = ["haxe","languageservices","parser","Errors"];
haxe.languageservices.parser.Errors.prototype = {
	__class__: haxe.languageservices.parser.Errors
};
haxe.languageservices.parser.ErrorContext = function() {
	this.errors = new Array();
};
$hxClasses["haxe.languageservices.parser.ErrorContext"] = haxe.languageservices.parser.ErrorContext;
haxe.languageservices.parser.ErrorContext.__name__ = ["haxe","languageservices","parser","ErrorContext"];
haxe.languageservices.parser.ErrorContext.prototype = {
	errors: null
	,add: function(error) {
		this.errors.push(error);
	}
	,__class__: haxe.languageservices.parser.ErrorContext
};
haxe.languageservices.parser.Const = $hxClasses["haxe.languageservices.parser.Const"] = { __ename__ : ["haxe","languageservices","parser","Const"], __constructs__ : ["CInt","CFloat","CString"] };
haxe.languageservices.parser.Const.CInt = function(v) { var $x = ["CInt",0,v]; $x.__enum__ = haxe.languageservices.parser.Const; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Const.CFloat = function(f) { var $x = ["CFloat",1,f]; $x.__enum__ = haxe.languageservices.parser.Const; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Const.CString = function(s) { var $x = ["CString",2,s]; $x.__enum__ = haxe.languageservices.parser.Const; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Const.__empty_constructs__ = [];
haxe.languageservices.parser.ExprDef = $hxClasses["haxe.languageservices.parser.ExprDef"] = { __ename__ : ["haxe","languageservices","parser","ExprDef"], __constructs__ : ["EConst","EIdent","EVar","EParent","EBlock","EField","EBinop","EUnop","ECall","EIf","EWhile","EFor","EBreak","EContinue","EFunction","EReturn","EArray","EArrayDecl","ENew","EThrow","ETry","EObject","ETernary","ESwitch"] };
haxe.languageservices.parser.ExprDef.EConst = function(c) { var $x = ["EConst",0,c]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EIdent = function(v) { var $x = ["EIdent",1,v]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EVar = function(n,t,e) { var $x = ["EVar",2,n,t,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EParent = function(e) { var $x = ["EParent",3,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EBlock = function(e) { var $x = ["EBlock",4,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EField = function(e,f) { var $x = ["EField",5,e,f]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EBinop = function(op,e1,e2) { var $x = ["EBinop",6,op,e1,e2]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EUnop = function(op,prefix,e) { var $x = ["EUnop",7,op,prefix,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.ECall = function(e,params) { var $x = ["ECall",8,e,params]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EIf = function(cond,e1,e2) { var $x = ["EIf",9,cond,e1,e2]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EWhile = function(cond,e) { var $x = ["EWhile",10,cond,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EFor = function(v,it,e) { var $x = ["EFor",11,v,it,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EBreak = ["EBreak",12];
haxe.languageservices.parser.ExprDef.EBreak.toString = $estr;
haxe.languageservices.parser.ExprDef.EBreak.__enum__ = haxe.languageservices.parser.ExprDef;
haxe.languageservices.parser.ExprDef.EContinue = ["EContinue",13];
haxe.languageservices.parser.ExprDef.EContinue.toString = $estr;
haxe.languageservices.parser.ExprDef.EContinue.__enum__ = haxe.languageservices.parser.ExprDef;
haxe.languageservices.parser.ExprDef.EFunction = function(args,e,name,ret) { var $x = ["EFunction",14,args,e,name,ret]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EReturn = function(e) { var $x = ["EReturn",15,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EArray = function(e,index) { var $x = ["EArray",16,e,index]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EArrayDecl = function(e) { var $x = ["EArrayDecl",17,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.ENew = function(cl,params) { var $x = ["ENew",18,cl,params]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EThrow = function(e) { var $x = ["EThrow",19,e]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.ETry = function(e,v,t,ecatch) { var $x = ["ETry",20,e,v,t,ecatch]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.EObject = function(fl) { var $x = ["EObject",21,fl]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.ETernary = function(cond,e1,e2) { var $x = ["ETernary",22,cond,e1,e2]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.ESwitch = function(e,cases,defaultExpr) { var $x = ["ESwitch",23,e,cases,defaultExpr]; $x.__enum__ = haxe.languageservices.parser.ExprDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ExprDef.__empty_constructs__ = [haxe.languageservices.parser.ExprDef.EBreak,haxe.languageservices.parser.ExprDef.EContinue];
haxe.languageservices.parser.StmDef = $hxClasses["haxe.languageservices.parser.StmDef"] = { __ename__ : ["haxe","languageservices","parser","StmDef"], __constructs__ : ["EPackage","EImport","ETypedef","EClass","EFile"] };
haxe.languageservices.parser.StmDef.EPackage = function(parts) { var $x = ["EPackage",0,parts]; $x.__enum__ = haxe.languageservices.parser.StmDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.StmDef.EImport = function(parts) { var $x = ["EImport",1,parts]; $x.__enum__ = haxe.languageservices.parser.StmDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.StmDef.ETypedef = function(packageName,name) { var $x = ["ETypedef",2,packageName,name]; $x.__enum__ = haxe.languageservices.parser.StmDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.StmDef.EClass = function(packageName,name,params) { var $x = ["EClass",3,packageName,name,params]; $x.__enum__ = haxe.languageservices.parser.StmDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.StmDef.EFile = function(chunks) { var $x = ["EFile",4,chunks]; $x.__enum__ = haxe.languageservices.parser.StmDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.StmDef.__empty_constructs__ = [];
haxe.languageservices.parser.CType = $hxClasses["haxe.languageservices.parser.CType"] = { __ename__ : ["haxe","languageservices","parser","CType"], __constructs__ : ["CTInvalid","CTPath","CTFun","CTAnon","CTParent","CTTypeParam"] };
haxe.languageservices.parser.CType.CTInvalid = ["CTInvalid",0];
haxe.languageservices.parser.CType.CTInvalid.toString = $estr;
haxe.languageservices.parser.CType.CTInvalid.__enum__ = haxe.languageservices.parser.CType;
haxe.languageservices.parser.CType.CTPath = function(path,params) { var $x = ["CTPath",1,path,params]; $x.__enum__ = haxe.languageservices.parser.CType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CType.CTFun = function(args,ret) { var $x = ["CTFun",2,args,ret]; $x.__enum__ = haxe.languageservices.parser.CType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CType.CTAnon = function(fields) { var $x = ["CTAnon",3,fields]; $x.__enum__ = haxe.languageservices.parser.CType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CType.CTParent = function(t) { var $x = ["CTParent",4,t]; $x.__enum__ = haxe.languageservices.parser.CType; $x.toString = $estr; return $x; };
haxe.languageservices.parser.CType.CTTypeParam = ["CTTypeParam",5];
haxe.languageservices.parser.CType.CTTypeParam.toString = $estr;
haxe.languageservices.parser.CType.CTTypeParam.__enum__ = haxe.languageservices.parser.CType;
haxe.languageservices.parser.CType.__empty_constructs__ = [haxe.languageservices.parser.CType.CTInvalid,haxe.languageservices.parser.CType.CTTypeParam];
haxe.languageservices.parser.Error2 = function(message) {
	this.message = message;
};
$hxClasses["haxe.languageservices.parser.Error2"] = haxe.languageservices.parser.Error2;
haxe.languageservices.parser.Error2.__name__ = ["haxe","languageservices","parser","Error2"];
haxe.languageservices.parser.Error2.prototype = {
	message: null
	,toString: function() {
		return "Error(" + this.message + ")";
	}
	,__class__: haxe.languageservices.parser.Error2
};
haxe.languageservices.parser.Error = function(e,pmin,pmax) {
	this.e = e;
	this.pmin = pmin;
	this.pmax = pmax;
};
$hxClasses["haxe.languageservices.parser.Error"] = haxe.languageservices.parser.Error;
haxe.languageservices.parser.Error.__name__ = ["haxe","languageservices","parser","Error"];
haxe.languageservices.parser.Error.prototype = {
	e: null
	,pmin: null
	,pmax: null
	,toString: function() {
		return "Error(" + Std.string(this.e) + ", " + this.pmin + ", " + this.pmax + ")";
	}
	,__class__: haxe.languageservices.parser.Error
};
haxe.languageservices.parser.ErrorDef = $hxClasses["haxe.languageservices.parser.ErrorDef"] = { __ename__ : ["haxe","languageservices","parser","ErrorDef"], __constructs__ : ["EInvalidChar","EUnexpected","EUnterminatedString","EUnterminatedComment","EUnknown","EUnknownVariable","EInvalidIterator","EInvalidOp","EInvalidAccess"] };
haxe.languageservices.parser.ErrorDef.EInvalidChar = function(c) { var $x = ["EInvalidChar",0,c]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.EUnexpected = function(s) { var $x = ["EUnexpected",1,s]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.EUnterminatedString = ["EUnterminatedString",2];
haxe.languageservices.parser.ErrorDef.EUnterminatedString.toString = $estr;
haxe.languageservices.parser.ErrorDef.EUnterminatedString.__enum__ = haxe.languageservices.parser.ErrorDef;
haxe.languageservices.parser.ErrorDef.EUnterminatedComment = ["EUnterminatedComment",3];
haxe.languageservices.parser.ErrorDef.EUnterminatedComment.toString = $estr;
haxe.languageservices.parser.ErrorDef.EUnterminatedComment.__enum__ = haxe.languageservices.parser.ErrorDef;
haxe.languageservices.parser.ErrorDef.EUnknown = function(v) { var $x = ["EUnknown",4,v]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.EUnknownVariable = function(v) { var $x = ["EUnknownVariable",5,v]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.EInvalidIterator = function(v) { var $x = ["EInvalidIterator",6,v]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.EInvalidOp = function(op) { var $x = ["EInvalidOp",7,op]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.EInvalidAccess = function(f) { var $x = ["EInvalidAccess",8,f]; $x.__enum__ = haxe.languageservices.parser.ErrorDef; $x.toString = $estr; return $x; };
haxe.languageservices.parser.ErrorDef.__empty_constructs__ = [haxe.languageservices.parser.ErrorDef.EUnterminatedString,haxe.languageservices.parser.ErrorDef.EUnterminatedComment];
haxe.languageservices.parser.Parser = function(typeContext) {
	this.afterChecks = new Array();
	this.uid = 0;
	if(typeContext == null) typeContext = new haxe.languageservices.parser.TypeContext();
	this.typeContext = typeContext;
	var priorities = [["%"],["*","/"],["+","-"],["<<",">>",">>>"],["|","&","^"],["==","!=",">","<",">=","<="],["..."],["&&"],["||"],["=","+=","-=","*=","/=","%=","<<=",">>=",">>>=","|=","&=","^="]];
	this.opPriority = new haxe.ds.StringMap();
	this.opRightAssoc = new haxe.ds.StringMap();
	this.unops = new haxe.ds.StringMap();
	var _g1 = 0;
	var _g = priorities.length;
	while(_g1 < _g) {
		var i = _g1++;
		var _g2 = 0;
		var _g3 = priorities[i];
		while(_g2 < _g3.length) {
			var x = _g3[_g2];
			++_g2;
			this.opPriority.set(x,i);
			if(i == 9) this.opRightAssoc.set(x,true);
		}
	}
	var _g4 = 0;
	var _g11 = ["!","++","--","-","~"];
	while(_g4 < _g11.length) {
		var x1 = _g11[_g4];
		++_g4;
		this.unops.set(x1,x1 == "++" || x1 == "--");
	}
};
$hxClasses["haxe.languageservices.parser.Parser"] = haxe.languageservices.parser.Parser;
haxe.languageservices.parser.Parser.__name__ = ["haxe","languageservices","parser","Parser"];
haxe.languageservices.parser.Parser.prototype = {
	opPriority: null
	,opRightAssoc: null
	,unops: null
	,uid: null
	,typeContext: null
	,tokenizer: null
	,errors: null
	,completion: null
	,parseExpressionsString: function(s,path) {
		this.setInputString(s,path);
		return this.parseExpressionsFile();
	}
	,parseHaxeFileString: function(s,path) {
		this.setInputString(s,path);
		return this.parseHaxeFile();
	}
	,parseExpressionsFile: function() {
		var result = this.parseExpressions();
		this.runAfterChecks();
		return result;
	}
	,parseHaxeFile: function() {
		var result = this.parseTopLevel();
		this.runAfterChecks();
		return result;
	}
	,isValidPackagePath: function(path) {
		var _g = 0;
		while(_g < path.length) {
			var i = path[_g];
			++_g;
			if(!haxe.languageservices.util.StringUtils.isLowerCase(i)) return false;
		}
		return true;
	}
	,parseTopLevel: function() {
		var _g = this;
		var p0 = this.tokenizer.tokenMin;
		var parts = new Array();
		var packageName = new Array();
		var imports = new Array();
		var importCount = 0;
		var typeCount = 0;
		try {
			while(true) {
				var p1 = this.tokenizer.tokenMin;
				var tk = this.token();
				switch(tk[1]) {
				case 2:
					switch(tk[2]) {
					case "package":
						if(importCount != 0 || typeCount != 0) this.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknown("Package must appear at the beggining of the file"),p1,this.tokenizer.tokenMax));
						packageName = this.parseFullyQualifiedName();
						if(!this.isValidPackagePath(packageName)) this.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknown("Package name must be all lower case"),p1,this.tokenizer.tokenMax));
						this.ensure(haxe.languageservices.parser.Token.TSemicolon);
						parts.push(this.mkStm(haxe.languageservices.parser.StmDef.EPackage(packageName),p1,this.tokenizer.tokenMax));
						break;
					case "import":
						importCount++;
						if(typeCount != 0) this.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknown("Package must appear at the beggining of the file"),p1,this.tokenizer.tokenMax));
						var fqname = this.parseFullyQualifiedName();
						this.ensure(haxe.languageservices.parser.Token.TSemicolon);
						parts.push(this.mkStm(haxe.languageservices.parser.StmDef.EImport(fqname),p1,this.tokenizer.tokenMax));
						imports.push(fqname);
						break;
					case "typedef":
						typeCount++;
						var typedefName = this.parseIdentifier();
						if(typedefName == null) {
						} else {
							var type = [this.typeContext.getPackage(packageName.join(".")).getClass(typedefName,haxe.languageservices.parser.TypeTypedef)];
							type[0].typeParams = this.parseTypeParametersWithDiamonds();
							this.ensure(haxe.languageservices.parser.Token.TOp("="));
							var ttype = [null];
							this.completion.pushScope((function(ttype,type) {
								return function(c) {
									var _g1 = 0;
									var _g11 = type[0].typeParams;
									while(_g1 < _g11.length) {
										var p = _g11[_g1];
										++_g1;
										c.addLocal(p.name,haxe.languageservices.parser.CType.CTTypeParam,null);
									}
									ttype[0] = _g.parseType();
								};
							})(ttype,type));
							var ctype = haxe.languageservices.parser.CompletionTypeUtils.fromCType(ttype[0]);
							this.ensure(haxe.languageservices.parser.Token.TSemicolon);
							(js.Boot.__cast(type[0] , haxe.languageservices.parser.TypeTypedef)).setTargetType(ctype);
							parts.push(this.mkStm(haxe.languageservices.parser.StmDef.ETypedef(packageName,typedefName),p1,this.tokenizer.tokenMax));
						}
						break;
					case "class":
						typeCount++;
						var className = this.parseIdentifier();
						if(className == null) {
						} else {
							var type1 = [this.typeContext.getPackage(packageName.join(".")).getClass(className,haxe.languageservices.parser.TypeClass)];
							if(!haxe.languageservices.util.StringUtils.isFirstUpper(className)) this.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknown("Class name must be capitalized"),this.tokenizer.tokenMin,this.tokenizer.tokenMax));
							type1[0].typeParams = this.parseTypeParametersWithDiamonds();
							this.completion.pushScope((function(type1) {
								return function(c1) {
									_g.ensure(haxe.languageservices.parser.Token.TBrOpen);
									var _g12 = 0;
									var _g2 = type1[0].typeParams;
									while(_g12 < _g2.length) {
										var p2 = _g2[_g12];
										++_g12;
										c1.addLocal(p2.name,haxe.languageservices.parser.CType.CTTypeParam,null,haxe.languageservices.parser.CompletionTypeUtils.fromCType(haxe.languageservices.parser.CType.CTTypeParam));
									}
									c1.addKeyword("public");
									c1.addKeyword("private");
									c1.addKeyword("var");
									c1.addKeyword("function");
									_g.parseClassElements(type1[0]);
									_g.ensure(haxe.languageservices.parser.Token.TBrClose);
								};
							})(type1));
							parts.push(this.mkStm(haxe.languageservices.parser.StmDef.EClass(packageName,className,type1[0].typeParams),p1,this.tokenizer.tokenMax));
						}
						break;
					default:
						this.unexpected(tk,"Expected eof, package, import or class");
						this.push(tk);
						throw "__break__";
					}
					break;
				case 0:
					throw "__break__";
					break;
				default:
					this.unexpected(tk,"Expected eof, package, import or class");
					this.push(tk);
					throw "__break__";
				}
			}
		} catch( e ) { if( e != "__break__" ) throw e; }
		return this.mkStm(haxe.languageservices.parser.StmDef.EFile(parts),p0,null);
	}
	,parseTypeParametersWithDiamonds: function() {
		var tk = this.token();
		switch(tk[1]) {
		case 3:
			switch(tk[2]) {
			case "<":
				var typeParameters = this.parseTypeParameters();
				this.ensure(haxe.languageservices.parser.Token.TOp(">"));
				return typeParameters;
			default:
				this.push(tk);
			}
			break;
		default:
			this.push(tk);
		}
		return [];
	}
	,parseTypeParameters: function() {
		var params = new Array();
		try {
			while(true) {
				var param = this.parseTypeParameter();
				if(param == null) throw "__break__";
				params.push(param);
				var tk = this.token();
				switch(tk[1]) {
				case 9:
					break;
				default:
					this.push(tk);
					throw "__break__";
				}
			}
		} catch( e ) { if( e != "__break__" ) throw e; }
		return params;
	}
	,parseTypeParameter: function() {
		var tk = this.token();
		switch(tk[1]) {
		case 2:
			var name = tk[2];
			tk = this.token();
			var constraints = null;
			switch(tk[1]) {
			case 14:
				constraints = this.parseTypeParameterConstraints();
				break;
			default:
				this.push(tk);
			}
			return { name : name, constraints : constraints};
		default:
			this.push(tk);
		}
		return null;
	}
	,parseTypeParameterConstraints: function() {
		var tk = this.token();
		switch(tk[1]) {
		case 4:
			var types = this.parseTypeList();
			this.ensure(haxe.languageservices.parser.Token.TPClose);
			return types;
		case 2:
			var name = tk[2];
			this.push(tk);
			return [this.parseType()];
		default:
		}
		return null;
	}
	,parseClassElements: function(type) {
		while(true) {
			var r = this.parseClassElement(type);
			if(r == null) break;
		}
	}
	,parseClassElement: function(type) {
		var _g = this;
		var modifier = null;
		var isStatic = false;
		var isInline = false;
		var resetModifiers = function() {
			modifier = null;
			isStatic = false;
			isInline = false;
		};
		try {
			while(true) {
				var tk = this.token();
				switch(tk[1]) {
				case 2:
					switch(tk[2]) {
					case "public":case "private":
						if(modifier != null) this.unexpected(tk,"already has a modifier");
						switch(tk[1]) {
						case 2:
							switch(tk[2]) {
							case "public":
								modifier = "public";
								break;
							case "private":
								modifier = "public";
								break;
							default:
								modifier = null;
							}
							break;
						default:
							modifier = null;
						}
						break;
					case "static":
						if(isStatic == true) this.unexpected(tk,"already has the static modifier");
						isStatic = true;
						break;
					case "inline":
						if(isInline == true) this.unexpected(tk,"already has the inline modifier");
						isInline = true;
						break;
					case "var":
						var name = this.parseIdentifier();
						var ctype = this.parseOptionalTypeWithDoubleDot();
						var value = null;
						var valueType = null;
						if(this.check(haxe.languageservices.parser.Token.TOp("="))) {
							value = this.parseExpr();
							valueType = this.completion.scope.getType(value);
							if(ctype != null) {
								if(!haxe.languageservices.parser.CompletionTypeUtils.canAssign(haxe.languageservices.parser.CompletionTypeUtils.fromCType(ctype),valueType)) {
									this.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EInvalidOp("Can't assign expression to type"),value.pmin,value.pmax));
									valueType = haxe.languageservices.parser.CompletionTypeUtils.fromCType(ctype);
								}
							}
						}
						this.ensure(haxe.languageservices.parser.Token.TSemicolon);
						this.completion.scope.addLocal(name,ctype,null,valueType);
						type.members.push(new haxe.languageservices.parser.TypeField(name,valueType));
						resetModifiers();
						throw "__break__";
						break;
					case "function":
						var name1 = [this.parseIdentifier()];
						var ptypes = [this.parseTypeParametersWithDiamonds()];
						var body = [null];
						var bodyType = [null];
						var funcType = [null];
						this.completion.pushScope((function(funcType,bodyType,body,ptypes,name1) {
							return function(c) {
								var _g1 = 0;
								while(_g1 < ptypes[0].length) {
									var ptype = ptypes[0][_g1];
									++_g1;
									c.addLocal(ptype.name,null,null,haxe.languageservices.parser.CompletionType.TypeParam);
								}
								_g.ensure(haxe.languageservices.parser.Token.TPOpen);
								var args = _g.parseArgumentsDecl();
								_g.ensure(haxe.languageservices.parser.Token.TPClose);
								var rettype = _g.parseOptionalTypeWithDoubleDot();
								_g.completion.pushScope((function(funcType,bodyType,body,name1) {
									return function(c1) {
										c1.addLocal("this",null,null,haxe.languageservices.parser.CompletionType.Type2(type.fqName));
										var _g11 = 0;
										while(_g11 < args.length) {
											var arg = args[_g11];
											++_g11;
											c1.addLocal(arg.name,arg.type,null,haxe.languageservices.parser.CompletionTypeUtils.fromCType(arg.type));
										}
										body[0] = _g.parseExpr();
										bodyType[0] = c1.getType(body[0]);
										funcType[0] = haxe.languageservices.parser.CompletionType.Function(type.fqName,name1[0],(function($this) {
											var $r;
											var _g12 = [];
											{
												var _g2 = 0;
												while(_g2 < args.length) {
													var arg1 = args[_g2];
													++_g2;
													_g12.push({ name : arg1.name, type : haxe.languageservices.parser.CompletionTypeUtils.fromCType(arg1.type)});
												}
											}
											$r = _g12;
											return $r;
										}(this)),bodyType[0]);
									};
								})(funcType,bodyType,body,name1));
							};
						})(funcType,bodyType,body,ptypes,name1));
						type.members.push(new haxe.languageservices.parser.TypeMethod(name1[0],funcType[0]));
						resetModifiers();
						break;
					default:
						this.unexpected(tk,"field info");
						throw "__break__";
					}
					break;
				case 7:
					this.push(tk);
					throw "__break__";
					break;
				default:
					this.unexpected(tk,"field info");
					throw "__break__";
				}
			}
		} catch( e ) { if( e != "__break__" ) throw e; }
		return null;
	}
	,parseCommaList: function(itemReader) {
		var items = new Array();
		while(true) {
			var item = itemReader();
			if(item == null) break;
			items.push(item);
			if(!this.check(haxe.languageservices.parser.Token.TComma)) break;
		}
		return items;
	}
	,parseArgumentsDecl: function() {
		return this.parseCommaList($bind(this,this.parseArgumentDecl));
	}
	,parseArgumentDecl: function() {
		var tk = this.token();
		switch(tk[1]) {
		case 2:
			var name = tk[2];
			var type = this.parseOptionalTypeWithDoubleDot();
			return { name : name, type : type};
		default:
			this.push(tk);
		}
		return null;
	}
	,parseOptionalTypeWithDoubleDot: function() {
		var tk = this.token();
		switch(tk[1]) {
		case 14:
			return this.parseType();
		default:
			this.push(tk);
		}
		return null;
	}
	,parseIdentifier: function() {
		var tk = this.token();
		var ident = null;
		switch(tk[1]) {
		case 2:
			var id = tk[2];
			ident = id;
			break;
		default:
			this.unexpected(tk,"identifier");
		}
		return ident;
	}
	,parseFullyQualifiedName: function() {
		var chunks = new Array();
		try {
			while(true) {
				var tk = this.token();
				switch(tk[1]) {
				case 2:
					var name = tk[2];
					chunks.push(name);
					if(!this.check(haxe.languageservices.parser.Token.TDot)) throw "__break__";
					break;
				default:
					this.push(tk);
					throw "__break__";
				}
			}
		} catch( e ) { if( e != "__break__" ) throw e; }
		return chunks;
	}
	,setInput: function(s,path) {
		this.uid = 0;
		this.tokenizer = new haxe.languageservices.parser.Tokenizer(s,path);
		this.errors = new haxe.languageservices.parser.ErrorContext();
		this.completion = new haxe.languageservices.parser.CompletionContext(this.tokenizer,this.errors,this.typeContext);
	}
	,setInputString: function(s,path) {
		this.setInput(new haxe.io.StringInput(s),path);
	}
	,parseExpressions: function() {
		var _g = this;
		var a = [];
		this.completion.pushScope(function(c) {
			while(true) {
				var tk = _g.token();
				if(tk == haxe.languageservices.parser.Token.TEof) break;
				_g.push(tk);
				a.push(_g.parseFullExpr());
			}
		});
		if(a.length == 1) return a[0]; else return this.mk(haxe.languageservices.parser.ExprDef.EBlock(a),0,null);
	}
	,unexpected: function(tk,expected) {
		this.tokenizer.error(haxe.languageservices.parser.ErrorDef.EUnexpected("expected:" + expected + ", found:" + this.tokenizer.tokenString(tk) + ""),this.tokenizer.tokenMin,this.tokenizer.tokenMax);
		return null;
	}
	,push: function(t) {
		return this.tokenizer.push(t);
	}
	,token: function() {
		return this.tokenizer.token();
	}
	,ensure: function(tk) {
		var t = this.token();
		if("" + Std.string(t) != "" + Std.string(tk)) this.unexpected(t,this.tokenizer.tokenString(tk));
	}
	,check: function(tk) {
		var t = this.token();
		if(Type.enumEq(t,tk)) return true; else {
			this.push(t);
			return false;
		}
	}
	,expr: function(e) {
		return e.e;
	}
	,pmin: function(e) {
		return e.pmin;
	}
	,pmax: function(e) {
		return e.pmax;
	}
	,mk: function(e,pmin,pmax) {
		if(pmin == null) pmin = this.tokenizer.tokenMin;
		if(pmax == null) pmax = this.tokenizer.tokenMax;
		return { e : e, pmin : pmin, pmax : pmax};
	}
	,mkStm: function(e,pmin,pmax) {
		if(pmin == null) pmin = this.tokenizer.tokenMin;
		if(pmax == null) pmax = this.tokenizer.tokenMax;
		return { e : e, pmin : pmin, pmax : pmax};
	}
	,isBlock: function(e) {
		{
			var _g = e.e;
			switch(_g[1]) {
			case 4:case 21:case 23:
				return true;
			case 14:
				var e1 = _g[3];
				return this.isBlock(e1);
			case 2:
				var e2 = _g[4];
				return e2 != null && this.isBlock(e2);
			case 9:
				var e21 = _g[4];
				var e11 = _g[3];
				if(e21 != null) return this.isBlock(e21); else return this.isBlock(e11);
				break;
			case 6:
				var e3 = _g[4];
				return this.isBlock(e3);
			case 7:
				var e4 = _g[4];
				var prefix = _g[3];
				return !prefix && this.isBlock(e4);
			case 10:
				var e5 = _g[3];
				return this.isBlock(e5);
			case 11:
				var e6 = _g[4];
				return this.isBlock(e6);
			case 15:
				var e7 = _g[2];
				return e7 != null && this.isBlock(e7);
			default:
				return false;
			}
		}
	}
	,parseFullExpr: function() {
		var e = this.parseExpr();
		var tk = this.token();
		if(tk != haxe.languageservices.parser.Token.TSemicolon && tk != haxe.languageservices.parser.Token.TEof) {
			if(this.isBlock(e)) this.push(tk); else this.unexpected(tk,"block");
		}
		return e;
	}
	,callCompletionAt: function(index) {
		return this.completion.root.locateIndex(index).callCompletion;
	}
	,completionsAt: function(index) {
		var out = [];
		var scope = this.completion.root.locateIndex(index);
		{
			var _g = scope.getCompletionType();
			switch(_g[1]) {
			case 9:
				var items = _g[2];
				out = out.concat(items);
				break;
			default:
			}
		}
		return new haxe.languageservices.parser.CompletionList(out);
	}
	,parseObject: function(p1) {
		var fl = new Array();
		try {
			while(true) {
				var tk = this.token();
				var id = null;
				switch(tk[1]) {
				case 2:
					var i = tk[2];
					id = i;
					break;
				case 1:
					var c = tk[2];
					switch(c[1]) {
					case 2:
						var s = c[2];
						id = s;
						break;
					default:
						this.unexpected(tk,"string");
					}
					break;
				case 7:
					throw "__break__";
					break;
				default:
					this.unexpected(tk,"identifier, const or }");
				}
				this.ensure(haxe.languageservices.parser.Token.TDoubleDot);
				fl.push({ name : id, e : this.parseExpr()});
				tk = this.token();
				switch(tk[1]) {
				case 7:
					throw "__break__";
					break;
				case 9:
					break;
				default:
					this.unexpected(tk,"} or ,");
				}
			}
		} catch( e ) { if( e != "__break__" ) throw e; }
		return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EObject(fl),p1,null));
	}
	,parseExpr: function() {
		var _g = this;
		var tk = this.token();
		var p1 = this.tokenizer.tokenMin;
		switch(tk[1]) {
		case 2:
			var id = tk[2];
			var e = this.parseStructure(id);
			if(e == null) {
				e = this.mk(haxe.languageservices.parser.ExprDef.EIdent(id),null,null);
				var local = this.completion.scope.getLocal(id);
				if(local != null) local.addReference(haxe.languageservices.parser.Reference.Read(e)); else this.errors.errors.push(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknownVariable("Can't find \"" + id + "\""),e.pmin,e.pmax));
			}
			return this.parseExprNext(e);
		case 1:
			var c = tk[2];
			return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EConst(c),null,null));
		case 4:
			var e1 = this.parseExpr();
			this.ensure(haxe.languageservices.parser.Token.TPClose);
			return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EParent(e1),p1,this.tokenizer.tokenMax));
		case 6:
			tk = this.token();
			switch(tk[1]) {
			case 7:
				return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EObject([]),p1,null));
			case 2:
				var tk2 = this.token();
				this.push(tk2);
				this.push(tk);
				switch(tk2[1]) {
				case 14:
					return this.parseExprNext(this.parseObject(p1));
				default:
				}
				break;
			case 1:
				var c1 = tk[2];
				switch(c1[1]) {
				case 2:
					var tk21 = this.token();
					this.push(tk21);
					this.push(tk);
					switch(tk21[1]) {
					case 14:
						return this.parseExprNext(this.parseObject(p1));
					default:
					}
					break;
				default:
					this.push(tk);
				}
				break;
			default:
				this.push(tk);
			}
			var a = new Array();
			this.completion.pushScope(function(c2) {
				while(true) {
					a.push(_g.parseFullExpr());
					tk = _g.token();
					if(tk == haxe.languageservices.parser.Token.TBrClose) break;
					_g.push(tk);
				}
			});
			return this.mk(haxe.languageservices.parser.ExprDef.EBlock(a),p1,null);
		case 3:
			var op = tk[2];
			if(this.unops.exists(op)) return this.makeUnop(op,this.parseExpr());
			return this.unexpected(tk,"unary operator");
		case 11:
			var a1 = new Array();
			tk = this.token();
			while(tk != haxe.languageservices.parser.Token.TBkClose) {
				this.push(tk);
				a1.push(this.parseExpr());
				tk = this.token();
				if(tk == haxe.languageservices.parser.Token.TComma) tk = this.token();
			}
			if(a1.length == 1) {
				var _g1 = a1[0].e;
				switch(_g1[1]) {
				case 11:case 10:
					var tmp = "__a_" + this.uid++;
					var e2 = this.mk(haxe.languageservices.parser.ExprDef.EBlock([this.mk(haxe.languageservices.parser.ExprDef.EVar(tmp,null,this.mk(haxe.languageservices.parser.ExprDef.EArrayDecl([]),p1,null)),p1,null),this.mapCompr(tmp,a1[0]),this.mk(haxe.languageservices.parser.ExprDef.EIdent(tmp),p1,null)]),p1,null);
					return this.parseExprNext(e2);
				default:
				}
			}
			return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EArrayDecl(a1),p1,null));
		default:
			return this.unexpected(tk,"----");
		}
	}
	,mapCompr: function(tmp,e) {
		var edef;
		{
			var _g = e.e;
			switch(_g[1]) {
			case 11:
				var e2 = _g[4];
				var it = _g[3];
				var v = _g[2];
				edef = haxe.languageservices.parser.ExprDef.EFor(v,it,this.mapCompr(tmp,e2));
				break;
			case 10:
				var e21 = _g[3];
				var cond = _g[2];
				edef = haxe.languageservices.parser.ExprDef.EWhile(cond,this.mapCompr(tmp,e21));
				break;
			case 9:
				var e22 = _g[4];
				var e1 = _g[3];
				var cond1 = _g[2];
				if(e22 == null) edef = haxe.languageservices.parser.ExprDef.EIf(cond1,this.mapCompr(tmp,e1),null); else edef = haxe.languageservices.parser.ExprDef.ECall(this.mk(haxe.languageservices.parser.ExprDef.EField(this.mk(haxe.languageservices.parser.ExprDef.EIdent(tmp),e.pmin,e.pmax),"push"),e.pmin,e.pmax),[e]);
				break;
			case 4:
				switch(_g[2].length) {
				case 1:
					var e3 = _g[2][0];
					edef = haxe.languageservices.parser.ExprDef.EBlock([this.mapCompr(tmp,e3)]);
					break;
				default:
					edef = haxe.languageservices.parser.ExprDef.ECall(this.mk(haxe.languageservices.parser.ExprDef.EField(this.mk(haxe.languageservices.parser.ExprDef.EIdent(tmp),e.pmin,e.pmax),"push"),e.pmin,e.pmax),[e]);
				}
				break;
			case 3:
				var e23 = _g[2];
				edef = haxe.languageservices.parser.ExprDef.EParent(this.mapCompr(tmp,e23));
				break;
			default:
				edef = haxe.languageservices.parser.ExprDef.ECall(this.mk(haxe.languageservices.parser.ExprDef.EField(this.mk(haxe.languageservices.parser.ExprDef.EIdent(tmp),e.pmin,e.pmax),"push"),e.pmin,e.pmax),[e]);
			}
		}
		return this.mk(edef,e.pmin,e.pmax);
	}
	,makeUnop: function(op,e) {
		{
			var _g = e.e;
			switch(_g[1]) {
			case 6:
				var e2 = _g[4];
				var e1 = _g[3];
				var bop = _g[2];
				return this.mk(haxe.languageservices.parser.ExprDef.EBinop(bop,this.makeUnop(op,e1),e2),e1.pmin,e2.pmax);
			case 22:
				var e3 = _g[4];
				var e21 = _g[3];
				var e11 = _g[2];
				return this.mk(haxe.languageservices.parser.ExprDef.ETernary(this.makeUnop(op,e11),e21,e3),e11.pmin,e3.pmax);
			default:
				return this.mk(haxe.languageservices.parser.ExprDef.EUnop(op,true,e),e.pmin,e.pmax);
			}
		}
	}
	,makeBinop: function(op,e1,e) {
		{
			var _g = e.e;
			switch(_g[1]) {
			case 6:
				var e3 = _g[4];
				var e2 = _g[3];
				var op2 = _g[2];
				if(this.opPriority.get(op) <= this.opPriority.get(op2) && !this.opRightAssoc.exists(op)) return this.mk(haxe.languageservices.parser.ExprDef.EBinop(op2,this.makeBinop(op,e1,e2),e3),e1.pmin,e3.pmax); else return this.mk(haxe.languageservices.parser.ExprDef.EBinop(op,e1,e),e1.pmin,e.pmax);
				break;
			case 22:
				var e4 = _g[4];
				var e31 = _g[3];
				var e21 = _g[2];
				if(this.opRightAssoc.exists(op)) return this.mk(haxe.languageservices.parser.ExprDef.EBinop(op,e1,e),e1.pmin,e.pmax); else return this.mk(haxe.languageservices.parser.ExprDef.ETernary(this.makeBinop(op,e1,e21),e31,e4),e1.pmin,e.pmax);
				break;
			default:
				return this.mk(haxe.languageservices.parser.ExprDef.EBinop(op,e1,e),e1.pmin,e.pmax);
			}
		}
	}
	,parseStructure: function(id) {
		var _g = this;
		var p1 = this.tokenizer.tokenMin;
		switch(id) {
		case "if":
			var cond = this.parseExpr();
			var e1 = this.parseExpr();
			var e2 = null;
			var semic = false;
			var tk = this.token();
			if(tk == haxe.languageservices.parser.Token.TSemicolon) {
				semic = true;
				tk = this.token();
			}
			if(Type.enumEq(tk,haxe.languageservices.parser.Token.TId("else"))) e2 = this.parseExpr(); else {
				this.push(tk);
				if(semic) this.push(haxe.languageservices.parser.Token.TSemicolon);
			}
			return this.mk(haxe.languageservices.parser.ExprDef.EIf(cond,e1,e2),p1,e2 == null?this.tokenizer.tokenMax:e2.pmax);
		case "var":
			var tk1;
			var ident = this.parseIdentifier();
			tk1 = this.token();
			var t = null;
			if(tk1 == haxe.languageservices.parser.Token.TDoubleDot) {
				t = this.parseType();
				tk1 = this.token();
			}
			var e = null;
			if(Type.enumEq(tk1,haxe.languageservices.parser.Token.TOp("="))) e = this.parseExpr(); else this.push(tk1);
			this.completion.scope.addLocal(ident,t,e);
			return this.mk(haxe.languageservices.parser.ExprDef.EVar(ident,t,e),p1,e == null?this.tokenizer.tokenMax:e.pmax);
		case "while":
			var econd = this.parseExpr();
			var e3 = this.parseExpr();
			return this.mk(haxe.languageservices.parser.ExprDef.EWhile(econd,e3),p1,e3.pmax);
		case "for":
			this.ensure(haxe.languageservices.parser.Token.TPOpen);
			var tk2 = this.token();
			var vname = null;
			switch(tk2[1]) {
			case 2:
				var id1 = tk2[2];
				vname = id1;
				break;
			default:
				this.unexpected(tk2,"identifier");
			}
			tk2 = this.token();
			if(!Type.enumEq(tk2,haxe.languageservices.parser.Token.TId("in"))) this.unexpected(tk2,"in");
			var eiter = this.parseExpr();
			this.ensure(haxe.languageservices.parser.Token.TPClose);
			var e4 = null;
			var forContext = this.completion.pushScope(function(scope) {
				scope.addLocal(vname,null,eiter,scope.getElementType(eiter));
				e4 = _g.parseExpr();
			});
			return this.mk(haxe.languageservices.parser.ExprDef.EFor(vname,eiter,e4),p1,e4.pmax);
		case "break":
			return this.mk(haxe.languageservices.parser.ExprDef.EBreak,null,null);
		case "continue":
			return this.mk(haxe.languageservices.parser.ExprDef.EContinue,null,null);
		case "else":
			return this.unexpected(haxe.languageservices.parser.Token.TId(id),"--");
		case "function":
			var tk3 = this.token();
			var name = null;
			switch(tk3[1]) {
			case 2:
				var id2 = tk3[2];
				name = id2;
				break;
			default:
				this.push(tk3);
			}
			this.ensure(haxe.languageservices.parser.Token.TPOpen);
			var args = [];
			tk3 = this.token();
			if(tk3 != haxe.languageservices.parser.Token.TPClose) {
				var done = false;
				while(!done) {
					var name1 = null;
					var opt = false;
					switch(tk3[1]) {
					case 13:
						opt = true;
						tk3 = this.token();
						break;
					default:
					}
					switch(tk3[1]) {
					case 2:
						var id3 = tk3[2];
						name1 = id3;
						break;
					default:
						this.unexpected(tk3,"identifier");
					}
					tk3 = this.token();
					var arg = { name : name1};
					args.push(arg);
					if(opt) arg.opt = true;
					if(tk3 == haxe.languageservices.parser.Token.TDoubleDot) {
						arg.t = this.parseType();
						tk3 = this.token();
					}
					switch(tk3[1]) {
					case 9:
						tk3 = this.token();
						break;
					case 5:
						done = true;
						break;
					default:
						this.unexpected(tk3,"comma or )");
					}
				}
			}
			var ret = null;
			tk3 = this.token();
			if(tk3 != haxe.languageservices.parser.Token.TDoubleDot) this.push(tk3); else ret = this.parseType();
			var body = null;
			var bodyScope = this.completion.pushScope(function(scope1) {
				var _g1 = 0;
				while(_g1 < args.length) {
					var arg1 = args[_g1];
					++_g1;
					scope1.addLocal(arg1.name,arg1.t,null,haxe.languageservices.parser.CompletionTypeUtils.fromCType(arg1.t));
				}
				body = _g.parseExpr();
			});
			var expr = this.mk(haxe.languageservices.parser.ExprDef.EFunction(args,body,name,ret),p1,body.pmax);
			this.completion.scope.addLocal(name,ret,expr,null,bodyScope);
			return expr;
		case "return":
			var tk4 = this.token();
			this.push(tk4);
			var e5;
			if(tk4 == haxe.languageservices.parser.Token.TSemicolon) e5 = null; else e5 = this.parseExpr();
			return this.mk(haxe.languageservices.parser.ExprDef.EReturn(e5),p1,e5 == null?this.tokenizer.tokenMax:e5.pmax);
		case "new":
			var a = new Array();
			var tk5 = this.token();
			switch(tk5[1]) {
			case 2:
				var id4 = tk5[2];
				a.push(id4);
				break;
			default:
				this.unexpected(tk5,"identifier");
			}
			var next = true;
			while(next) {
				tk5 = this.token();
				switch(tk5[1]) {
				case 8:
					tk5 = this.token();
					switch(tk5[1]) {
					case 2:
						var id5 = tk5[2];
						a.push(id5);
						break;
					default:
						this.unexpected(tk5,"identifier");
					}
					break;
				case 4:
					next = false;
					break;
				default:
					this.unexpected(tk5,". or (");
				}
			}
			var args1 = this.parseExprList(haxe.languageservices.parser.Token.TPClose);
			return this.mk(haxe.languageservices.parser.ExprDef.ENew(a.join("."),args1),p1,null);
		case "throw":
			var e6 = this.parseExpr();
			return this.mk(haxe.languageservices.parser.ExprDef.EThrow(e6),p1,e6.pmax);
		case "try":
			var e7 = this.parseExpr();
			var tk6 = this.token();
			if(!Type.enumEq(tk6,haxe.languageservices.parser.Token.TId("catch"))) this.unexpected(tk6,"catch");
			this.ensure(haxe.languageservices.parser.Token.TPOpen);
			tk6 = this.token();
			var vname1;
			switch(tk6[1]) {
			case 2:
				var id6 = tk6[2];
				vname1 = id6;
				break;
			default:
				vname1 = this.unexpected(tk6,"identifier");
			}
			this.ensure(haxe.languageservices.parser.Token.TDoubleDot);
			var t1 = null;
			t1 = this.parseType();
			this.ensure(haxe.languageservices.parser.Token.TPClose);
			var ec = this.parseExpr();
			return this.mk(haxe.languageservices.parser.ExprDef.ETry(e7,vname1,t1,ec),p1,ec.pmax);
		case "switch":
			var e8 = this.parseExpr();
			var def = null;
			var cases = [];
			this.ensure(haxe.languageservices.parser.Token.TBrOpen);
			try {
				while(true) {
					var tk7 = this.token();
					switch(tk7[1]) {
					case 2:
						switch(tk7[2]) {
						case "case":
							var c = { values : [], expr : null};
							cases.push(c);
							try {
								while(true) {
									var e9 = this.parseExpr();
									c.values.push(e9);
									tk7 = this.token();
									switch(tk7[1]) {
									case 9:
										break;
									case 14:
										throw "__break__";
										break;
									default:
										this.unexpected(tk7,", or :");
									}
								}
							} catch( e ) { if( e != "__break__" ) throw e; }
							var exprs = [];
							try {
								while(true) {
									tk7 = this.token();
									this.push(tk7);
									switch(tk7[1]) {
									case 2:
										switch(tk7[2]) {
										case "case":case "default":
											throw "__break__";
											break;
										default:
											exprs.push(this.parseFullExpr());
										}
										break;
									case 7:
										throw "__break__";
										break;
									default:
										exprs.push(this.parseFullExpr());
									}
								}
							} catch( e ) { if( e != "__break__" ) throw e; }
							if(exprs.length == 1) c.expr = exprs[0]; else if(exprs.length == 0) c.expr = this.mk(haxe.languageservices.parser.ExprDef.EBlock([]),this.tokenizer.tokenMin,this.tokenizer.tokenMin); else c.expr = this.mk(haxe.languageservices.parser.ExprDef.EBlock(exprs),exprs[0].pmin,exprs[exprs.length - 1].pmax);
							break;
						case "default":
							if(def != null) this.unexpected(tk7,"default already specified");
							this.ensure(haxe.languageservices.parser.Token.TDoubleDot);
							var exprs1 = [];
							try {
								while(true) {
									tk7 = this.token();
									this.push(tk7);
									switch(tk7[1]) {
									case 2:
										switch(tk7[2]) {
										case "case":case "default":
											throw "__break__";
											break;
										default:
											exprs1.push(this.parseFullExpr());
										}
										break;
									case 7:
										throw "__break__";
										break;
									default:
										exprs1.push(this.parseFullExpr());
									}
								}
							} catch( e ) { if( e != "__break__" ) throw e; }
							if(exprs1.length == 1) def = exprs1[0]; else if(exprs1.length == 0) def = this.mk(haxe.languageservices.parser.ExprDef.EBlock([]),this.tokenizer.tokenMin,this.tokenizer.tokenMin); else def = this.mk(haxe.languageservices.parser.ExprDef.EBlock(exprs1),exprs1[0].pmin,exprs1[exprs1.length - 1].pmax);
							break;
						default:
							this.unexpected(tk7,"case or default or }");
						}
						break;
					case 7:
						throw "__break__";
						break;
					default:
						this.unexpected(tk7,"case or default or }");
					}
				}
			} catch( e ) { if( e != "__break__" ) throw e; }
			return this.mk(haxe.languageservices.parser.ExprDef.ESwitch(e8,cases,def),p1,this.tokenizer.tokenMax);
		default:
			return null;
		}
	}
	,afterChecks: null
	,runAfterChecks: function() {
		var _g = 0;
		var _g1 = this.afterChecks;
		while(_g < _g1.length) {
			var check = _g1[_g];
			++_g;
			check();
		}
	}
	,parseExprNext: function(e1) {
		var _g = this;
		var tk = this.token();
		switch(tk[1]) {
		case 3:
			var op = tk[2];
			if(this.unops.get(op)) {
				if(this.isBlock(e1) || (function($this) {
					var $r;
					var _g1 = e1.e;
					$r = (function($this) {
						var $r;
						switch(_g1[1]) {
						case 3:
							$r = true;
							break;
						default:
							$r = false;
						}
						return $r;
					}($this));
					return $r;
				}(this))) {
					this.push(tk);
					return e1;
				}
				return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EUnop(op,false,e1),e1.pmin,null));
			}
			return this.makeBinop(op,e1,this.parseExpr());
		case 8:
			tk = this.token();
			var field = null;
			var scope2 = this.completion.scope;
			scope2.createChild().setBounds(this.tokenizer.tokenMax,this.tokenizer.tokenMax).setCompletionTypeGen(function() {
				return scope2.getType(e1);
			});
			switch(tk[1]) {
			case 2:
				var id = tk[2];
				field = id;
				break;
			default:
				this.unexpected(tk,"identifier");
			}
			var exprType = this.completion.scope.getType(e1);
			this.afterChecks.push(function() {
				if(!haxe.languageservices.parser.CompletionTypeUtils.hasField(_g.typeContext,exprType,field)) _g.errors.add(new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnknown("Expression " + Std.string(e1) + " doesn't contain field " + field),e1.pmin,e1.pmax));
			});
			return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EField(e1,field),e1.pmin,null));
		case 4:
			var args = this.parseExprList(haxe.languageservices.parser.Token.TPClose);
			var type = this.completion.scope.getType(e1);
			switch(type[1]) {
			case 12:
				var tret = type[5];
				var targs = type[4];
				var name = type[3];
				var type1 = type[2];
				var _g11 = 0;
				var _g2 = args.length;
				while(_g11 < _g2) {
					var aindex = _g11++;
					var arg = args[aindex];
					this.completion.scope.createChild().setBounds(arg.pmin,arg.pmax).setCallCompletion(haxe.languageservices.parser.CCompletion.CallCompletion(type1,name,targs,{ type : tret},aindex));
				}
				break;
			default:
			}
			return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.ECall(e1,args),e1.pmin,null));
		case 11:
			var e2 = this.parseExpr();
			this.ensure(haxe.languageservices.parser.Token.TBkClose);
			return this.parseExprNext(this.mk(haxe.languageservices.parser.ExprDef.EArray(e1,e2),e1.pmin,null));
		case 13:
			var e21 = this.parseExpr();
			this.ensure(haxe.languageservices.parser.Token.TDoubleDot);
			var e3 = this.parseExpr();
			return this.mk(haxe.languageservices.parser.ExprDef.ETernary(e1,e21,e3),e1.pmin,e3.pmax);
		default:
			this.push(tk);
			return e1;
		}
	}
	,parseTypeList: function() {
		var types = new Array();
		while(true) {
			var type = this.parseType();
			if(type == null) break;
			types.push(type);
			if(!this.check(haxe.languageservices.parser.Token.TComma)) break;
		}
		return types;
	}
	,parseType: function() {
		var t = this.token();
		switch(t[1]) {
		case 2:
			var v = t[2];
			var path = [v];
			while(true) {
				t = this.token();
				if(t != haxe.languageservices.parser.Token.TDot) break;
				t = this.token();
				switch(t[1]) {
				case 2:
					var v1 = t[2];
					path.push(v1);
					break;
				default:
					this.unexpected(t,"identifier");
				}
			}
			var params = null;
			switch(t[1]) {
			case 3:
				var op = t[2];
				if(op == "<") {
					params = [];
					try {
						while(true) {
							params.push(this.parseType());
							t = this.token();
							switch(t[1]) {
							case 9:
								continue;
								break;
							case 3:
								var op1 = t[2];
								if(op1 == ">") throw "__break__";
								break;
							default:
							}
							this.unexpected(t,", or >");
						}
					} catch( e ) { if( e != "__break__" ) throw e; }
				} else this.push(t);
				break;
			default:
				this.push(t);
			}
			return this.parseTypeNext(haxe.languageservices.parser.CType.CTPath(path,params));
		case 4:
			var t1 = this.parseType();
			this.ensure(haxe.languageservices.parser.Token.TPClose);
			return this.parseTypeNext(haxe.languageservices.parser.CType.CTParent(t1));
		case 6:
			var fields = [];
			try {
				while(true) {
					t = this.token();
					switch(t[1]) {
					case 7:
						throw "__break__";
						break;
					case 2:
						var name = t[2];
						this.ensure(haxe.languageservices.parser.Token.TDoubleDot);
						fields.push({ name : name, t : this.parseType()});
						t = this.token();
						switch(t[1]) {
						case 9:
							break;
						case 7:
							throw "__break__";
							break;
						default:
							this.unexpected(t,", or }");
						}
						break;
					default:
						this.unexpected(t,"identifier or }");
					}
				}
			} catch( e ) { if( e != "__break__" ) throw e; }
			return this.parseTypeNext(haxe.languageservices.parser.CType.CTAnon(fields));
		default:
			return this.unexpected(t,"identifier or [ or {");
		}
	}
	,parseTypeNext: function(t) {
		var tk = this.token();
		switch(tk[1]) {
		case 3:
			var op = tk[2];
			if(op != "->") {
				this.push(tk);
				return t;
			}
			break;
		default:
			this.push(tk);
			return t;
		}
		var t2 = this.parseType();
		switch(t2[1]) {
		case 2:
			var args = t2[2];
			args.unshift(t);
			return t2;
		default:
			return haxe.languageservices.parser.CType.CTFun([t],t2);
		}
	}
	,parseExprList: function(etk) {
		var args = [];
		var tk = this.token();
		if(tk == etk) return args;
		this.push(tk);
		try {
			while(true) {
				args.push(this.parseExpr());
				tk = this.token();
				switch(tk[1]) {
				case 9:
					break;
				default:
					if(tk == etk) throw "__break__";
					this.unexpected(tk,",");
				}
			}
		} catch( e ) { if( e != "__break__" ) throw e; }
		return args;
	}
	,__class__: haxe.languageservices.parser.Parser
};
haxe.languageservices.parser.Token = $hxClasses["haxe.languageservices.parser.Token"] = { __ename__ : ["haxe","languageservices","parser","Token"], __constructs__ : ["TEof","TConst","TId","TOp","TPOpen","TPClose","TBrOpen","TBrClose","TDot","TComma","TSemicolon","TBkOpen","TBkClose","TQuestion","TDoubleDot"] };
haxe.languageservices.parser.Token.TEof = ["TEof",0];
haxe.languageservices.parser.Token.TEof.toString = $estr;
haxe.languageservices.parser.Token.TEof.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TConst = function(c) { var $x = ["TConst",1,c]; $x.__enum__ = haxe.languageservices.parser.Token; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Token.TId = function(s) { var $x = ["TId",2,s]; $x.__enum__ = haxe.languageservices.parser.Token; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Token.TOp = function(s) { var $x = ["TOp",3,s]; $x.__enum__ = haxe.languageservices.parser.Token; $x.toString = $estr; return $x; };
haxe.languageservices.parser.Token.TPOpen = ["TPOpen",4];
haxe.languageservices.parser.Token.TPOpen.toString = $estr;
haxe.languageservices.parser.Token.TPOpen.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TPClose = ["TPClose",5];
haxe.languageservices.parser.Token.TPClose.toString = $estr;
haxe.languageservices.parser.Token.TPClose.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TBrOpen = ["TBrOpen",6];
haxe.languageservices.parser.Token.TBrOpen.toString = $estr;
haxe.languageservices.parser.Token.TBrOpen.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TBrClose = ["TBrClose",7];
haxe.languageservices.parser.Token.TBrClose.toString = $estr;
haxe.languageservices.parser.Token.TBrClose.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TDot = ["TDot",8];
haxe.languageservices.parser.Token.TDot.toString = $estr;
haxe.languageservices.parser.Token.TDot.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TComma = ["TComma",9];
haxe.languageservices.parser.Token.TComma.toString = $estr;
haxe.languageservices.parser.Token.TComma.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TSemicolon = ["TSemicolon",10];
haxe.languageservices.parser.Token.TSemicolon.toString = $estr;
haxe.languageservices.parser.Token.TSemicolon.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TBkOpen = ["TBkOpen",11];
haxe.languageservices.parser.Token.TBkOpen.toString = $estr;
haxe.languageservices.parser.Token.TBkOpen.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TBkClose = ["TBkClose",12];
haxe.languageservices.parser.Token.TBkClose.toString = $estr;
haxe.languageservices.parser.Token.TBkClose.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TQuestion = ["TQuestion",13];
haxe.languageservices.parser.Token.TQuestion.toString = $estr;
haxe.languageservices.parser.Token.TQuestion.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.TDoubleDot = ["TDoubleDot",14];
haxe.languageservices.parser.Token.TDoubleDot.toString = $estr;
haxe.languageservices.parser.Token.TDoubleDot.__enum__ = haxe.languageservices.parser.Token;
haxe.languageservices.parser.Token.__empty_constructs__ = [haxe.languageservices.parser.Token.TEof,haxe.languageservices.parser.Token.TPOpen,haxe.languageservices.parser.Token.TPClose,haxe.languageservices.parser.Token.TBrOpen,haxe.languageservices.parser.Token.TBrClose,haxe.languageservices.parser.Token.TDot,haxe.languageservices.parser.Token.TComma,haxe.languageservices.parser.Token.TSemicolon,haxe.languageservices.parser.Token.TBkOpen,haxe.languageservices.parser.Token.TBkClose,haxe.languageservices.parser.Token.TQuestion,haxe.languageservices.parser.Token.TDoubleDot];
haxe.languageservices.parser.Tokenizer = function(input,path) {
	this.line = 1;
	this.ops = [];
	this.idents = [];
	this.readPos = 0;
	this.tokenMin = this.oldTokenMin = 0;
	this.tokenMax = this.oldTokenMax = 0;
	this.tokens = new List();
	this["char"] = -1;
	this.input = input;
	this.path = path;
	var opChars = "+*/-=!><&|^%~";
	var identChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_";
	var _g1 = 0;
	var _g = opChars.length;
	while(_g1 < _g) {
		var i = _g1++;
		this.ops[HxOverrides.cca(opChars,i)] = true;
	}
	var _g11 = 0;
	var _g2 = identChars.length;
	while(_g11 < _g2) {
		var i1 = _g11++;
		this.idents[HxOverrides.cca(identChars,i1)] = true;
	}
};
$hxClasses["haxe.languageservices.parser.Tokenizer"] = haxe.languageservices.parser.Tokenizer;
haxe.languageservices.parser.Tokenizer.__name__ = ["haxe","languageservices","parser","Tokenizer"];
haxe.languageservices.parser.Tokenizer.prototype = {
	input: null
	,line: null
	,tokens: null
	,tokenMin: null
	,tokenMax: null
	,oldTokenMin: null
	,oldTokenMax: null
	,readPos: null
	,'char': null
	,ops: null
	,idents: null
	,path: null
	,token: function() {
		var t = this.tokens.pop();
		if(t != null) {
			this.tokenMin = t.min;
			this.tokenMax = t.max;
			return t.t;
		}
		this.oldTokenMin = this.tokenMin;
		this.oldTokenMax = this.tokenMax;
		if(this["char"] < 0) this.tokenMin = this.readPos; else this.tokenMin = this.readPos - 1;
		var t1 = this._token();
		if(this["char"] < 0) this.tokenMax = this.readPos - 1; else this.tokenMax = this.readPos - 2;
		return t1;
	}
	,_token: function() {
		var $char;
		if(this["char"] < 0) $char = this.readChar(); else {
			$char = this["char"];
			this["char"] = -1;
		}
		while(true) {
			switch($char) {
			case 0:
				return haxe.languageservices.parser.Token.TEof;
			case 32:case 9:case 13:
				this.tokenMin++;
				break;
			case 10:
				this.line++;
				this.tokenMin++;
				break;
			case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
				var n = ($char - 48) * 1.0;
				var exp = 0.;
				while(true) {
					$char = this.readChar();
					exp *= 10;
					switch($char) {
					case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
						n = n * 10 + ($char - 48);
						break;
					case 46:
						if(exp > 0) {
							if(exp == 10 && this.readChar() == 46) {
								this.push(haxe.languageservices.parser.Token.TOp("..."));
								var i = n | 0;
								return haxe.languageservices.parser.Token.TConst(i == n?haxe.languageservices.parser.Const.CInt(i):haxe.languageservices.parser.Const.CFloat(n));
							}
							this.invalidChar($char);
						}
						exp = 1.;
						break;
					case 120:
						if(n > 0 || exp > 0) this.invalidChar($char);
						var n1 = 0;
						while(true) {
							$char = this.readChar();
							switch($char) {
							case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
								n1 = (n1 << 4) + $char - 48;
								break;
							case 65:case 66:case 67:case 68:case 69:case 70:
								n1 = (n1 << 4) + ($char - 55);
								break;
							case 97:case 98:case 99:case 100:case 101:case 102:
								n1 = (n1 << 4) + ($char - 87);
								break;
							default:
								this["char"] = $char;
								return haxe.languageservices.parser.Token.TConst(haxe.languageservices.parser.Const.CInt(n1));
							}
						}
						break;
					default:
						this["char"] = $char;
						var i1 = n | 0;
						return haxe.languageservices.parser.Token.TConst(exp > 0?haxe.languageservices.parser.Const.CFloat(n * 10 / exp):i1 == n?haxe.languageservices.parser.Const.CInt(i1):haxe.languageservices.parser.Const.CFloat(n));
					}
				}
				break;
			case 59:
				return haxe.languageservices.parser.Token.TSemicolon;
			case 40:
				return haxe.languageservices.parser.Token.TPOpen;
			case 41:
				return haxe.languageservices.parser.Token.TPClose;
			case 44:
				return haxe.languageservices.parser.Token.TComma;
			case 46:
				$char = this.readChar();
				switch($char) {
				case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
					var n2 = $char - 48;
					var exp1 = 1;
					while(true) {
						$char = this.readChar();
						exp1 *= 10;
						switch($char) {
						case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
							n2 = n2 * 10 + ($char - 48);
							break;
						default:
							this["char"] = $char;
							return haxe.languageservices.parser.Token.TConst(haxe.languageservices.parser.Const.CFloat(n2 / exp1));
						}
					}
					break;
				case 46:
					$char = this.readChar();
					if($char != 46) this.invalidChar($char);
					return haxe.languageservices.parser.Token.TOp("...");
				default:
					this["char"] = $char;
					return haxe.languageservices.parser.Token.TDot;
				}
				break;
			case 123:
				return haxe.languageservices.parser.Token.TBrOpen;
			case 125:
				return haxe.languageservices.parser.Token.TBrClose;
			case 91:
				return haxe.languageservices.parser.Token.TBkOpen;
			case 93:
				return haxe.languageservices.parser.Token.TBkClose;
			case 39:
				return haxe.languageservices.parser.Token.TConst(haxe.languageservices.parser.Const.CString(this.readString(39)));
			case 34:
				return haxe.languageservices.parser.Token.TConst(haxe.languageservices.parser.Const.CString(this.readString(34)));
			case 63:
				return haxe.languageservices.parser.Token.TQuestion;
			case 58:
				return haxe.languageservices.parser.Token.TDoubleDot;
			default:
				if(this.ops[$char]) {
					var op = String.fromCharCode($char);
					while(true) {
						$char = this.readChar();
						if(!this.ops[$char]) {
							if(HxOverrides.cca(op,0) == 47) return this.tokenComment(op,$char);
							this["char"] = $char;
							return haxe.languageservices.parser.Token.TOp(op);
						}
						op += String.fromCharCode($char);
					}
				}
				if(this.idents[$char]) {
					var id = String.fromCharCode($char);
					while(true) {
						$char = this.readChar();
						if(!this.idents[$char]) {
							this["char"] = $char;
							return haxe.languageservices.parser.Token.TId(id);
						}
						id += String.fromCharCode($char);
					}
				}
				this.invalidChar($char);
			}
			$char = this.readChar();
		}
		return null;
	}
	,readString: function(until) {
		var c = 0;
		var b = new haxe.io.BytesOutput();
		var esc = false;
		var old = this.line;
		var s = this.input;
		var p1 = this.readPos - 1;
		while(true) {
			try {
				this.readPos++;
				c = s.readByte();
			} catch( e ) {
				this.line = old;
				throw new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnterminatedString,p1,p1);
			}
			if(esc) {
				esc = false;
				switch(c) {
				case 110:
					b.writeByte(10);
					break;
				case 114:
					b.writeByte(13);
					break;
				case 116:
					b.writeByte(9);
					break;
				case 39:case 34:case 92:
					b.writeByte(c);
					break;
				case 47:
					b.writeByte(c);
					break;
				case 117:
					var code = null;
					try {
						this.readPos++;
						this.readPos++;
						this.readPos++;
						this.readPos++;
						code = s.readString(4);
					} catch( e1 ) {
						this.line = old;
						throw new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnterminatedString,p1,p1);
					}
					var k = 0;
					var _g = 0;
					while(_g < 4) {
						var i = _g++;
						k <<= 4;
						var $char = HxOverrides.cca(code,i);
						switch($char) {
						case 48:case 49:case 50:case 51:case 52:case 53:case 54:case 55:case 56:case 57:
							k += $char - 48;
							break;
						case 65:case 66:case 67:case 68:case 69:case 70:
							k += $char - 55;
							break;
						case 97:case 98:case 99:case 100:case 101:case 102:
							k += $char - 87;
							break;
						default:
							this.invalidChar($char);
						}
					}
					if(k <= 127) b.writeByte(k); else if(k <= 2047) {
						b.writeByte(192 | k >> 6);
						b.writeByte(128 | k & 63);
					} else {
						b.writeByte(224 | k >> 12);
						b.writeByte(128 | k >> 6 & 63);
						b.writeByte(128 | k & 63);
					}
					break;
				default:
					this.invalidChar(c);
				}
			} else if(c == 92) esc = true; else if(c == until) break; else {
				if(c == 10) this.line++;
				b.writeByte(c);
			}
		}
		return b.getBytes().toString();
	}
	,tokenComment: function(op,$char) {
		var c = HxOverrides.cca(op,1);
		var s = this.input;
		if(c == 47) {
			try {
				while($char != 10 && $char != 13) {
					this.readPos++;
					$char = s.readByte();
				}
				this["char"] = $char;
			} catch( e ) {
			}
			return this.token();
		}
		if(c == 42) {
			var old = this.line;
			try {
				while(true) {
					while($char != 42) {
						if($char == 10) this.line++;
						this.readPos++;
						$char = s.readByte();
					}
					this.readPos++;
					$char = s.readByte();
					if($char == 47) break;
				}
			} catch( e1 ) {
				this.line = old;
				throw new haxe.languageservices.parser.Error(haxe.languageservices.parser.ErrorDef.EUnterminatedComment,this.tokenMin,this.tokenMin);
			}
			return this.token();
		}
		this["char"] = $char;
		return haxe.languageservices.parser.Token.TOp(op);
	}
	,error: function(err,pmin,pmax) {
		throw new haxe.languageservices.parser.Error(err,pmin,pmax);
	}
	,push: function(tk) {
		this.tokens.push({ t : tk, min : this.tokenMin, max : this.tokenMax});
		this.tokenMin = this.oldTokenMin;
		this.tokenMax = this.oldTokenMax;
	}
	,incPos: function() {
		this.readPos++;
	}
	,readChar: function() {
		this.readPos++;
		try {
			return this.input.readByte();
		} catch( e ) {
			return 0;
		}
	}
	,invalidChar: function(c) {
		this.error(haxe.languageservices.parser.ErrorDef.EInvalidChar(c),this.readPos,this.readPos);
	}
	,constString: function(c) {
		switch(c[1]) {
		case 0:
			var v = c[2];
			if(v == null) return "null"; else return "" + v;
			break;
		case 1:
			var f = c[2];
			if(f == null) return "null"; else return "" + f;
			break;
		case 2:
			var s = c[2];
			return s;
		}
	}
	,tokenString: function(t) {
		switch(t[1]) {
		case 0:
			return "<eof>";
		case 1:
			var c = t[2];
			return this.constString(c);
		case 2:
			var s = t[2];
			return s;
		case 3:
			var s1 = t[2];
			return s1;
		case 4:
			return "(";
		case 5:
			return ")";
		case 6:
			return "{";
		case 7:
			return "}";
		case 8:
			return ".";
		case 9:
			return ",";
		case 10:
			return ";";
		case 11:
			return "[";
		case 12:
			return "]";
		case 13:
			return "?";
		case 14:
			return ":";
		}
	}
	,__class__: haxe.languageservices.parser.Tokenizer
};
haxe.languageservices.parser.TypeContext = function() {
	this.packages = new haxe.ds.StringMap();
};
$hxClasses["haxe.languageservices.parser.TypeContext"] = haxe.languageservices.parser.TypeContext;
haxe.languageservices.parser.TypeContext.__name__ = ["haxe","languageservices","parser","TypeContext"];
haxe.languageservices.parser.TypeContext.prototype = {
	packages: null
	,getPackage: function(name) {
		var packag = this.packages.get(name);
		if(packag == null) {
			var v = new haxe.languageservices.parser.TypePackage(this,name);
			this.packages.set(name,v);
			packag = v;
		}
		return packag;
	}
	,getPackage2: function(chunks) {
		return this.getPackage(chunks.join("."));
	}
	,getTypeFq: function(fqName) {
		var items = fqName.split(".");
		var typeName = items.pop();
		return this.getPackage2(items).getClass(typeName,null);
	}
	,getAllTypes: function(out) {
		if(out == null) out = [];
		var $it0 = this.packages.iterator();
		while( $it0.hasNext() ) {
			var packag = $it0.next();
			packag.getClasses(out);
		}
		return out;
	}
	,__class__: haxe.languageservices.parser.TypeContext
};
haxe.languageservices.parser.TypePackage = function(context,name) {
	this.classes = new haxe.ds.StringMap();
	this.context = context;
	this.name = name;
	this.parts = name.split(".");
};
$hxClasses["haxe.languageservices.parser.TypePackage"] = haxe.languageservices.parser.TypePackage;
haxe.languageservices.parser.TypePackage.__name__ = ["haxe","languageservices","parser","TypePackage"];
haxe.languageservices.parser.TypePackage.prototype = {
	context: null
	,parts: null
	,name: null
	,classes: null
	,toString: function() {
		return "TypePackage(" + this.name + ")";
	}
	,getClass: function(name,_newKind) {
		var clazz = this.classes.get(name);
		if(clazz == null) {
			var v = Type.createInstance(_newKind,[this,name]);
			this.classes.set(name,v);
			clazz = v;
		}
		return clazz;
	}
	,getClasses: function(out) {
		if(out == null) out = [];
		var $it0 = this.classes.iterator();
		while( $it0.hasNext() ) {
			var clazz = $it0.next();
			out.push(clazz);
		}
		return out;
	}
	,__class__: haxe.languageservices.parser.TypePackage
};
haxe.languageservices.parser.TypeType = function(packag,name) {
	this.typeParams = new Array();
	this.members = new Array();
	this.imports = new Array();
	this.uid = haxe.languageservices.parser.TypeType.lastUid++;
	this.packag = packag;
	this.name = name;
	if(packag.name.length > 0) this.fqName = packag.name + "." + name; else this.fqName = name;
};
$hxClasses["haxe.languageservices.parser.TypeType"] = haxe.languageservices.parser.TypeType;
haxe.languageservices.parser.TypeType.__name__ = ["haxe","languageservices","parser","TypeType"];
haxe.languageservices.parser.TypeType.prototype = {
	uid: null
	,packag: null
	,name: null
	,fqName: null
	,imports: null
	,members: null
	,typeParams: null
	,getDescription: function() {
		var getParamTypeString = function(p) {
			var getConstraints = function(p1) {
				if(p1 == null || p1.length == 0) return "";
				if(p1.length == 1) return ":" + Std.string(haxe.languageservices.parser.CompletionTypeUtils.fromCType(p1[0]));
				return ":(" + ((function($this) {
					var $r;
					var _g = [];
					{
						var _g1 = 0;
						while(_g1 < p1.length) {
							var n = p1[_g1];
							++_g1;
							_g.push("" + Std.string(haxe.languageservices.parser.CompletionTypeUtils.fromCType(n)));
						}
					}
					$r = _g;
					return $r;
				}(this))).join(",") + ")";
			};
			return p.name + getConstraints(p.constraints);
		};
		if(this.typeParams != null && this.typeParams.length > 0) return "" + this.fqName + "<" + ((function($this) {
			var $r;
			var _g2 = [];
			{
				var _g11 = 0;
				var _g21 = $this.typeParams;
				while(_g11 < _g21.length) {
					var p2 = _g21[_g11];
					++_g11;
					_g2.push(getParamTypeString(p2));
				}
			}
			$r = _g2;
			return $r;
		}(this))).join(",") + ">"; else return this.fqName;
	}
	,toString: function() {
		return "TypeType(" + this.getDescription() + ")";
	}
	,__class__: haxe.languageservices.parser.TypeType
};
haxe.languageservices.parser.TypeClass = function(packag,name) {
	haxe.languageservices.parser.TypeType.call(this,packag,name);
};
$hxClasses["haxe.languageservices.parser.TypeClass"] = haxe.languageservices.parser.TypeClass;
haxe.languageservices.parser.TypeClass.__name__ = ["haxe","languageservices","parser","TypeClass"];
haxe.languageservices.parser.TypeClass.__super__ = haxe.languageservices.parser.TypeType;
haxe.languageservices.parser.TypeClass.prototype = $extend(haxe.languageservices.parser.TypeType.prototype,{
	toString: function() {
		return "TypeClass(" + this.getDescription() + ")";
	}
	,__class__: haxe.languageservices.parser.TypeClass
});
haxe.languageservices.parser.TypeEnum = function(packag,name) {
	haxe.languageservices.parser.TypeType.call(this,packag,name);
};
$hxClasses["haxe.languageservices.parser.TypeEnum"] = haxe.languageservices.parser.TypeEnum;
haxe.languageservices.parser.TypeEnum.__name__ = ["haxe","languageservices","parser","TypeEnum"];
haxe.languageservices.parser.TypeEnum.__super__ = haxe.languageservices.parser.TypeType;
haxe.languageservices.parser.TypeEnum.prototype = $extend(haxe.languageservices.parser.TypeType.prototype,{
	toString: function() {
		return "TypeEnum(" + this.getDescription() + ")";
	}
	,__class__: haxe.languageservices.parser.TypeEnum
});
haxe.languageservices.parser.TypeAbstract = function(packag,name) {
	haxe.languageservices.parser.TypeType.call(this,packag,name);
};
$hxClasses["haxe.languageservices.parser.TypeAbstract"] = haxe.languageservices.parser.TypeAbstract;
haxe.languageservices.parser.TypeAbstract.__name__ = ["haxe","languageservices","parser","TypeAbstract"];
haxe.languageservices.parser.TypeAbstract.__super__ = haxe.languageservices.parser.TypeType;
haxe.languageservices.parser.TypeAbstract.prototype = $extend(haxe.languageservices.parser.TypeType.prototype,{
	toString: function() {
		return "TypeAbstract(" + this.getDescription() + ")";
	}
	,__class__: haxe.languageservices.parser.TypeAbstract
});
haxe.languageservices.parser.TypeTypedef = function(packag,name) {
	haxe.languageservices.parser.TypeType.call(this,packag,name);
};
$hxClasses["haxe.languageservices.parser.TypeTypedef"] = haxe.languageservices.parser.TypeTypedef;
haxe.languageservices.parser.TypeTypedef.__name__ = ["haxe","languageservices","parser","TypeTypedef"];
haxe.languageservices.parser.TypeTypedef.__super__ = haxe.languageservices.parser.TypeType;
haxe.languageservices.parser.TypeTypedef.prototype = $extend(haxe.languageservices.parser.TypeType.prototype,{
	targetType: null
	,toString: function() {
		return "TypeTypedef(" + this.getDescription() + "->" + Std.string(this.targetType) + ")";
	}
	,setTargetType: function(targetType) {
		this.targetType = targetType;
	}
	,__class__: haxe.languageservices.parser.TypeTypedef
});
haxe.languageservices.parser.TypeMember = function(name,type) {
	this.name = name;
	this.type = type;
};
$hxClasses["haxe.languageservices.parser.TypeMember"] = haxe.languageservices.parser.TypeMember;
haxe.languageservices.parser.TypeMember.__name__ = ["haxe","languageservices","parser","TypeMember"];
haxe.languageservices.parser.TypeMember.prototype = {
	visibility: null
	,isStatic: null
	,name: null
	,type: null
	,__class__: haxe.languageservices.parser.TypeMember
};
haxe.languageservices.parser.TypeField = function(name,type) {
	haxe.languageservices.parser.TypeMember.call(this,name,type);
};
$hxClasses["haxe.languageservices.parser.TypeField"] = haxe.languageservices.parser.TypeField;
haxe.languageservices.parser.TypeField.__name__ = ["haxe","languageservices","parser","TypeField"];
haxe.languageservices.parser.TypeField.__super__ = haxe.languageservices.parser.TypeMember;
haxe.languageservices.parser.TypeField.prototype = $extend(haxe.languageservices.parser.TypeMember.prototype,{
	__class__: haxe.languageservices.parser.TypeField
});
haxe.languageservices.parser.TypeMethod = function(name,type) {
	haxe.languageservices.parser.TypeMember.call(this,name,type);
};
$hxClasses["haxe.languageservices.parser.TypeMethod"] = haxe.languageservices.parser.TypeMethod;
haxe.languageservices.parser.TypeMethod.__name__ = ["haxe","languageservices","parser","TypeMethod"];
haxe.languageservices.parser.TypeMethod.__super__ = haxe.languageservices.parser.TypeMember;
haxe.languageservices.parser.TypeMethod.prototype = $extend(haxe.languageservices.parser.TypeMember.prototype,{
	__class__: haxe.languageservices.parser.TypeMethod
});
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
haxe.languageservices.util.ArrayUtils = function() { };
$hxClasses["haxe.languageservices.util.ArrayUtils"] = haxe.languageservices.util.ArrayUtils;
haxe.languageservices.util.ArrayUtils.__name__ = ["haxe","languageservices","util","ArrayUtils"];
haxe.languageservices.util.ArrayUtils.unique = function(array) {
	var out = new Array();
	var _g = 0;
	while(_g < array.length) {
		var item = array[_g];
		++_g;
		if(HxOverrides.indexOf(out,item,0) < 0) out.push(item);
	}
	return out;
};
haxe.languageservices.util.ArrayUtils.sorted = function(array) {
	var out = array.slice(0,array.length);
	out.sort(haxe.languageservices.util.ArrayUtils.compare);
	return out;
};
haxe.languageservices.util.ArrayUtils.uniqueSorted = function(array) {
	return haxe.languageservices.util.ArrayUtils.sorted(haxe.languageservices.util.ArrayUtils.unique(array));
};
haxe.languageservices.util.ArrayUtils.compare = function(a,b) {
	if(a < b) return -1; else if(a > b) return 1; else return 0;
};
haxe.languageservices.util.ArrayUtils.contains = function(array,item) {
	return HxOverrides.indexOf(array,item,0) >= 0;
};
haxe.languageservices.util.ArrayUtils.containsAll = function(a,sub) {
	var _g = 0;
	while(_g < sub.length) {
		var i = sub[_g];
		++_g;
		if(!haxe.languageservices.util.ArrayUtils.contains(a,i)) return false;
	}
	return true;
};
haxe.languageservices.util.ArrayUtils.containsAny = function(a,sub) {
	var _g = 0;
	while(_g < sub.length) {
		var i = sub[_g];
		++_g;
		if(haxe.languageservices.util.ArrayUtils.contains(a,i)) return true;
	}
	return false;
};
haxe.languageservices.util.ArrayUtils.pushOnce = function(array,value) {
	if(!haxe.languageservices.util.ArrayUtils.contains(array,value)) array.push(value);
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
haxe.macro = {};
haxe.macro.Constant = $hxClasses["haxe.macro.Constant"] = { __ename__ : ["haxe","macro","Constant"], __constructs__ : ["CInt","CFloat","CString","CIdent","CRegexp"] };
haxe.macro.Constant.CInt = function(v) { var $x = ["CInt",0,v]; $x.__enum__ = haxe.macro.Constant; $x.toString = $estr; return $x; };
haxe.macro.Constant.CFloat = function(f) { var $x = ["CFloat",1,f]; $x.__enum__ = haxe.macro.Constant; $x.toString = $estr; return $x; };
haxe.macro.Constant.CString = function(s) { var $x = ["CString",2,s]; $x.__enum__ = haxe.macro.Constant; $x.toString = $estr; return $x; };
haxe.macro.Constant.CIdent = function(s) { var $x = ["CIdent",3,s]; $x.__enum__ = haxe.macro.Constant; $x.toString = $estr; return $x; };
haxe.macro.Constant.CRegexp = function(r,opt) { var $x = ["CRegexp",4,r,opt]; $x.__enum__ = haxe.macro.Constant; $x.toString = $estr; return $x; };
haxe.macro.Constant.__empty_constructs__ = [];
haxe.macro.Binop = $hxClasses["haxe.macro.Binop"] = { __ename__ : ["haxe","macro","Binop"], __constructs__ : ["OpAdd","OpMult","OpDiv","OpSub","OpAssign","OpEq","OpNotEq","OpGt","OpGte","OpLt","OpLte","OpAnd","OpOr","OpXor","OpBoolAnd","OpBoolOr","OpShl","OpShr","OpUShr","OpMod","OpAssignOp","OpInterval","OpArrow"] };
haxe.macro.Binop.OpAdd = ["OpAdd",0];
haxe.macro.Binop.OpAdd.toString = $estr;
haxe.macro.Binop.OpAdd.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpMult = ["OpMult",1];
haxe.macro.Binop.OpMult.toString = $estr;
haxe.macro.Binop.OpMult.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpDiv = ["OpDiv",2];
haxe.macro.Binop.OpDiv.toString = $estr;
haxe.macro.Binop.OpDiv.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpSub = ["OpSub",3];
haxe.macro.Binop.OpSub.toString = $estr;
haxe.macro.Binop.OpSub.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpAssign = ["OpAssign",4];
haxe.macro.Binop.OpAssign.toString = $estr;
haxe.macro.Binop.OpAssign.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpEq = ["OpEq",5];
haxe.macro.Binop.OpEq.toString = $estr;
haxe.macro.Binop.OpEq.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpNotEq = ["OpNotEq",6];
haxe.macro.Binop.OpNotEq.toString = $estr;
haxe.macro.Binop.OpNotEq.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpGt = ["OpGt",7];
haxe.macro.Binop.OpGt.toString = $estr;
haxe.macro.Binop.OpGt.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpGte = ["OpGte",8];
haxe.macro.Binop.OpGte.toString = $estr;
haxe.macro.Binop.OpGte.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpLt = ["OpLt",9];
haxe.macro.Binop.OpLt.toString = $estr;
haxe.macro.Binop.OpLt.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpLte = ["OpLte",10];
haxe.macro.Binop.OpLte.toString = $estr;
haxe.macro.Binop.OpLte.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpAnd = ["OpAnd",11];
haxe.macro.Binop.OpAnd.toString = $estr;
haxe.macro.Binop.OpAnd.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpOr = ["OpOr",12];
haxe.macro.Binop.OpOr.toString = $estr;
haxe.macro.Binop.OpOr.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpXor = ["OpXor",13];
haxe.macro.Binop.OpXor.toString = $estr;
haxe.macro.Binop.OpXor.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpBoolAnd = ["OpBoolAnd",14];
haxe.macro.Binop.OpBoolAnd.toString = $estr;
haxe.macro.Binop.OpBoolAnd.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpBoolOr = ["OpBoolOr",15];
haxe.macro.Binop.OpBoolOr.toString = $estr;
haxe.macro.Binop.OpBoolOr.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpShl = ["OpShl",16];
haxe.macro.Binop.OpShl.toString = $estr;
haxe.macro.Binop.OpShl.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpShr = ["OpShr",17];
haxe.macro.Binop.OpShr.toString = $estr;
haxe.macro.Binop.OpShr.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpUShr = ["OpUShr",18];
haxe.macro.Binop.OpUShr.toString = $estr;
haxe.macro.Binop.OpUShr.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpMod = ["OpMod",19];
haxe.macro.Binop.OpMod.toString = $estr;
haxe.macro.Binop.OpMod.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpAssignOp = function(op) { var $x = ["OpAssignOp",20,op]; $x.__enum__ = haxe.macro.Binop; $x.toString = $estr; return $x; };
haxe.macro.Binop.OpInterval = ["OpInterval",21];
haxe.macro.Binop.OpInterval.toString = $estr;
haxe.macro.Binop.OpInterval.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.OpArrow = ["OpArrow",22];
haxe.macro.Binop.OpArrow.toString = $estr;
haxe.macro.Binop.OpArrow.__enum__ = haxe.macro.Binop;
haxe.macro.Binop.__empty_constructs__ = [haxe.macro.Binop.OpAdd,haxe.macro.Binop.OpMult,haxe.macro.Binop.OpDiv,haxe.macro.Binop.OpSub,haxe.macro.Binop.OpAssign,haxe.macro.Binop.OpEq,haxe.macro.Binop.OpNotEq,haxe.macro.Binop.OpGt,haxe.macro.Binop.OpGte,haxe.macro.Binop.OpLt,haxe.macro.Binop.OpLte,haxe.macro.Binop.OpAnd,haxe.macro.Binop.OpOr,haxe.macro.Binop.OpXor,haxe.macro.Binop.OpBoolAnd,haxe.macro.Binop.OpBoolOr,haxe.macro.Binop.OpShl,haxe.macro.Binop.OpShr,haxe.macro.Binop.OpUShr,haxe.macro.Binop.OpMod,haxe.macro.Binop.OpInterval,haxe.macro.Binop.OpArrow];
haxe.macro.Unop = $hxClasses["haxe.macro.Unop"] = { __ename__ : ["haxe","macro","Unop"], __constructs__ : ["OpIncrement","OpDecrement","OpNot","OpNeg","OpNegBits"] };
haxe.macro.Unop.OpIncrement = ["OpIncrement",0];
haxe.macro.Unop.OpIncrement.toString = $estr;
haxe.macro.Unop.OpIncrement.__enum__ = haxe.macro.Unop;
haxe.macro.Unop.OpDecrement = ["OpDecrement",1];
haxe.macro.Unop.OpDecrement.toString = $estr;
haxe.macro.Unop.OpDecrement.__enum__ = haxe.macro.Unop;
haxe.macro.Unop.OpNot = ["OpNot",2];
haxe.macro.Unop.OpNot.toString = $estr;
haxe.macro.Unop.OpNot.__enum__ = haxe.macro.Unop;
haxe.macro.Unop.OpNeg = ["OpNeg",3];
haxe.macro.Unop.OpNeg.toString = $estr;
haxe.macro.Unop.OpNeg.__enum__ = haxe.macro.Unop;
haxe.macro.Unop.OpNegBits = ["OpNegBits",4];
haxe.macro.Unop.OpNegBits.toString = $estr;
haxe.macro.Unop.OpNegBits.__enum__ = haxe.macro.Unop;
haxe.macro.Unop.__empty_constructs__ = [haxe.macro.Unop.OpIncrement,haxe.macro.Unop.OpDecrement,haxe.macro.Unop.OpNot,haxe.macro.Unop.OpNeg,haxe.macro.Unop.OpNegBits];
haxe.macro.ExprDef = $hxClasses["haxe.macro.ExprDef"] = { __ename__ : ["haxe","macro","ExprDef"], __constructs__ : ["EConst","EArray","EBinop","EField","EParenthesis","EObjectDecl","EArrayDecl","ECall","ENew","EUnop","EVars","EFunction","EBlock","EFor","EIn","EIf","EWhile","ESwitch","ETry","EReturn","EBreak","EContinue","EUntyped","EThrow","ECast","EDisplay","EDisplayNew","ETernary","ECheckType","EMeta"] };
haxe.macro.ExprDef.EConst = function(c) { var $x = ["EConst",0,c]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EArray = function(e1,e2) { var $x = ["EArray",1,e1,e2]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EBinop = function(op,e1,e2) { var $x = ["EBinop",2,op,e1,e2]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EField = function(e,field) { var $x = ["EField",3,e,field]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EParenthesis = function(e) { var $x = ["EParenthesis",4,e]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EObjectDecl = function(fields) { var $x = ["EObjectDecl",5,fields]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EArrayDecl = function(values) { var $x = ["EArrayDecl",6,values]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ECall = function(e,params) { var $x = ["ECall",7,e,params]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ENew = function(t,params) { var $x = ["ENew",8,t,params]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EUnop = function(op,postFix,e) { var $x = ["EUnop",9,op,postFix,e]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EVars = function(vars) { var $x = ["EVars",10,vars]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EFunction = function(name,f) { var $x = ["EFunction",11,name,f]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EBlock = function(exprs) { var $x = ["EBlock",12,exprs]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EFor = function(it,expr) { var $x = ["EFor",13,it,expr]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EIn = function(e1,e2) { var $x = ["EIn",14,e1,e2]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EIf = function(econd,eif,eelse) { var $x = ["EIf",15,econd,eif,eelse]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EWhile = function(econd,e,normalWhile) { var $x = ["EWhile",16,econd,e,normalWhile]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ESwitch = function(e,cases,edef) { var $x = ["ESwitch",17,e,cases,edef]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ETry = function(e,catches) { var $x = ["ETry",18,e,catches]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EReturn = function(e) { var $x = ["EReturn",19,e]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EBreak = ["EBreak",20];
haxe.macro.ExprDef.EBreak.toString = $estr;
haxe.macro.ExprDef.EBreak.__enum__ = haxe.macro.ExprDef;
haxe.macro.ExprDef.EContinue = ["EContinue",21];
haxe.macro.ExprDef.EContinue.toString = $estr;
haxe.macro.ExprDef.EContinue.__enum__ = haxe.macro.ExprDef;
haxe.macro.ExprDef.EUntyped = function(e) { var $x = ["EUntyped",22,e]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EThrow = function(e) { var $x = ["EThrow",23,e]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ECast = function(e,t) { var $x = ["ECast",24,e,t]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EDisplay = function(e,isCall) { var $x = ["EDisplay",25,e,isCall]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EDisplayNew = function(t) { var $x = ["EDisplayNew",26,t]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ETernary = function(econd,eif,eelse) { var $x = ["ETernary",27,econd,eif,eelse]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.ECheckType = function(e,t) { var $x = ["ECheckType",28,e,t]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.EMeta = function(s,e) { var $x = ["EMeta",29,s,e]; $x.__enum__ = haxe.macro.ExprDef; $x.toString = $estr; return $x; };
haxe.macro.ExprDef.__empty_constructs__ = [haxe.macro.ExprDef.EBreak,haxe.macro.ExprDef.EContinue];
haxe.macro.ComplexType = $hxClasses["haxe.macro.ComplexType"] = { __ename__ : ["haxe","macro","ComplexType"], __constructs__ : ["TPath","TFunction","TAnonymous","TParent","TExtend","TOptional"] };
haxe.macro.ComplexType.TPath = function(p) { var $x = ["TPath",0,p]; $x.__enum__ = haxe.macro.ComplexType; $x.toString = $estr; return $x; };
haxe.macro.ComplexType.TFunction = function(args,ret) { var $x = ["TFunction",1,args,ret]; $x.__enum__ = haxe.macro.ComplexType; $x.toString = $estr; return $x; };
haxe.macro.ComplexType.TAnonymous = function(fields) { var $x = ["TAnonymous",2,fields]; $x.__enum__ = haxe.macro.ComplexType; $x.toString = $estr; return $x; };
haxe.macro.ComplexType.TParent = function(t) { var $x = ["TParent",3,t]; $x.__enum__ = haxe.macro.ComplexType; $x.toString = $estr; return $x; };
haxe.macro.ComplexType.TExtend = function(p,fields) { var $x = ["TExtend",4,p,fields]; $x.__enum__ = haxe.macro.ComplexType; $x.toString = $estr; return $x; };
haxe.macro.ComplexType.TOptional = function(t) { var $x = ["TOptional",5,t]; $x.__enum__ = haxe.macro.ComplexType; $x.toString = $estr; return $x; };
haxe.macro.ComplexType.__empty_constructs__ = [];
haxe.macro.TypeParam = $hxClasses["haxe.macro.TypeParam"] = { __ename__ : ["haxe","macro","TypeParam"], __constructs__ : ["TPType","TPExpr"] };
haxe.macro.TypeParam.TPType = function(t) { var $x = ["TPType",0,t]; $x.__enum__ = haxe.macro.TypeParam; $x.toString = $estr; return $x; };
haxe.macro.TypeParam.TPExpr = function(e) { var $x = ["TPExpr",1,e]; $x.__enum__ = haxe.macro.TypeParam; $x.toString = $estr; return $x; };
haxe.macro.TypeParam.__empty_constructs__ = [];
haxe.macro.Access = $hxClasses["haxe.macro.Access"] = { __ename__ : ["haxe","macro","Access"], __constructs__ : ["APublic","APrivate","AStatic","AOverride","ADynamic","AInline","AMacro"] };
haxe.macro.Access.APublic = ["APublic",0];
haxe.macro.Access.APublic.toString = $estr;
haxe.macro.Access.APublic.__enum__ = haxe.macro.Access;
haxe.macro.Access.APrivate = ["APrivate",1];
haxe.macro.Access.APrivate.toString = $estr;
haxe.macro.Access.APrivate.__enum__ = haxe.macro.Access;
haxe.macro.Access.AStatic = ["AStatic",2];
haxe.macro.Access.AStatic.toString = $estr;
haxe.macro.Access.AStatic.__enum__ = haxe.macro.Access;
haxe.macro.Access.AOverride = ["AOverride",3];
haxe.macro.Access.AOverride.toString = $estr;
haxe.macro.Access.AOverride.__enum__ = haxe.macro.Access;
haxe.macro.Access.ADynamic = ["ADynamic",4];
haxe.macro.Access.ADynamic.toString = $estr;
haxe.macro.Access.ADynamic.__enum__ = haxe.macro.Access;
haxe.macro.Access.AInline = ["AInline",5];
haxe.macro.Access.AInline.toString = $estr;
haxe.macro.Access.AInline.__enum__ = haxe.macro.Access;
haxe.macro.Access.AMacro = ["AMacro",6];
haxe.macro.Access.AMacro.toString = $estr;
haxe.macro.Access.AMacro.__enum__ = haxe.macro.Access;
haxe.macro.Access.__empty_constructs__ = [haxe.macro.Access.APublic,haxe.macro.Access.APrivate,haxe.macro.Access.AStatic,haxe.macro.Access.AOverride,haxe.macro.Access.ADynamic,haxe.macro.Access.AInline,haxe.macro.Access.AMacro];
haxe.macro.FieldType = $hxClasses["haxe.macro.FieldType"] = { __ename__ : ["haxe","macro","FieldType"], __constructs__ : ["FVar","FFun","FProp"] };
haxe.macro.FieldType.FVar = function(t,e) { var $x = ["FVar",0,t,e]; $x.__enum__ = haxe.macro.FieldType; $x.toString = $estr; return $x; };
haxe.macro.FieldType.FFun = function(f) { var $x = ["FFun",1,f]; $x.__enum__ = haxe.macro.FieldType; $x.toString = $estr; return $x; };
haxe.macro.FieldType.FProp = function(get,set,t,e) { var $x = ["FProp",2,get,set,t,e]; $x.__enum__ = haxe.macro.FieldType; $x.toString = $estr; return $x; };
haxe.macro.FieldType.__empty_constructs__ = [];
haxe.macro.TypeDefKind = $hxClasses["haxe.macro.TypeDefKind"] = { __ename__ : ["haxe","macro","TypeDefKind"], __constructs__ : ["TDEnum","TDStructure","TDClass","TDAlias","TDAbstract"] };
haxe.macro.TypeDefKind.TDEnum = ["TDEnum",0];
haxe.macro.TypeDefKind.TDEnum.toString = $estr;
haxe.macro.TypeDefKind.TDEnum.__enum__ = haxe.macro.TypeDefKind;
haxe.macro.TypeDefKind.TDStructure = ["TDStructure",1];
haxe.macro.TypeDefKind.TDStructure.toString = $estr;
haxe.macro.TypeDefKind.TDStructure.__enum__ = haxe.macro.TypeDefKind;
haxe.macro.TypeDefKind.TDClass = function(superClass,interfaces,isInterface) { var $x = ["TDClass",2,superClass,interfaces,isInterface]; $x.__enum__ = haxe.macro.TypeDefKind; $x.toString = $estr; return $x; };
haxe.macro.TypeDefKind.TDAlias = function(t) { var $x = ["TDAlias",3,t]; $x.__enum__ = haxe.macro.TypeDefKind; $x.toString = $estr; return $x; };
haxe.macro.TypeDefKind.TDAbstract = function(tthis,from,to) { var $x = ["TDAbstract",4,tthis,from,to]; $x.__enum__ = haxe.macro.TypeDefKind; $x.toString = $estr; return $x; };
haxe.macro.TypeDefKind.__empty_constructs__ = [haxe.macro.TypeDefKind.TDEnum,haxe.macro.TypeDefKind.TDStructure];
haxe.macro.Error = function(m,p) {
	this.message = m;
	this.pos = p;
};
$hxClasses["haxe.macro.Error"] = haxe.macro.Error;
haxe.macro.Error.__name__ = ["haxe","macro","Error"];
haxe.macro.Error.prototype = {
	message: null
	,pos: null
	,toString: function() {
		return this.message;
	}
	,__class__: haxe.macro.Error
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
haxe.io.Output.LN2 = Math.log(2);
haxe.languageservices.parser.TypeType.lastUid = 0;
MainIde.main();
})();

//# sourceMappingURL=mainide.js.map