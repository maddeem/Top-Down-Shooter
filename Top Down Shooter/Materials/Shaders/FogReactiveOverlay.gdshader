shader_type spatial;
render_mode unshaded;
global uniform sampler2D FogDataLocal : filter_linear_mipmap_anisotropic;
global uniform vec2 FogDimensions;
global uniform vec2 InverseFogDimensions;

vec4 blur(vec2 uv, float blurRadius){
    vec4 result = vec4(0.0);
    float totalWeight = 0.0;
    for (float x = -blurRadius; x <= blurRadius; x++){
        for (float y = -blurRadius; y <= blurRadius; y++){
			vec2 offset = vec2(x, y) * InverseFogDimensions;
            result += texture(FogDataLocal, uv + offset);
            totalWeight ++;
        }
    }
    return result /= totalWeight;
}

void fragment() {
	vec2 uv = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz * InverseFogDimensions - vec2(0.5);
	vec4 color = blur(uv,1.0);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
