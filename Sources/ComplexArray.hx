package;

import Complex;

@:forward(length)
abstract ComplexArray(Array<Complex>) {
	public inline function new(re:Array<Float>, im:Array<Float>) {
		this = new Array<Complex>();
		for (i in 0...re.length) {
			this.push(new Complex(re[i], im[i]));
		}
	}

	public static function zeros(size:Int) {
		var real = new Array<Float>();
		var imag = new Array<Float>();
		for (i in 0...size) {
			real.push(0.0);
			imag.push(0.0);
		}
		return new ComplexArray(real, imag);
	}

	public inline function elementDiv(x:Float) {
		for (i in 0...this.length) {
			this[i].re /= x;
			this[i].im /= x;
		}
	}

	@:arrayAccess
	public inline function get(key:Int) {
		return this[key].clone();
	}

	@:arrayAccess
	public inline function arrayWrite(key:Int, c:Complex):Complex {
		this[key] = c;
		return c;
	}

	public inline function getReal(): Array<Float> {
		var re = new Array<Float>();
		for (c in this) {
			re.push(c.re);
		}
		return re;
	}

	public inline function getImaginary(): Array<Float> {
		var im = new Array<Float>();
		for (c in this) {
			im.push(c.im);
		}
		return im;
	}

	public inline function clone() {
		return new ComplexArray(getReal(), getImaginary());
	}

	public inline function multElemWise(other:ComplexArray): ComplexArray {
		var result = zeros(this.length);
		for (i in 0...this.length) {
			result[i] = new Complex(this[i].re * other[i].re, this[i].im * other[i].im);
		}
		return result;
	}

	public inline function fullWaveRectify() {
		for (i in 0...this.length) {
			this[i].re = Math.abs(this[i].re);
			this[i].im = Math.abs(this[i].im);
		}
	}

	public inline function diff_rect() {
		// differentiate in half wave rectify in one step
		var result = zeros(this.length);
		for (i in 1...this.length) {
			var delta_re = this[i].re - this[i - 1].re;
			var delta_im = this[i].im - this[i - 1].im;
			result[i] = new Complex(Math.max(0, delta_re), Math.max(0, delta_im));
		}

		return result;
	}
}