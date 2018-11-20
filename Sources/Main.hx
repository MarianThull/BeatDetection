package;

import kha.System;
import Project;


class Main {
	public static function main(): Void {
		System.start({title: "Shader", width: 640, height: 480}, function (_) {
			var project = new Project();
		});
	}
}
