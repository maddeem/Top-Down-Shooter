shader_type spatial;
render_mode unshaded;
global uniform vec2 FogDimensions;
global uniform sampler2D FogData: filter_linear_mipmap_anisotropic;
const int strength = 0;

void fragment() {
	vec2 uv = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz / FogDimensions - vec2(0.5);
	vec4 fog_sample = texture(FogData,uv);
	if (fog_sample.a < 1.0){
		ALBEDO = fog_sample.rgb;
	}else{
		ALBEDO = vec3(0);
	}
	ALPHA = fog_sample.a;
}
