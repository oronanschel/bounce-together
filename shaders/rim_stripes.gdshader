shader_type spatial;
// Coral-and-cream stripes around an inflatable ring (stripes by angle in object space).
uniform vec4 color_a : source_color = vec4(0.949, 0.463, 0.420, 1.0);
uniform vec4 color_b : source_color = vec4(0.984, 0.925, 0.827, 1.0);
uniform float stripes = 16.0;
varying vec3 obj_pos;

void vertex() {
	obj_pos = VERTEX;
}

void fragment() {
	float a = atan(obj_pos.z, obj_pos.x) / 6.2831853 + 0.5;
	float s = step(0.5, fract(a * stripes * 0.5));
	ALBEDO = mix(color_a.rgb, color_b.rgb, s);
	ROUGHNESS = 0.45;
	SPECULAR = 0.4;
}
