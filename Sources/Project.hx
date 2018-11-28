package;

import kha.Assets;
import kha.Color;
import kha.Framebuffer;
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
	private var maxBeatDist = 0.5;
	private var distLoc: ConstantLocation;
	private var sampleSound: Sound;
	private var sampleBytes: Bytes;
	private var beatDetection: BeatDetection;
	
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
		});

		// var s = Assets.sounds;
		// var b = Assets.blobs;
		// trace(b);

		
		// debugBeatDetection();
		// debugffts();
		debugfilter();

		Scheduler.addTimeTask(update, 0, 1 / 60);
		System.notifyOnFrames(render);
	}

	private function debugBeatDetection() {
		sampleSound = Assets.sounds.KingOfTheDesert;
		if (sampleSound != null && sampleSound.uncompressedData != null) {
			trace("Using Sound asset.");
			beatDetection = new BeatDetection(sampleSound.uncompressedData);
		}
		else {
			var sampleBlob = Assets.blobs.KingOfTheDesert_ogg_blob;
			if (sampleBlob != null) {
				trace("Using Blob asset.");
				sampleBytes = sampleBlob.toBytes();
				beatDetection = new BeatDetection(uncompressOggBytes(sampleBytes));
			}
			else {
				trace("Using dummie data.");
				var data = new kha.arrays.Float32Array(20 * 44100);
				beatDetection = new BeatDetection(data);
			}
			
		}
	}

	private static function debugffts(): Void {
		// test fft
		var testData = new Array<Float>();
		for (i in 0...1024) {
			testData.push(i % 2 == 0 ? -1.0 : 1.0);
		}
		var t0 = Scheduler.realTime();
		var results = FFT.realfft(testData, false);
		var t = Scheduler.realTime() - t0;
		var l = testData.length;
		trace('$t seconds for $l elements');
		var x = results[0];
	}

	private static function debugfilter(): Void {
		var testData = ComplexArray.zeros(16);
		for (i in 0...testData.length) {
			testData[i] = new Complex((i % 2) * 10.0, ((i + 1) % 2) * 10.0);
		}
		var kernel = Kernel.fromReal([0.5, 1.0, 0.5], true);
		var filter = new Filter(kernel);
		var filtered = filter.apply(testData);
		return;
	}

	private static function uncompressOggBytes(compressedData:Bytes): kha.arrays.Float32Array {
		var uncompressedData: kha.arrays.Float32Array;

		var output = new BytesOutput();
		var header = Reader.readAll(compressedData, output, true);
		var soundBytes = output.getBytes();
		var count = Std.int(soundBytes.length / 4);
		if (header.channel == 1) {
			uncompressedData = new kha.arrays.Float32Array(count * 2);
			for (i in 0...count) {
				uncompressedData[i * 2 + 0] = soundBytes.getFloat(i * 4);
				uncompressedData[i * 2 + 1] = soundBytes.getFloat(i * 4);
			}
		}
		else {
			uncompressedData = new kha.arrays.Float32Array(count);
			for (i in 0...count) {
				uncompressedData[i] = soundBytes.getFloat(i * 4);
			}
		}

		return uncompressedData;
	}

	private function update(): Void {
		var time = Scheduler.realTime();
		beatDist = 1.0 - Math.sin(5 * time);
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
	}
}
