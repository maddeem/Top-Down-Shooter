shader_type spatial;
render_mode unshaded;
global uniform vec2 FogDimensions;
global uniform sampler2D FogData;
global uniform vec2 InverseFogDimensions;

void fragment() {
	vec4 fog_sample = texture(FogData,(INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz * InverseFogDimensions - vec2(0.5));
	ALBEDO = fog_sample.rgb;
	ALPHA = fog_sample.a;
}
