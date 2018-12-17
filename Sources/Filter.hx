package;

import FastComplex;
import FastComplexArray;
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

	public function apply(data:FastComplexArray) {
		if (kernel_spectrum == null || kernel_spectrum.length != data.length) {
			prep_freq_domain(data.length);
		}
		FFT.fft(data);
		data.multElemWise(kernel_spectrum);
		FFT.ifft(data);
	}

	public function apply_on_freq(freq_data:FastComplexArray) {
		if (kernel_spectrum == null || kernel_spectrum.length != freq_data.length) {
			prep_freq_domain(freq_data.length);
		}
		freq_data.multElemWise(kernel_spectrum);
	}

	public static function hann_window_right(win_length:Float, max_freq:Int = 44100): Filter {
		var kernel = Kernel.hann_window_right(win_length, max_freq);
		return new Filter(kernel);
	}

	public static function comb_filter(bpm:Float, samplerate:Int, pulses:Int=3): Filter {
		var kernel = Kernel.comb_kernel(bpm, samplerate, pulses);
		return new Filter(kernel);
	}
}


@:forward(length)
abstract Kernel(FastComplexArray) from FastComplexArray to FastComplexArray {
	public function new(k: FastComplexArray) {
		this = k;
	}

	public static function fromReal(k: Array<Float>, normalize=false) {
		if (normalize) {
			normalizeReal(k);
		}
		var k_copy = new Array<Float>();
		for (i in 0...k.length) {
			k_copy.push(k[i]);
		}
		return new Kernel(new FastComplexArray(k, k_copy));
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
		var zeros = FastComplexArray.zeros(pad_to);
		for (i in 0...Math.floor(Math.min(this.length, pad_to))) {
			zeros[i] = this[i];
		}
		return zeros;
	}

	public inline function get_spectrum(pad_to:Int) {
		var padded = padded_copy(pad_to);
		FFT.fft(padded);
		return padded;
	}

	public static function hann_window_right(win_length:Float, max_freq:Int = 44100): Kernel {
		var hann_length = Math.ceil(win_length * max_freq); // for sampling theorem
		var hann = FastComplexArray.zeros(hann_length);
		for (i in 0...hann_length) {
			var h = Math.pow(Math.cos(i * Math.PI / (hann_length * 2)), 2);
			hann[i] = new FastComplex(h, h);
		}
		return hann;
	}

	public static function comb_kernel(bpm:Float, samplerate:Int, pulses:Int=3): Kernel {
		var step = Math.floor(60 * samplerate / bpm);
		var k = new Array<Float>();

		for (i in 0...step * pulses) {
			if (i % step == 0) {
				k.push(1);
			}
			else {
				k.push(0);
			}
		}

		return Kernel.fromReal(k);
	}
}