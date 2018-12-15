package;

import kha.FastFloat;

class FastComplex {
	public var re: FastFloat;
	public var im: FastFloat;

	public function new(re:FastFloat, im:FastFloat) {
		this.re = re;
		this.im = im;
	}

	public function clone(): FastComplex {
		return new FastComplex(re, im);
	}

	public static function add(lhs:FastComplex, rhs:FastComplex): FastComplex {
		return new FastComplex(lhs.re + rhs.re, lhs.im + rhs.im);
	}

	public static function sub(lhs:FastComplex, rhs:FastComplex): FastComplex {
		return new FastComplex(lhs.re - rhs.re, lhs.im - rhs.im);
	}

	public static function mul(lhs:FastComplex, rhs:FastComplex): FastComplex {
		return FastComplex(lhs.re * rhs.re - lhs.im * rhs.im, lhs.re * rhs.im + lhs.im * rhs.re);
	}

	public function abs(): Float {
		return Math.sqrt(re * re + im * im);
	}

	public inline function phi(): Float {
		return Math.atan2(im, re);
	}

	public inline function toString(): String {
		var sign = im < 0 ? "-" : "+";
        var imag = Math.abs(im);
        return '$re $sign ${imag}i';
	}
}