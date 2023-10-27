shader_type spatial;
render_mode unshaded, depth_draw_opaque;
uniform vec3 color : source_color;
void fragment() {
	ALBEDO = color.rgb;
}
