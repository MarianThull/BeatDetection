package;

import FFT;
import Filter;
import ComplexArray;
import kha.Assets;
import kha.Sound;
import kha.Scheduler;
import kha.arrays.Float32Array;

class BeatDetection {
	private var bpm: Float;
	private var data: Float32Array;
	private var samplerate = 44100;
	private var samplesizeSeconds = 2.2;
	private var sampleSize: Int;
	private var bandLimits = [0, 200, 400, 800, 1600, 3200];
	private var minBPM: Float = 60;
	private var maxBPM: Float = 240;
	private var accuracies = [2]; // [2, 0.5, 0.1, 0.01];

	private static var DEBUG = true;
	private static var time0 = 0.0;
	private static var ffts0 = 0;

	public function new(data:Float32Array): Void {
		this.data = data;
		sampleSize = Math.floor(Math.pow(2, Math.ceil(Math.log(samplesizeSeconds * samplerate) / Math.log(2))));
		debug('sample size: $sampleSize');
		if (DEBUG) time0 = Scheduler.realTime();
		var sample = getSample();
		debug(timer("extract sample"));
		var bands = filterbank(sample);
		debug(timer("filterbank"));
		smoothing(bands);
		debug(timer("smoothing"));
		differentiate(bands);
		debug(timer("differentiate"));
		bpm = combFilter(bands);
		debug(timer("comb filter"));
		debug('found bpm: $bpm');
		return;
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

	private function getSample(): FastComplexArray {
		if (data != null) {
			var left = new Float32Array(sampleSize);
			var right = new Float32Array(sampleSize);

			var l = data.length;
			debug('file length: $l');
			var start_i = Math.floor(l / 2) - sampleSize; // half sampleSize but x2 for stereo
			var n = 0;
			for (i in start_i...(start_i + sampleSize)) {
				left[n] = data[i];
				right[n] = data[i + 1];
				i += 2;
				n += 1;
			}

			return new FastComplexArray(left, right);
		}
		else {
			return FastComplexArray.zeros(sampleSize);
		}
	}

	private function filterbank(sample:FastComplexArray): Array<FastComplexArray> {
		var bands = new Array<FastComplexArray>();
		var empty = FastComplexArray.zeros(sampleSize);
		FFT.fft(sample);

		var indices = new Array<Int>();
		for (limit in bandLimits) {
			indices.push(Math.floor(limit * sampleSize / samplerate));
		}
		indices.push(sampleSize);

		for (i in 0...bandLimits.length) {
			var band = empty.clone();
			for (j in indices[i]...indices[i + 1]) {
				band[j] = sample[j];
			}
			FFT.ifft(band);
			bands.push(band);
		}

		return bands;
	}

	private function smoothing(bands:Array<FastComplexArray>) {
		var hann_filter = Filter.hann_window_right(0.4, samplerate);
		for (band in bands) {
			band.fullWaveRectify();
			hann_filter.apply(band);
		}
	}

	private function differentiate(bands:Array<FastComplexArray>) {
		for (band in bands) {
			band.diff_rect();
		}
	}

	private function combFilter(bands:Array<FastComplexArray>): Float {
		for (band in bands) {
			FFT.fft(band);
		}

		var lowerBPM = minBPM;
		var upperBPM = maxBPM;
		var estBPM:Float = 0;

		for (accuracy in accuracies) {
			estBPM = combFilterRound(bands, accuracy, lowerBPM, upperBPM);
			lowerBPM = estBPM - accuracy;
			upperBPM = estBPM + accuracy;
		}

		return estBPM;
	}

	private function combFilterRound(freq_bands:Array<FastComplexArray>, accuracy:Float, startBPM:Float, stopBPM:Float): Float {
		var max_energy: Float = 0;
		var bestBPM: Float = minBPM;  // prevent errors for constant signals
		var curBPM: Float = 0;
		var energy: Float = 0;
		var filter: Filter;
		var band_copy: FastComplexArray;

		for (i in 0...Math.ceil((stopBPM - startBPM) / accuracy) + 1) {
			curBPM = startBPM + i * accuracy;
			energy = 0;
			filter = Filter.comb_filter(curBPM, samplerate);
			for (band in freq_bands) {
				band_copy = band.clone();
				filter.apply_on_freq(band_copy);
				FFT.ifft(band_copy);
				energy += band_copy.energy();
			}

			if (energy > max_energy) {
				bestBPM = curBPM;
				max_energy = energy;
			}
		}

		return bestBPM;
	}
}