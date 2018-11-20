#version 450

out vec4 FragColor;

uniform float beatDist;

void main() {
	FragColor = vec4(1.0 - beatDist, 0.0, beatDist, 1.0);
}
