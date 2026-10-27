shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 5.0) = 2.5;

void fragment() {
	vec2 ps = SCREEN_PIXEL_SIZE * blur_strength;
	vec4 col = vec4(0.0);

	col += texture(screen_texture, SCREEN_UV + vec2(-2.0, -2.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2(-1.0, -2.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 0.0, -2.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2(-2.0, -1.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2(-1.0, -1.0) * ps) * 0.25;
	col += texture(screen_texture, SCREEN_UV + vec2( 0.0, -1.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 1.0, -1.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2(-2.0,  0.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2(-1.0,  0.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 0.0,  0.0) * ps) * 0.25;
	col += texture(screen_texture, SCREEN_UV + vec2( 1.0,  0.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 2.0,  0.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2(-1.0,  1.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2( 0.0,  1.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 1.0,  1.0) * ps) * 0.25;
	col += texture(screen_texture, SCREEN_UV + vec2( 2.0,  1.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 0.0,  2.0) * ps) * 0.0625;
	col += texture(screen_texture, SCREEN_UV + vec2( 1.0,  2.0) * ps) * 0.125;
	col += texture(screen_texture, SCREEN_UV + vec2( 2.0,  2.0) * ps) * 0.0625;

	col /= col.a > 0.0 ? col.a : 1.0;
	col.a = 1.0;
	COLOR = col;
}
