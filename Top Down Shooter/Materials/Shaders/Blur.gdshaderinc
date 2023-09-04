vec4 blur(vec2 uv, float blurRadius,vec2 InverseFogDimensions, sampler2D FogDataLocal){
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
