package;

import FastComplex;


abstract FastComplexArray(Array<Array<Float>>) {
	public var length(get, never): Int;

	public inline function get_length(): Int {
		return this[0].length;
	} 

	public inline function new(re:Array<Float>, im:Array<Float>) {
		this = new Array<Array<Float>>();
		this.push(re);
		this.push(im);
	}

	public static function zeros(size:Int) {
		var real = new Array<Float>();
		var imag = new Array<Float>();
		for (i in 0...size) {
			real.push(0);
			imag.push(0);
		}
		return new FastComplexArray(real, imag);
	}

	public inline function elementDiv(x:Float) {
		for (i in 0...length) {
			this[0][i] /= x;
			this[1][i] /= x;
		}
	}

	@:arrayAccess
	public inline function get(key:Int) {
		return new FastComplex(this[0][key], this[1][key]);
	}

	@:arrayAccess
	public inline function arrayWrite(key:Int, c:FastComplex):FastComplex {
		this[0][key] = c.re;
		this[1][key] = c.im;
		return c;
	}

	public inline function getReal(): Array<Float> {
		return this[0];
	}

	public inline function getImaginary(): Array<Float> {
		return this[1];
	}

	public inline function clone() {
		var re_new = new Array<Float>();
		var im_new = new Array<Float>();
		for (i in 0...length) {
			re_new.push(this[0][i]);
			im_new.push(this[1][i]);
		}
		return new FastComplexArray(re_new, im_new);
	}

	public inline function slice(start:Int, stop:Int) {
		var re_new = new Array<Float>();
		var im_new = new Array<Float>();
		for (i in start...stop) {
			re_new.push(this[0][i]);
			im_new.push(this[1][i]);
		}
		return new FastComplexArray(re_new, im_new);
	}

	public inline function multElemWise(other:FastComplexArray) {
		var other_i: FastComplex;
		for (i in 0...length) {
			other_i = other[i];
			this[0][i] *= other_i.re;
			this[1][i] *= other_i.im;
		}
	}

	public inline function fullWaveRectify() {
		for (i in 0...length) {
			this[0][i] = Math.abs(this[0][i]);
			this[1][i] = Math.abs(this[1][i]);
		}
	}

	public inline function diff_rect() {
		// differentiate and half wave rectify in one step
		var result = zeros(length);
		var delta_re: Float;
		var delta_im: Float;
		for (i in 1...length) {
			delta_re = this[0][i] - this[0][i - 1];
			delta_im = this[1][i] - this[1][i - 1];
			result[i] = new FastComplex(Math.max(0, delta_re), Math.max(0, delta_im));
		}
		this[0] = result.getReal();
		this[1] = result.getImaginary();
	}

	public inline function energy() {
		var e: Float = 0;
		for (i in 0...length) {
			e += Math.pow(this[0][i], 2) + Math.pow(this[1][i], 2);
		}
		return e;
	}
}