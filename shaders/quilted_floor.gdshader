shader_type spatial;
// Teal quilted bouncy floor: puffy square cushions with soft seams.
// Applied to a subdivided plane clipped to a circle; uses world XZ so cushions
// stay square regardless of mesh UVs. Up to 8 recent landings press dents.
uniform vec4 base_color : source_color = vec4(0.24, 0.76, 0.69, 1.0);
uniform vec4 seam_color : source_color = vec4(0.13, 0.55, 0.52, 1.0);
uniform float cell_size = 2.0;
// Separate uniforms (not an array) for reliable Web/Compatibility support.
// xyz = world position, w = strength 0..1
uniform vec4 dent0; uniform vec4 dent1; uniform vec4 dent2; uniform vec4 dent3;
uniform vec4 dent4; uniform vec4 dent5; uniform vec4 dent6; uniform vec4 dent7;
uniform float radius = 8.0;
uniform float dent_depth = 0.28;
varying vec3 world_pos;

float one_dent(vec2 xz, vec4 d) {
	return d.w * smoothstep(1.3, 0.0, distance(xz, d.xz));
}

float dent_at(vec2 xz) {
	float dent = one_dent(xz, dent0) + one_dent(xz, dent1) + one_dent(xz, dent2) + one_dent(xz, dent3)
		+ one_dent(xz, dent4) + one_dent(xz, dent5) + one_dent(xz, dent6) + one_dent(xz, dent7);
	return min(dent, 1.0);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Press the cushion down where someone landed (visual only).
	VERTEX.y -= dent_at(world_pos.xz) * dent_depth;
}

void fragment() {
	vec2 p = world_pos.xz / cell_size;
	vec2 f = fract(p) - 0.5;
	// Cushion height: 1 at center, 0 at seams.
	vec2 c = cos(f * 3.14159);
	float puff = c.x * c.y;
	// Fake normal from cushion gradient.
	vec2 grad = -vec2(sin(f.x * 3.14159) * c.y, c.x * sin(f.y * 3.14159)) * 0.9;
	if (length(world_pos.xz) > radius) {
		discard;
	}
	float dent = dent_at(world_pos.xz);
	// Tilt the normal along the dent slope so the hollow catches light.
	vec2 dg = vec2(dent_at(world_pos.xz + vec2(0.1, 0.0)) - dent, dent_at(world_pos.xz + vec2(0.0, 0.1)) - dent) * 10.0 * dent_depth;
	grad += dg * 2.5;
	vec3 n = normalize(vec3(grad.x, 1.0, grad.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float seam = smoothstep(0.08, 0.0, puff);
	vec3 col = mix(base_color.rgb, seam_color.rgb, seam * 0.8);
	col *= 0.88 + 0.12 * puff;
	col = mix(col, seam_color.rgb * 0.85, dent * 0.45);
	ALBEDO = col;
	ROUGHNESS = 0.8;
	SPECULAR = 0.25;
}
