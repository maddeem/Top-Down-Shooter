shader_type spatial;
render_mode unshaded,cull_disabled;
instance uniform vec4 color : source_color;
instance uniform float time = 0.0;
void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a * smoothstep(time, time + 0.1, UV.y * 2.0);
}
