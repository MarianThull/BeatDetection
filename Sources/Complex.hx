package;

abstract Complex(Array<Float>) from Array<Float> {
	public inline function new(re:Float, im:Float) {
		this = new Array<Float>();
		this.push(re);
		this.push(im);
	}

	public var re(get, set): Float;

	public inline function get_re(): Float {
		return this[0];
	}

	public inline function set_re(re:Float): Float {
		this[0] = re;
		return re;
	}

	public var im(get, set): Float;

	public inline function get_im(): Float {
		return this[1];
	}

	public inline function set_im(im:Float): Float {
		this[1] = im;
		return im;
	}

	public function clone(): Complex {
		return new Complex(re, im);
	}

	@:op(A += B)
	public inline function addassign(rhs:Complex): Complex {
		re += rhs.re;
		im += rhs.im;
		return this;
	}

	@:op(A + B)
	public static function add(lhs:Complex, rhs:Complex): Complex {
		var tmp = lhs.clone();
		tmp += rhs;
		return tmp;
	}

	@:op(A -= B)
	public inline function subassign(rhs:Complex): Complex {
		re -= rhs.re;
		im -= rhs.im;
		return this;
	}

	@:op(A - B)
	public static function sub(lhs:Complex, rhs:Complex): Complex {
		var tmp = lhs.clone();
		tmp -= rhs;
		return tmp;
	}

	@:op(A *= B)
	public inline function mulassign(rhs:Complex): Complex {
		var reCpy = re;
		re = re * rhs.re - im * rhs.im;
		im = reCpy * rhs.im + im * rhs.re;
		return this;
	}

	@:op(A * B)
	public static function mul(lhs:Complex, rhs:Complex): Complex {
		var tmp = lhs.clone();
		tmp *= rhs;
		return tmp;
	}

	public inline function abs(): Float {
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