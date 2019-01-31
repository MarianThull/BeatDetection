package;

import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.arrays.Float32Array;
import kha.graphics4.ConstantLocation;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.Scheduler;
import kha.Shaders;
import kha.System;
import kha.Sound;
import kha.Blob;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import kha.audio2.ogg.vorbis.Reader;

import FFT;
import BeatDetection;
import Complex;
import ComplexArray;
import Filter;

class Project {
	private var pipeline: PipelineState;
	private var vertices: VertexBuffer;
	private var indices: IndexBuffer;
	private var beatDist = 0.0;
	private var maxBeatDist = 0.2;
	private var soundLag = 0.0;
	private var distLoc: ConstantLocation;
	private var sampleSound: Sound;
	private var sampleBytes: Bytes;
	private var beatDetection: BeatDetection;
	private var audioChannel: kha.audio1.AudioChannel;
	private var sampleRate = 44100;
	// used to stay in sync with playback
	private var previousFrameTime:Float;
	private var lastReportedPlayheadPosition:Float;
	private var songTime:Float;
	
	public function new(): Void {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		
		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Shaders.shader_vert;
		pipeline.fragmentShader = Shaders.shader_frag;
		pipeline.compile();

		distLoc = pipeline.getConstantLocation("beatDist");
		
		vertices = new VertexBuffer(3, structure, Usage.StaticUsage);
		var v = vertices.lock();
		v.set(0, -1); v.set(1, -1); v.set(2, 0.5);
		v.set(3,  1); v.set(4, -1); v.set(5, 0.5);
		v.set(6, -1); v.set(7,  1); v.set(8, 0.5);
		vertices.unlock();
		
		indices = new IndexBuffer(3, Usage.StaticUsage);
		var i = indices.lock();
		i[0] = 0; i[1] = 1; i[2] = 2;
		indices.unlock();
		
		Assets.loadEverything(function():Void {
			// var s = Assets.sounds;
			// var b = Assets.blobs;
			// trace(b);

			
			debugBeatDetection();
			// debugffts();
			// debugfilter();

			Scheduler.addTimeTask(update, 0, 1 / 60);
			System.notifyOnFrames(render);

			startSong();
		});
	}

	private function debugBeatDetection() {
		// sampleSound = Assets.sounds.KingOfTheDesert;
		// var bpm_override = 134.0;

		sampleSound = Assets.sounds.bpm83; // bpm: 82.95, offset: 0.025
		var bpm_override = 82.99;
		var offset_override = 0.027;

		// sampleSound = Assets.sounds.bpm120;
		// var bpm_override = 120.01;

		// sampleSound = Assets.sounds.bpm204;
		// var bpm_override = 102.01;

		// sampleSound = Assets.sounds.War; // 137.01
		// var bpm_override = 137.01;
		
		// sampleSound = Assets.sounds.LeeRosevere_ImGoingForACoffee;  // by Lee Rosevere (https://creativecommons.org/licenses/by/4.0/)
		// var bpm_override = 89.02;
		// var offset_override = 0.81;

		if (sampleSound != null && sampleSound.uncompressedData != null) {
			trace("Using Sound asset.");
			beatDetection = new BeatDetection(sampleSound.uncompressedData, sampleRate, bpm_override, offset_override);
		}
		
		else {
			trace("Using dummie data.");
			var data = new Float32Array(20 * 44100);
			beatDetection = new BeatDetection(data, 44100, bpm_override, offset_override);
		}
	}

	private static function debugffts(): Void {
		// test fft
		var testData = new Array<Float>();
		for (i in 0...8) {
			testData.push(i == 1 ? 1.0 : 0.0);
		}
		var t0 = Scheduler.realTime();
		FFT.realfft(testData, false);
		var t = Scheduler.realTime() - t0;
		var l = testData.length;
		trace('$t seconds for $l elements');
		var x = testData[0];
	}

	private static function debugfilter(): Void {
		var testData = FastComplexArray.zeros(16);
		for (i in 0...testData.length) {
			testData[i] = new FastComplex((i % 2) * 10.0, ((i + 1) % 2) * 10.0);
		}
		var example = [0.5, 1.0, 0.5];
		var kernel = Kernel.fromReal(example, true);
		var kernel2 = Kernel.hann_window_right(0.4);
		var filter = new Filter(kernel);
		var filter2 = new Filter(kernel2);
		filter2.prep_freq_domain(8192);
		filter.apply(testData);
		return;
	}

	private static function uncompressOggBytes(compressedData:Bytes): kha.arrays.Float32Array {
		var uncompressedData: Float32Array;

		var output = new BytesOutput();
		var header = Reader.readAll(compressedData, output, true);
		var soundBytes = output.getBytes();
		var count = Std.int(soundBytes.length / 4);
		if (header.channel == 1) {
			uncompressedData = new Float32Array(count * 2);
			for (i in 0...count) {
				uncompressedData[i * 2 + 0] = soundBytes.getFloat(i * 4);
				uncompressedData[i * 2 + 1] = soundBytes.getFloat(i * 4);
			}
		}
		else {
			uncompressedData = new Float32Array(count);
			for (i in 0...count) {
				uncompressedData[i] = soundBytes.getFloat(i * 4);
			}
		}

		return uncompressedData;
	}

	private function startSong() {
		previousFrameTime = Scheduler.realTime();
		lastReportedPlayheadPosition = 0;
		songTime = 0;
		audioChannel = kha.audio2.Audio1.play(sampleSound);		
	}

	private function update(): Void {
		var now = Scheduler.realTime();
		var pos = audioChannel.position;
		songTime += now - previousFrameTime;
		previousFrameTime = now;
		if (pos != lastReportedPlayheadPosition) {
			songTime = (songTime + pos) / 2;
			lastReportedPlayheadPosition = pos;
		}

		beatDist = Math.abs(beatDetection.getBeatDist(songTime - soundLag));
		if (beatDist > maxBeatDist) {
			beatDist = 1.0;
		}
		else {
			beatDist /= maxBeatDist;
		}
	}
	
	private function render(frames: Array<Framebuffer>): Void {
		var g = frames[0].g4;
		g.begin();
		g.clear(Color.Black);
		g.setPipeline(pipeline);
		g.setFloat(distLoc, beatDist);
		g.setVertexBuffer(vertices);
		g.setIndexBuffer(indices);
		g.drawIndexedVertices();
		g.end();

		// beatDetection.graph.render(frames[0]);
	}
}
