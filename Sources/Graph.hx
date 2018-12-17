package;

import kha.Color;
import kha.Framebuffer;

class Graph {
	private var subgraphs: Array<Subgraph>;

	public function new() {
		subgraphs = new Array<Subgraph>();
	}

	public function add_subgraph(sg:Subgraph) {
		subgraphs.push(sg);
	}

	public function render(frame: Framebuffer) {
		for (sg in subgraphs) {
			sg.render(frame);
		}
	}
}

class Subgraph {
	private var x: Float;
	private var y: Float;
	private var width: Float;
	private var height: Float;
	private var data: Array<Float>;
	private var dataTransformed: Array<Array<Float>>;
	private var yFactor: Float;
	private var yOffset: Float;
	private var xFactor: Float;
	private var n: Int;

	public function new(data:Array<Float>, x:Float, y:Float, width:Float, height:Float, maxY:Float) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.data = data;
		yFactor = height / (2 * maxY);
		yOffset = height / 2;
		n = data.length;
		xFactor = width / n;

		dataTransformed = new Array<Array<Float>>();
		for (i in 0...n) {
			dataTransformed.push([i * xFactor + x, -data[i] * yFactor + yOffset + y]);
		}
	}

	public function render(frame:Framebuffer) {
		var g = frame.g2;
		g.begin(false);
		g.color = Color.White;
		g.fillRect(x, y, width, height);
		g.color = Color.Black;
		g.drawRect(x, y, width, height);

		g.color = Color.Blue;
		for (i in 0...n-1) {
			g.drawLine(dataTransformed[i][0], dataTransformed[i][1],
				dataTransformed[i + 1][0], dataTransformed[i + 1][1]);
		}
		g.color = Color.White;

		g.end();
	}
}