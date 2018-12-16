package;

import FastComplex;
import FastComplexArray;
import FFT;
import kha.arrays.Float32Array;

class Filter {
	private var kernel: Kernel;
	private var kernel_spectrum: Kernel;

	public function new(kernel:Kernel) {
		this.kernel = kernel;
	}

	public function prep_freq_domain(data_length:Int) {
		kernel_spectrum = kernel.get_spectrum(data_length);
	}

	public function apply(data:FastComplexArray) {
		if (kernel_spectrum == null || kernel_spectrum.length != data.length) {
			prep_freq_domain(data.length);
		}
		FFT.fft(data);
		data.multElemWise(kernel_spectrum);
		FFT.ifft(data);
	}
}


class Kernel {
	public var kernel: FastComplexArray;
	public var length(get, never): Int;

	public function new(k: FastComplexArray) {
		kernel = k;
	}

	public function get_length(): Int {
		return kernel.length;
	} 

	public static function fromReal(k: Float32Array, normalize=false) {
		if (normalize) {
			normalizeReal(k);
		}
		var k_copy = new Float32Array(k.length);
		for (i in 0...k.length) {
			k_copy[i] = k[i];
		}
		return new Kernel(new FastComplexArray(k, k_copy));
	}

	public static function normalizeReal(data: Float32Array) {
		var s = 0.0;
		for (i in 0...data.length) {
			s += data[i];
		}
		for (i in 0...data.length) {
			data[i] /= s;
		}
	}

	public function padded_copy(pad_to:Int) {
		var zeros = FastComplexArray.zeros(pad_to);
		for (i in 0...Math.floor(Math.min(kernel.length, pad_to))) {
			zeros.set(i, kernel.get(i));
		}
		return new Kernel(zeros);
	}

	public function get_spectrum(pad_to:Int) {
		var padded = padded_copy(pad_to);
		FFT.fft(padded.kernel);
		return padded;
	}

	public static function hann_window_right(win_length:Float, max_freq:Int = 4096): Kernel {
		var hann_length = Math.ceil(win_length * 2 * max_freq); // for sampling theorem
		var hann = FastComplexArray.zeros(hann_length);
		for (i in 0...hann_length) {
			var h = Math.pow(Math.cos(i * Math.PI / (hann_length / 2)), 2);
			hann.set(i, new FastComplex(h, h));
		}
		return new Kernel(hann);
	}
}