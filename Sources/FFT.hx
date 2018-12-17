package;

import FastComplex;
import FastComplexArray;

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
					tmp = data[i];
					data[i] = FastComplex.add(data[i], data[k]);
					data[k] = FastComplex.sub(tmp, data[k]);
					data[k] = FastComplex.mul(data[k], wActual);

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
				tmp = data[i];
				data[i] = data[j];
				data[j] = tmp;
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

	public static function realfft(reData:Array<Float>, inverse:Bool = false): Array<Float> {
		var im = new Array<Float>();
		for (i in 0...reData.length) {
			im.push(0);
		}
		var data = new FastComplexArray(reData, im);
		fft(data, inverse);
		return data.getReal();
	}

	public static function realifft(reData:Array<Float>): Array<Float> {
		return realfft(reData, true);
	}
}
