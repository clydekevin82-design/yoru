shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pixelated_uv = floor(SCREEN_UV * (resolution / pixel_size)) / (resolution / pixel_size);
	COLOR = texture(screen_texture, pixelated_uv);
}
