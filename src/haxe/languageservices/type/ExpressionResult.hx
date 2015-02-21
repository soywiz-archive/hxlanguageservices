package haxe.languageservices.type;

class ExpressionResult {
    public var type:SpecificHaxeType;
    public var hasValue:Bool;
    public var value:Dynamic;

    private function new(type:SpecificHaxeType, hasValue:Bool, value:Dynamic) {
        this.type = type;
        this.hasValue = hasValue;
        this.value = value;
    }

    public function toString() {
        if (hasValue) {
            if (Std.is(value, String)) return '$type = "$value"';
            return '$type = $value';
        }
        return '$type';
    }

    static public function unify(types:HaxeTypes, items:Array<ExpressionResult>):ExpressionResult {
        if (items.length == 0) return withoutValue(types.specTypeDynamic);
        if (items.length == 1) return items[0];
        return unify2(types, items[0], unify(types, items.slice(1)));
    }

    static public function unify2(types:HaxeTypes, a:ExpressionResult, b:ExpressionResult):ExpressionResult {
        if (a.type == b.type && a.hasValue == b.hasValue && a.value == b.value) return a;
        if (a.type == b.type) return withoutValue(a.type);
        return withoutValue(a.type.type.types.unify([a.type, b.type]));
    }

    static public function withoutValue(type:SpecificHaxeType):ExpressionResult return new ExpressionResult(type, false, null);
    static public function withValue(type:SpecificHaxeType, value:Dynamic):ExpressionResult return new ExpressionResult(type, true, value);
}
