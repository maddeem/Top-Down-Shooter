shader_type canvas_item;
global uniform sampler2D CreepData : filter_nearest;
global uniform sampler2D FogDataLocal : filter_nearest;
global uniform sampler2D CreepDataIn : filter_nearest;
global uniform vec4 FogExploredColor;
const float fade = 0.016 * 4.0;

void fragment() {
	vec4 s1 = texture(CreepData,UV);
	vec4 s2 = texture(FogDataLocal,UV);
	vec3 s3 = texture(CreepDataIn,UV).rgb;
	float visible = float(s2.a < FogExploredColor.a);
	if (s3.r == 1.0){
		float alpha = min(1.0,s1.a + fade);
		float g = mix(s1.g, 1, float(visible == 1.0 || s1.g > 0.0));
		COLOR = vec4(0,g,visible,alpha);
	}else{
		float alpha = max(0.0, s1.a - fade);
		float visibleAlpha = mix(alpha, 0.0, float(alpha == 0.0 || s1.b == 0.0));
		float g = mix(s1.g, visibleAlpha, float(visible == 1.0));
		COLOR = vec4(mix(s1.r, 0.0, float(visible != 1.0)), g, visible, mix(s1.a, visibleAlpha, float(visible == 1.0)));
	}
}
