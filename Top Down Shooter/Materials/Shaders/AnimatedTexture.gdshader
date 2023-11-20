shader_type particles;
uniform sampler2D albedo;
uniform int h_frames = 1;
uniform int v_frames = 1;

void vertex(){
	frame_ratio = 1.0/vec2(ivec2(h_frames,v_frames));
	total_frames = float(h_frames * v_frames);
}

void fragment() {
	float total_frames = float(h_frames * v_frames);
	float p = mod(float(frame),float(h_frames));
	vec2 pos = vec2(p,floor(float(frame)/float(h_frames)));
	vec2 uv = (UV * frame_ratio) + pos * frame_ratio;
	vec4 col = texture(albedo, uv);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
