shader_type spatial;
render_mode unshaded;
global uniform sampler2D FogDataLocal;
global uniform vec2 FogDimensions;
global uniform vec2 InverseFogDimensions;
uniform float blurRadius = 1.5;

vec4 blur2(vec2 uv){
    vec4 result = vec4(0.0);
    // Horizontal blur pass
    for (float x = -blurRadius; x <= blurRadius; x++){
        result += texture(FogDataLocal, uv + vec2(x * InverseFogDimensions.x, 0.0));
    }
    result /= (2.0 * blurRadius + 1.0);
    // Vertical blur pass
    vec4 finalColor = vec4(0.0);
    for (float y = -blurRadius; y <= blurRadius; y++){
        finalColor += texture(FogDataLocal, uv + vec2(0.0, y * InverseFogDimensions.y));
    }
    finalColor /= (2.0 * blurRadius + 1.0);
    return finalColor;
}

vec4 blur(vec2 uv){
    vec4 result = vec4(0.0);
    float totalWeight = 0.0;

    // Calculate the weights for the Gaussian kernel
    for (float x = -blurRadius; x <= blurRadius; x++){
        for (float y = -blurRadius; y <= blurRadius; y++){
            float dist = length(vec2(x, y));
            float weight = exp(-0.5 * dist * dist);
            result += texture(FogDataLocal, uv + InverseFogDimensions * vec2(x, y)) * weight * 1.25 ;
            totalWeight += weight;
        }
    }

    // Normalize the result by dividing by the total weight
    result /= totalWeight;

    return result;
}

void fragment() {
	vec2 uv = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz * InverseFogDimensions - vec2(0.5);
	vec4 color = blur(uv);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
