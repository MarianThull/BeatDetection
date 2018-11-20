package;

import FFT;
import ComplexArray;
import kha.Assets;
import kha.Sound;
import kha.Scheduler;

class BeatDetection {
	private var bpm: Float;
	private var data: kha.arrays.Float32Array;
	private var samplerate = 44100;
	private var samplesizeSeconds = 1.0; // 2.2;
	private var sampleSize: Int;
	private var numBands = 6;

	private static var DEBUG = true;
	private static var time0 = 0.0;
	private static var ffts0 = 0;

	public function new(data:kha.arrays.Float32Array): Void {
		this.data = data;
		sampleSize = Math.floor(Math.pow(2, Math.ceil(Math.log(samplesizeSeconds * samplerate) / Math.log(2))));
		debug('sample size: $sampleSize');
		if (DEBUG) time0 = Scheduler.realTime();
		var sample = getSample();
		debug(timer("extract sample"));
		var bands = filterbank(sample);
		debug(timer("filterbank"));
		bands = smoothing(bands);
		debug(timer("smoothing"));
		bands = differentiate(bands);
		debug(timer("differentiate"));
		bpm = combFilter(bands);
		debug(timer("comb filter"));
	}

	private static function timer(name:String): String {
		var time1 = Scheduler.realTime();
		var time = time1 - time0;
		time0 = time1;

		var ffts_step = FFT.timesCalled - ffts0;
		ffts0 = FFT.timesCalled;

		return 'time for "$name" ($ffts_step FFTs): $time';
	}

	private static function debug(s:String) {
		if (DEBUG) {
			trace('DEBUG --> $s');
		}
	}

	private function getSample(): ComplexArray {
		if (data != null) {
			var left = new Array<Float>();
			var right = new Array<Float>();

			var l = data.length;
			debug('file length: $l');
			var i = Math.floor(l / 2) - sampleSize; // half sampleSize but x2 for stereo
			while (left.length < sampleSize) {
				left.push(data[i]);
				right.push(data[i + 1]);
				i += 2;
			}

			return new ComplexArray(left, right);
		}
		else {
			return ComplexArray.zeros(sampleSize);
		}
	}

	private function filterbank(sample:ComplexArray): Array<ComplexArray> {
		var bands = new Array<ComplexArray>();
		var empty = ComplexArray.zeros(sampleSize);
		var freq_domain = FFT.fft(sample);
		var log_step = Math.log(sampleSize) / numBands;

		var lower_index = 0;
		var upper_index = 0;
		for (i in 0...numBands) {
			upper_index = Math.floor(Math.exp((i + 1) * log_step));

			var band = empty.clone();
			for (j in lower_index...upper_index) {
				band[j] = freq_domain[j];
			}
			bands.push(FFT.ifft(band));

			lower_index = upper_index;
		}

		return bands;
	}

	private function smoothing(bands:Array<ComplexArray>): Array<ComplexArray> {
		return new Array<ComplexArray>();
	}

	private function differentiate(bands:Array<ComplexArray>): Array<ComplexArray> {
		return new Array<ComplexArray>();
	}

	private function combFilter(bands:Array<ComplexArray>): Float {
		return 0;
	}
}