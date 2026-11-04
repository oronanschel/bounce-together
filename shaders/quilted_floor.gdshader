shader_type spatial;
// Teal quilted bouncy floor: puffy square cushions with soft seams.
// Applied to the top cap of the arena cylinder; uses world XZ so cushions
// stay square regardless of mesh UVs. Up to 8 recent landings press dents.
uniform vec4 base_color : source_color = vec4(0.24, 0.76, 0.69, 1.0);
uniform vec4 seam_color : source_color = vec4(0.13, 0.55, 0.52, 1.0);
uniform float cell_size = 2.0;
uniform vec4 dents[8]; // xyz = world position, w = strength 0..1
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / cell_size;
	vec2 f = fract(p) - 0.5;
	// Cushion height: 1 at center, 0 at seams.
	vec2 c = cos(f * 3.14159);
	float puff = c.x * c.y;
	// Fake normal from cushion gradient.
	vec2 grad = -vec2(sin(f.x * 3.14159) * c.y, c.x * sin(f.y * 3.14159)) * 0.9;
	float dent = 0.0;
	for (int i = 0; i < 8; i++) {
		float d = distance(world_pos.xz, dents[i].xz);
		dent += dents[i].w * smoothstep(0.9, 0.0, d);
	}
	vec3 n = normalize(vec3(grad.x, 1.0, grad.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float seam = smoothstep(0.08, 0.0, puff);
	vec3 col = mix(base_color.rgb, seam_color.rgb, seam * 0.8);
	col *= 0.88 + 0.12 * puff;
	col = mix(col, seam_color.rgb * 0.8, clamp(dent, 0.0, 0.7));
	ALBEDO = col;
	ROUGHNESS = 0.8;
	SPECULAR = 0.25;
}
