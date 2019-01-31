package;

import FFT;
import Filter;
import FastComplexArray;
import Graph;
import kha.Assets;
import kha.Sound;
import kha.Scheduler;

class BeatDetection {
	private var bpm: Float;
	private var beat_length: Float;
	private var offset_seconds: Float;
	private var offset_frames: Int;
	public var graph: Graph;
	private var graphAreas = [[0, 0, 640, 360], [0, 360, 640, 360], [640, 0, 640, 360], [640, 360, 640, 360]];
	private var displayedBand = 2;

	private var data: Array<Float>;
	private var samplerate = 4096;
	private var originalSamplerate = 48000;
	private var samplesizeSeconds = 5.0;
	private var sampleSize: Int;
	private var bandLimits = [0, 200, 400, 800, 1600, 3200];
	private var minBPM: Float = 60; // 60;
	private var maxBPM: Float = 240; // 240;
	private var accuracies = [2, 0.5, 0.1, 0.01]; // [2, 0.5, 0.1, 0.01];

	private static var DEBUG = true;
	private static var time0 = 0.0;
	private static var ffts0 = 0;

	public function new(data:kha.arrays.Float32Array, samplerate:Int, bpm_override:Float=0, offset_override:Float=0): Void {
		this.originalSamplerate = samplerate;
		this.data = new Array<Float>();
		for (f in data) {
			this.data.push(f);
		}
		graph = new Graph();

		if (DEBUG) time0 = Scheduler.realTime();

		var sample = getSample();
		debug(timer("extract sample"));
		var subData = sample.getReal().copy();
		graph.add_subgraph(new Graph.Subgraph(subData, graphAreas[0][0], graphAreas[0][1],
			graphAreas[0][2], graphAreas[0][3], 1.1));

		var bands = filterbank(sample);
		debug(timer("filterbank"));
		subData = bands[displayedBand].getReal().copy();
		graph.add_subgraph(new Graph.Subgraph(subData, graphAreas[1][0], graphAreas[1][1],
			graphAreas[1][2], graphAreas[1][3], 1.1));

		if (bpm_override != 0) {
			bpm = bpm_override;
			debug('Predefined bpm: $bpm');
		}
		else {
			var bands_copy = new Array<FastComplexArray>();
			for (band in bands) {
				bands_copy.push(band.clone());
			}

			smoothing(bands_copy);
			debug(timer("smoothing"));
			subData = bands_copy[displayedBand].getReal().copy();
			graph.add_subgraph(new Graph.Subgraph(subData, graphAreas[2][0], graphAreas[2][1],
				graphAreas[2][2], graphAreas[2][3], 1.1));

			differentiate(bands_copy);
			debug(timer("differentiate"));
			subData = bands_copy[displayedBand].getReal().copy();
			graph.add_subgraph(new Graph.Subgraph(subData, graphAreas[3][0], graphAreas[3][1],
				graphAreas[3][2], graphAreas[3][3], 1.1));

			bpm = combFilter(bands_copy);
			debug(timer("comb filter"));
		}

		beat_length = 60.0 / bpm;
		
		if (offset_override != 0) {
			offset_seconds = offset_override;
			debug('Predefined offset: $offset_seconds');
		}
		else {
			differentiate(bands);
			debug(timer("differentiate (phase alignment)"));

			offset_seconds = phaseAlign(bands);
			debug(timer("phase alignment"));
		}

		debug('BPM: $bpm');
		debug('TIME TO FIRST BEAT: $offset_seconds');
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
		sampleSize = Math.floor(Math.pow(2, Math.ceil(Math.log(samplesizeSeconds * samplerate) / Math.log(2))));
		debug('sample size: $sampleSize');
		var sampleSizeOriginal = Math.ceil(sampleSize * originalSamplerate / samplerate);
		var step:Float = originalSamplerate / samplerate;
		
		if (data != null) {
			// var left = new Array<Float>();
			// var right = new Array<Float>();
			var leftOriginal = new Array<Float>();
			var rightOriginal = new Array<Float>();

			var l = data.length;
			debug('file length: $l');
			var start_i = Math.floor(l / 2 - sampleSizeOriginal); // half sampleSize but x2 for stereo
			offset_frames = Math.floor(start_i / 2); // save for phase alignment
			var i = 0;
			while (leftOriginal.length < sampleSizeOriginal) {
				leftOriginal.push(data[start_i + i]);
				rightOriginal.push(data[start_i + i + 1]);
				i += 2;
			}
			var sampleOriginal = new FastComplexArray(leftOriginal, rightOriginal);

			// lowpass filter to prepare downsampling
			// FFT.fft(sampleOriginal);
			// var max_freq_index = Math.ceil(samplerate * sampleSizeOriginal / originalSamplerate);
			// for (i in max_freq_index...sampleSizeOriginal) {
			// 	sampleOriginal[i] = new FastComplex(0, 0);
			// }
			// FFT.ifft(sampleOriginal);

			// downsampling
			var i_inFile: Int;
			var sample = FastComplexArray.zeros(sampleSize);
			for (i in 0...sampleSize) {
				i_inFile = Math.floor(i * step);
				sample[i] = sampleOriginal[i_inFile];
			}

			return sample;
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
			filter = Filter.comb_filter(curBPM, samplerate, 5);
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

	private function phaseAlign(freq_bands:Array<FastComplexArray>): Float {
		var sig = FastComplexArray.zeros(freq_bands[0].length);
		for (band in freq_bands) {
			for (i in 0...sig.length) {
				sig[i] = FastComplex.add(sig[i], band[i]);
			}
		}
		var num_pulses = 5;
		var comb = Kernel.comb_kernel(bpm, samplerate, num_pulses);
		var pulse_length = Math.floor(comb.length / num_pulses);
		var energies = new Array<Float>();
		for (i in 0...pulse_length) {
			var sub_sig = sig.slice(i, i + comb.length);
			sub_sig.multElemWise(comb);
			energies.push(sub_sig.energy());
		}
		var best_i = 0;
		var best_e = 0.0;
		for (i in 0...energies.length) {
			if (energies[i] > best_e) {
				best_i = i;
				best_e = energies[i];
			}
		}
		
		offset_frames = (offset_frames + best_i) % pulse_length;
		return offset_frames / samplerate; // in seconds
	}

	public function getBeatDist(t:Float): Float {
		t -= offset_seconds; // align to first beat
		while (t > 0.5 * beat_length) {
			t -= beat_length;
		}
		return t;
	}
}