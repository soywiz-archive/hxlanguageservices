package hscript;

enum Const {
    CInt( v:Int );
    CFloat( f:Float );
    CString( s:String );
}

typedef Expr = {
    var e:ExprDef;
    var pmin:Int;
    var pmax:Int;
}
enum ExprDef {
    EConst( c:Const );
    EIdent( v:String );
    EVar( n:String, ?t:CType, ?e:Expr );
    EParent( e:Expr );
    EBlock( e:Array<Expr> );
    EField( e:Expr, f:String );
    EBinop( op:String, e1:Expr, e2:Expr );
    EUnop( op:String, prefix:Bool, e:Expr );
    ECall( e:Expr, params:Array<Expr> );
    EIf( cond:Expr, e1:Expr, ?e2:Expr );
    EWhile( cond:Expr, e:Expr );
    EFor( v:String, it:Expr, e:Expr );
    EBreak;
    EContinue;
    EFunction( args:Array<Argument>, e:Expr, ?name:String, ?ret:CType );
    EReturn( ?e:Expr );
    EArray( e:Expr, index:Expr );
    EArrayDecl( e:Array<Expr> );
    ENew( cl:String, params:Array<Expr> );
    EThrow( e:Expr );
    ETry( e:Expr, v:String, t:Null<CType>, ecatch:Expr );
    EObject( fl:Array<{ name:String, e:Expr }> );
    ETernary( cond:Expr, e1:Expr, e2:Expr );
    ESwitch( e:Expr, cases:Array<{ values:Array<Expr>, expr:Expr }>, ?defaultExpr:Expr);
}

typedef Argument = { name:String, ?t : CType, ?opt : Bool };

enum CType {
    CTPath( path:Array<String>, ?params:Array<CType> );
    CTFun( args:Array<CType>, ret:CType );
    CTAnon( fields:Array<{ name:String, t:CType }> );
    CTParent( t:CType );
}

class Error2 {
    public var message:String;

    public function new(message:String) { this.message = message; }
    public function toString() return 'Error($message)';
}

class Error {
    public var e:ErrorDef;
    public var pmin:Int;
    public var pmax:Int;

    public function new(e:ErrorDef, pmin:Int, pmax:Int) {
        this.e = e;
        this.pmin = pmin;
        this.pmax = pmax;
    }

    public function toString() return 'Error($e, $pmin, $pmax)';
}
enum ErrorDef {
    EInvalidChar( c:Int );
    EUnexpected( s:String );
    EUnterminatedString;
    EUnterminatedComment;
    EUnknownVariable( v:String );
    EInvalidIterator( v:String );
    EInvalidOp( op:String );
    EInvalidAccess( f:String );
}
