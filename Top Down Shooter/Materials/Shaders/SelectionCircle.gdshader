shader_type spatial;
render_mode unshaded,cull_disabled;
const float half_pi = PI * 0.5;
uniform vec4 color = vec4(0,1,0,1);
uniform float width = 0.04;
void fragment() {
	vec2 uv = (UV - 0.5) * half_pi;
	float d = length(uv);
	float r = 0.775;
	float c;
	if (d<r){
		r -= width;
		c = smoothstep(r, r - 0.01,d);
	}else{
		c = smoothstep(r , r + 0.01,d);
	}
	ALBEDO = color.rgb;
	ALPHA = mix(color.a,0.0,c);
}
