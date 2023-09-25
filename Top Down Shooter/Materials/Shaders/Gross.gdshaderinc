mat2 rotate2D(float r) {
    return mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r)));
}

vec4 get_slime(vec2 uv, float S){
    // Normalized pixel coordinates (from 0 to 1)
    vec3 col = vec3(0);
    float t = TIME * 0.025; // Adjust the time factor for faster animation

    vec2 n = vec2(0);
    vec2 q = vec2(0);
    vec2 p = uv;
    float d = dot(p, p);
    float a = 0.0;
	float o_s = S;
    mat2 m = rotate2D(5.);

    for (float j = 0.; j < 18.; j++) {
        p *= m;
        n *= m;
        q = p * S + t * 4. + sin(t * 4. - d * 6.) * 0.8 + j + n;
        a += dot(cos(q) / S, vec2(0.2));
        n -= sin(q);
        S *= 1.2;
    }

    col = vec3(4, 2, 1) * (a + 0.2) + a * o_s * 1.5;

    // Output to screen
    return vec4(col.rgb, 1.0);
}
