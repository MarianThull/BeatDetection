package;

import Complex;
import ComplexArray;

class FFT {
	public static var timesCalled = 0;
	public static function fft(data:ComplexArray, inverse:Bool = false): ComplexArray {
		timesCalled += 1;

		var result = data.clone();
		var n = data.length;

		var wStep = new Complex(0.0, 0.0);
		var wActual = new Complex(0.0, 0.0);
		var tmp = new Complex(0.0, 0.0);
		var i:Int;
		var j:Int;
		var k:Int;
		var iSign = inverse ? 1 : -1;

		var butterflySize = Math.floor(n / 2);
		while (butterflySize > 0) {
			wStep.re = Math.cos(iSign * Math.PI / butterflySize);
			wStep.im = Math.sin(iSign * Math.PI / butterflySize);
			wActual.re = 1.0;
			wActual.im = 0.0;

			for (j in 0...butterflySize) {
				i = j;
				while (i < n) {
					k = i + butterflySize;
					tmp = result[i];
					result[i] += result[k];
					result[k] = tmp - result[k];
					result[k] *= wActual;

					i += 2 * butterflySize;
				}
				wActual *= wStep;
			}

			butterflySize = Math.floor(butterflySize / 2);
		}

		// bit reversal
		j = 0;
		for (i in 0...n) {
			if (j > i) {
				tmp = result[i];
				result[i] = result[j];
				result[j] = tmp;
			}
			k = Math.floor(n / 2);
			while (k >= 2 && j >= k) {
				j -= k;
				k = Math.floor(k / 2);
			}
			j += k;
		}

		if (inverse) {
			result.elementDiv(n);
		}

		return result;
	}

	public static function ifft(data:ComplexArray): ComplexArray {
		return fft(data, true);
	}

	public static function realfft(reData:Array<Float>, inverse:Bool = false): Array<Float> {
		var im = new Array<Float>();
		for (i in 0...reData.length) {
			im.push(0);
		}
		var data = new ComplexArray(reData, im);
		return fft(data, inverse).getReal();
	}

	public static function realifft(reData:Array<Float>): Array<Float> {
		return realfft(reData, true);
	}
}
