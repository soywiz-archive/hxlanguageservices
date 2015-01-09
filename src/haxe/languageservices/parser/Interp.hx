package haxe.languageservices.parser;

import haxe.languageservices.parser.Expr.Error;
import haxe.languageservices.parser.Expr.ErrorDef;

private enum Stop {
	SBreak;
	SContinue;
	SReturn( v : Dynamic );
}

class Interp {
	public var variables : Map<String,Dynamic>;
	var locals : Map<String,{ r : Dynamic }>;
	var binops : Map<String, Expr -> Expr -> Dynamic >;

	var depth : Int;
	var declared : Array<{ n : String, old : { r : Dynamic } }>;

	var curExpr : Expr;

	public function new() {
		variables = new Map<String,Dynamic>();
		locals = new Map();
		variables.set("null",null);
		variables.set("true",true);
		variables.set("false",false);
		variables.set("trace",function(e) haxe.Log.trace(Std.string(e),cast { fileName : "hscript", lineNumber : 0 }));
		initOps();
	}

	function initOps() {
		var me = this;
		binops = new Map();
		binops.set("+",function(e1,e2) return me.expr(e1) + me.expr(e2));
		binops.set("-",function(e1,e2) return me.expr(e1) - me.expr(e2));
		binops.set("*",function(e1,e2) return me.expr(e1) * me.expr(e2));
		binops.set("/",function(e1,e2) return me.expr(e1) / me.expr(e2));
		binops.set("%",function(e1,e2) return me.expr(e1) % me.expr(e2));
		binops.set("&",function(e1,e2) return me.expr(e1) & me.expr(e2));
		binops.set("|",function(e1,e2) return me.expr(e1) | me.expr(e2));
		binops.set("^",function(e1,e2) return me.expr(e1) ^ me.expr(e2));
		binops.set("<<",function(e1,e2) return me.expr(e1) << me.expr(e2));
		binops.set(">>",function(e1,e2) return me.expr(e1) >> me.expr(e2));
		binops.set(">>>",function(e1,e2) return me.expr(e1) >>> me.expr(e2));
		binops.set("==",function(e1,e2) return me.expr(e1) == me.expr(e2));
		binops.set("!=",function(e1,e2) return me.expr(e1) != me.expr(e2));
		binops.set(">=",function(e1,e2) return me.expr(e1) >= me.expr(e2));
		binops.set("<=",function(e1,e2) return me.expr(e1) <= me.expr(e2));
		binops.set(">",function(e1,e2) return me.expr(e1) > me.expr(e2));
		binops.set("<",function(e1,e2) return me.expr(e1) < me.expr(e2));
		binops.set("||",function(e1,e2) return me.expr(e1) == true || me.expr(e2) == true);
		binops.set("&&",function(e1,e2) return me.expr(e1) == true && me.expr(e2) == true);
		binops.set("=",assign);
		binops.set("...",function(e1,e2) return new IntIterator(me.expr(e1),me.expr(e2)));
		assignOp("+=",function(v1:Dynamic,v2:Dynamic) return v1 + v2);
		assignOp("-=",function(v1:Float,v2:Float) return v1 - v2);
		assignOp("*=",function(v1:Float,v2:Float) return v1 * v2);
		assignOp("/=",function(v1:Float,v2:Float) return v1 / v2);
		assignOp("%=",function(v1:Float,v2:Float) return v1 % v2);
		assignOp("&=",function(v1,v2) return v1 & v2);
		assignOp("|=",function(v1,v2) return v1 | v2);
		assignOp("^=",function(v1,v2) return v1 ^ v2);
		assignOp("<<=",function(v1,v2) return v1 << v2);
		assignOp(">>=",function(v1,v2) return v1 >> v2);
		assignOp(">>>=",function(v1,v2) return v1 >>> v2);
	}

	function assign( e1 : Expr, e2 : Expr ) : Dynamic {
		var v = expr(e2);
		switch( edef(e1) ) {
		case EIdent(id):
			var l = locals.get(id);
			if( l == null )
				variables.set(id,v)
			else
				l.r = v;
		case EField(e,f):
			v = set(expr(e),f,v);
		case EArray(e,index):
			expr(e)[expr(index)] = v;
		default:
			error(EInvalidOp("="));
		}
		return v;
	}

	function assignOp( op, fop : Dynamic -> Dynamic -> Dynamic ) {
		var me = this;
		binops.set(op,function(e1,e2) return me.evalAssignOp(op,fop,e1,e2));
	}

