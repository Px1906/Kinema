shader_type canvas_item;

uniform vec4 flag_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float flag_uv_limit : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (UV.y < flag_uv_limit) {
		COLOR = vec4(flag_color.rgb, tex.a);
	} else {
		COLOR = tex;
	}
}
