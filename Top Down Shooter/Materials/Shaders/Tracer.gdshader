shader_type spatial;
render_mode unshaded,cull_disabled;
instance uniform vec4 color : source_color;
instance uniform float time = 0.0;
instance uniform float size = 0.25;
void fragment() {
	ALBEDO = color.rgb;
	float s = size * 0.5;
	float uv = UV.y * 2.0 + s;

	// Define two threshold values for the transition
	float lowerThreshold = uv - s;
	float upperThreshold = s + uv;

	// Use smoothstep to interpolate the alpha value between 0 and 1
	ALPHA = smoothstep(upperThreshold, lowerThreshold, time);

	// If you want to set ALPHA to 0 outside of the transition range, you can do:
	if (time < lowerThreshold || time > upperThreshold) {
		ALPHA = 0.0;
	}
}