	function evalAssignOp(op,fop,e1,e2) : Dynamic {
		var v;
		switch( edef(e1) ) {
		case EIdent(id):
			var l = locals.get(id);
			v = fop(expr(e1),expr(e2));
			if( l == null )
				variables.set(id,v)
			else
				l.r = v;
		case EField(e,f):
			var obj = expr(e);
			v = fop(get(obj,f),expr(e2));
			v = set(obj,f,v);
		case EArray(e,index):
			var arr = expr(e);
			var index = expr(index);
			v = fop(arr[index],expr(e2));
			arr[index] = v;
		default:
			return error(EInvalidOp(op));
		}
		return v;
	}

	function increment( e : Expr, prefix : Bool, delta : Int ) : Dynamic {
		curExpr = e;
		var e = e.e;
		switch(e) {
		case EIdent(id):
			var l = locals.get(id);
			var v : Dynamic = (l == null) ? variables.get(id) : l.r;
			if( prefix ) {
				v += delta;
				if( l == null ) variables.set(id,v) else l.r = v;
			} else
				if( l == null ) variables.set(id,v + delta) else l.r = v + delta;
			return v;
		case EField(e,f):
			var obj = expr(e);
			var v : Dynamic = get(obj,f);
			if( prefix ) {
				v += delta;
				set(obj,f,v);
			} else
				set(obj,f,v + delta);
			return v;
		case EArray(e,index):
			var arr = expr(e);
			var index = expr(index);
			var v = arr[index];
			if( prefix ) {
				v += delta;
				arr[index] = v;
			} else
				arr[index] = v + delta;
			return v;
		default:
			return error(EInvalidOp((delta > 0)?"++":"--"));
		}
	}

	public function execute( expr : Expr ) : Dynamic {
		depth = 0;
		locals = new Map();
		declared = new Array();
		return exprReturn(expr);
	}

	function exprReturn(e) : Dynamic {
		try {
			return expr(e);
		} catch( e : Stop ) {
			switch( e ) {
			case SBreak: throw "Invalid break";
			case SContinue: throw "Invalid continue";
			case SReturn(v): return v;
			}
		}
		return null;
	}

	function duplicate<T>( h : Map < String, T > ) {
		var h2 = new Map();
		for( k in h.keys() )
			h2.set(k,h.get(k));
		return h2;
	}

	function restore( old : Int ) {
		while( declared.length > old ) {
			var d = declared.pop();
			locals.set(d.n,d.old);
		}
	}

	inline function edef( e : Expr ) {
		return e.e;
	}

	inline function error(e : ErrorDef ) : Dynamic {
		throw new Error(e, curExpr.pmin, curExpr.pmax);
		return null;
	}

	function resolve( id : String ) : Dynamic {
		var l = locals.get(id);
		if( l != null )
			return l.r;
		var v = variables.get(id);
		if( v == null && !variables.exists(id) )
			error(EUnknownVariable(id));
		return v;
	}

