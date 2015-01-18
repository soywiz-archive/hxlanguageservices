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

    static public function withoutValue(type:SpecificHaxeType):ExpressionResult return new ExpressionResult(type, false, null);
    static public function withValue(type:SpecificHaxeType, value:Dynamic):ExpressionResult return new ExpressionResult(type, true, value);
}
