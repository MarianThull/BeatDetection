package;

import FastComplex;
import kha.arrays.Float32Array;
import kha.FastFloat;


class FastComplexArray {
	public var re = Float32Array;
	public var im = Float32Array;
	public var length(get, null): Int;

	public function new(re:Float32Array, im:Float32Array) {
		this.re = re;
		this.im = im;
	}

	public function get_length(): Int {
		return re.length;
	} 

	public static function zeros(size:Int) {
		var real = new Float32Array(size);
		var imag = new Float32Array(size);
		for (i in 0...size) {
			real[i] = 0;
			imag[i] = 0;
		}
		return new FastComplexArray(real, imag);
	}

	public function elementDiv(x:Float) {
		for (i in 0...length) {
			re[i] /= x;
			im[i] /= x;
		}
	}

	public function get(key:Int) {
		return new FastComplex(re[key], im[key]);
	}

	public function set(key:Int, c:FastComplex) {
		re[key] = c.re;
		im[key] = c.im;
	}

	public function clone() {
		var re_new = new Float32Array(length);
		var im_new = new Float32Array(length);
		for (i in 0...length) {
			re_new[i] = re[i];
			im_new[i] = im[i];
		}
		return new FastComplexArray(re_new, im_new);
	}

	public function multElemWise(other:FastComplexArray) {
		for (i in 0...length) {
			re[i] *= other.re[i];
			im[i] *= other.im[i];
		}
	}

	public function fullWaveRectify() {
		for (i in 0...this.length) {
			re[i] = Math.abs(re[i]);
			im[i] = Math.abs(im[i]);
		}
	}

	public function diff_rect() {
		// differentiate in half wave rectify in one step
		var result = zeros(length);
		var delta_re: FastFloat;
		var delta_im: FastFloat;
		for (i in 1...length) {
			delta_re = re[i] - re[i - 1];
			delta_im = im[i] - im[i - 1];
			if (delta_re > 0) {
				result.re[i] = delta_re;
			}
			if (delta_im > 0) {
				result.im[i] = delta_im;
			}
		}
		re = result.re;
		im = result.im;
	}
}