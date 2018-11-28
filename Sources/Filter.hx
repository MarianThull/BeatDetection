package;

import Complex;
import ComplexArray;
import FFT;

class Filter {
	private var kernel: Kernel;
	private var kernel_spectrum: Kernel;

	public function new(kernel:Kernel) {
		this.kernel = kernel;
	}

	public function prep_freq_domain(data_length:Int) {
		kernel_spectrum = kernel.get_spectrum(data_length);
	}

	public function apply(data:ComplexArray) {
		if (kernel_spectrum == null || kernel_spectrum.length != data.length) {
			prep_freq_domain(data.length);
		}
		var data_freq = FFT.fft(data);
		var results_freq = data_freq.multElemWise(kernel_spectrum);
		return FFT.ifft(results_freq);
	}
}


@:forward(length)
abstract Kernel(ComplexArray) from ComplexArray to ComplexArray {
	public function new(k: ComplexArray) {
		this = k;
	}

	public static function fromReal(k: Array<Float>, normalize=false) {
		if (normalize) {
			normalizeReal(k);
		}
		return new Kernel(new ComplexArray(k, k.copy()));
	}

	public static function normalizeReal(data: Array<Float>) {
		var s = 0.0;
		for (i in 0...data.length) {
			s += data[i];
		}
		for (i in 0...data.length) {
			data[i] /= s;
		}
	}

	public inline function padded_copy(pad_to:Int) {
		var zeros = ComplexArray.zeros(pad_to);
		for (i in 0...Math.floor(Math.min(this.length, pad_to))) {
			zeros[i] = this[i];
		}
		return zeros;
	}

	public inline function get_spectrum(pad_to:Int) {
		var padded = padded_copy(pad_to);
		return FFT.fft(padded);
	}
}