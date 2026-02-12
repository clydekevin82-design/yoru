shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 2.0;
uniform float sketch_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.2, 0.18, 0.16, 1.0);
uniform vec4 paper_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float time_scale : hint_range(0.0, 2.0) = 0.45;

float hash(vec2 p){
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pixelated_uv = floor(SCREEN_UV * (resolution / pixel_size)) / (resolution / pixel_size);
	vec4 base = texture(screen_texture, pixelated_uv);

	float lum = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	float hatch_a = step(0.34, fract((UV.x + UV.y + TIME * 0.03 * time_scale) * 110.0));
	float hatch_b = step(0.42, fract((UV.x - UV.y - TIME * 0.02 * time_scale) * 95.0));
	float hatch = 1.0 - (hatch_a * hatch_b);
	float edge = smoothstep(0.1, 0.8, 1.0 - lum);
	float grain = (hash(UV * resolution * 0.25 + TIME * time_scale) - 0.5) * 0.05;

	vec3 sketch_base = mix(base.rgb, paper_tint.rgb, 0.45);
	vec3 inked = mix(sketch_base, ink_color.rgb, hatch * edge * sketch_strength);
	inked += grain * sketch_strength;

	COLOR = vec4(mix(base.rgb, inked, sketch_strength), base.a);
}
