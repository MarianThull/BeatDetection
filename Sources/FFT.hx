package;

import FastComplex;
import FastComplexArray;
import kha.arrays.Float32Array;

class FFT {
	public static var timesCalled = 0;
	public static function fft(data:FastComplexArray, inverse:Bool = false) {
		timesCalled += 1;

		var n = data.length;

		var wStep = new FastComplex(0.0, 0.0);
		var wActual = new FastComplex(0.0, 0.0);
		var tmp = new FastComplex(0.0, 0.0);
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
					tmp = data.get(i);
					data.set(i, FastComplex.add(data.get(i), data.get(k)));
					data.set(k, FastComplex.sub(tmp, data.get(k)));
					data.set(k, FastComplex.mul(data.get(k), wActual));

					i += 2 * butterflySize;
				}
				wActual = FastComplex.mul(wActual, wStep);
			}

			butterflySize = Math.floor(butterflySize / 2);
		}

		// bit reversal
		j = 0;
		for (i in 0...n) {
			if (j > i) {
				tmp = data.get(i);
				data.set(i, data.get(j));
				data.set(j, tmp);
			}
			k = Math.floor(n / 2);
			while (k >= 2 && j >= k) {
				j -= k;
				k = Math.floor(k / 2);
			}
			j += k;
		}

		if (inverse) {
			data.elementDiv(n);
		}
	}

	public static function ifft(data:FastComplexArray) {
		fft(data, true);
	}

	public static function realfft(reData:Float32Array, inverse:Bool = false): Float32Array {
		var im = new Float32Array(reData.length);
		for (i in 0...reData.length) {
			im[i] = 0;
		}
		var data = new FastComplexArray(reData, im);
		fft(data, inverse);
		return data.re;
	}

	public static function realifft(reData:Float32Array): Float32Array {
		return realfft(reData, true);
	}
}