	public function expr( e : Expr ) : Dynamic {
		curExpr = e;
		var e = e.e;
		switch( e ) {
		case EConst(c):
			switch( c ) {
			case CInt(v): return v;
			case CFloat(f): return f;
			case CString(s): return s;
			}
		case EIdent(id):
			return resolve(id);
		case EVar(n,_,e):
			declared.push({ n : n, old : locals.get(n) });
			locals.set(n,{ r : (e == null)?null:expr(e) });
			return null;
		case EParent(e):
			return expr(e);
		case EBlock(exprs):
			var old = declared.length;
			var v = null;
			for( e in exprs )
				v = expr(e);
			restore(old);
			return v;
		case EField(e,f):
			return get(expr(e),f);
		case EBinop(op,e1,e2):
			var fop = binops.get(op);
			if( fop == null ) error(EInvalidOp(op));
			return fop(e1,e2);
		case EUnop(op,prefix,e):
			switch(op) {
			case "!":
				return expr(e) != true;
			case "-":
				return -expr(e);
			case "++":
				return increment(e,prefix,1);
			case "--":
				return increment(e,prefix,-1);
			case "~":
				return ~expr(e);
			default:
				error(EInvalidOp(op));
			}
		case ECall(e,params):
			var args = new Array();
			for( p in params )
				args.push(expr(p));

			switch( edef(e) ) {
			case EField(e,f):
				var obj = expr(e);
				if( obj == null ) error(EInvalidAccess(f));
				return fcall(obj,f,args);
			default:
				return call(null,expr(e),args);
			}
		case EIf(econd,e1,e2):
			return if( expr(econd) == true ) expr(e1) else if( e2 == null ) null else expr(e2);
		case EWhile(econd,e):
			whileLoop(econd,e);
			return null;
		case EFor(v,it,e):
			forLoop(v,it,e);
			return null;
		case EBreak:
			throw SBreak;
		case EContinue:
			throw SContinue;
		case EReturn(e):
			throw SReturn((e == null)?null:expr(e));
		case EFunction(params,fexpr,name,_):
			var capturedLocals = duplicate(locals);
			var me = this;
			var hasOpt = false, minParams = 0;
			for( p in params )
				if( p.opt )
					hasOpt = true;
				else
					minParams++;
			var f = function(args:Array<Dynamic>) {
				if( args.length != params.length ) {
					if( args.length < minParams ) {
						var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
						if( name != null ) str += " for function '" + name+"'";
						throw str;
					}
					// make sure mandatory args are forced
					var args2 = [];
					var extraParams = args.length - minParams;
					var pos = 0;
					for( p in params )
						if( p.opt ) {
							if( extraParams > 0 ) {
								args2.push(args[pos++]);
								extraParams--;
							} else
								args2.push(null);
						} else
							args2.push(args[pos++]);
					args = args2;
				}
				var old = me.locals, depth = me.depth;
				me.depth++;
				me.locals = me.duplicate(capturedLocals);
				for( i in 0...params.length )
					me.locals.set(params[i].name,{ r : args[i] });
				var r = null;
				try {
					r = me.exprReturn(fexpr);
				} catch( e : Dynamic ) {
					me.locals = old;
					me.depth = depth;
					throw e;
				}
				me.locals = old;
				me.depth = depth;
				return r;
			};
			var f = Reflect.makeVarArgs(f);
			if( name != null ) {
				if( depth == 0 ) {
					// global function
					variables.set(name, f);
				} else {
					// function-in-function is a local function
					declared.push( { n : name, old : locals.get(name) } );
					var ref = { r : f };
					locals.set(name, ref);
					capturedLocals.set(name, ref); // allow self-recursion
				}
			}
			return f;
		case EArrayDecl(arr):
			var a = new Array();
			for( e in arr )
				a.push(expr(e));
			return a;
		case EArray(e,index):
			return expr(e)[expr(index)];
		case ENew(cl,params):
			var a = new Array();
			for( e in params )
				a.push(expr(e));
			return cnew(cl,a);
		case EThrow(e):
			throw expr(e);
		case ETry(e,n,_,ecatch):
			var old = declared.length;
			try {
				var v : Dynamic = expr(e);
				restore(old);
				return v;
			} catch( err : Stop ) {
				throw err;
			} catch( err : Dynamic ) {
				// restore vars
				restore(old);
				// declare 'v'
				declared.push({ n : n, old : locals.get(n) });
				locals.set(n,{ r : err });
				var v : Dynamic = expr(ecatch);
				restore(old);
				return v;
			}
		case EObject(fl):
			var o = {};
			for( f in fl )
				set(o,f.name,expr(f.e));
			return o;
		case ETernary(econd,e1,e2):
			return if( expr(econd) == true ) expr(e1) else expr(e2);
		case ESwitch(e, cases, def):
			var val : Dynamic = expr(e);
			var match = false;
			for( c in cases ) {
				for( v in c.values )
					if( expr(v) == val ) {
						match = true;
						break;
					}
				if( match ) {
					val = expr(c.expr);
					break;
				}
			}
			if( !match )
				val = def == null ? null : expr(def);
			return val;
		}
		return null;
	}

	function whileLoop(econd,e) {
		var old = declared.length;
		while( expr(econd) == true ) {
			try {
				expr(e);
			} catch( err : Stop ) {
				switch(err) {
				case SContinue:
				case SBreak: break;
				case SReturn(_): throw err;
				}
			}
		}
		restore(old);
	}

	function makeIterator( v : Dynamic ) : Iterator<Dynamic> {
		try v = v.iterator() catch( e : Dynamic ) {};
		if( v.hasNext == null || v.next == null ) error(EInvalidIterator(v));
		return v;
	}

	function forLoop(n,it,e) {
		var old = declared.length;
		declared.push({ n : n, old : locals.get(n) });
		var it = makeIterator(expr(it));
		while( it.hasNext() ) {
			locals.set(n,{ r : it.next() });
			try {
				expr(e);
			} catch( err : Stop ) {
				switch( err ) {
				case SContinue:
				case SBreak: break;
				case SReturn(_): throw err;
				}
			}
		}
		restore(old);
	}

	function get( o : Dynamic, f : String ) : Dynamic {
		if( o == null ) error(EInvalidAccess(f));
		return Reflect.field(o,f);
	}

	function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
		if( o == null ) error(EInvalidAccess(f));
		Reflect.setField(o,f,v);
		return v;
	}

	function fcall( o : Dynamic, f : String, args : Array<Dynamic> ) : Dynamic {
		return call(o, Reflect.field(o, f), args);
	}

	function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
		return Reflect.callMethod(o,f,args);
	}

	function cnew( cl : String, args : Array<Dynamic> ) : Dynamic {
		var c = Type.resolveClass(cl);
		if( c == null ) c = resolve(cl);
		return Type.createInstance(c,args);
	}

}