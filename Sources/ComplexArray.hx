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
}