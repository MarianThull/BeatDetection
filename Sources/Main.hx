package;

import kha.System;
import Project;


class Main {
	public static function main(): Void {
		System.start({title: "Shader", width: 1280, height: 720}, function (_) {
			var project = new Project();
		});
	}
}
