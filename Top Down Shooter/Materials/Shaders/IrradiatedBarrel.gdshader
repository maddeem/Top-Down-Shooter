shader_type spatial;
render_mode unshaded;
uniform int MAX_ITER = 2;
void fragment() {
	vec2 p = UV*8.0- vec2(30.0);
	vec2 i = p;
	float c = 1.0;
	float inten = .05;
	vec2 world_pos = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz;

	for (int n = 0; n < MAX_ITER; n++) 
	{
		float t = (TIME + world_pos.x + world_pos.y) * (1.0 - (3.0 / float(n+1)));
		i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
		c += 1.0/length(vec2(p.x / (sin(i.x+t)/inten),p.y / (cos(i.y+t)/inten)));
	}
	c /= float(MAX_ITER);
	c = 1.5-inversesqrt(c);
	ALBEDO = vec3(c*c*c*c) * vec3(1,64,1);
	ALBEDO.g = min(1.0,ALBEDO.g);
	SPECULAR = 1.0;
}
void light() {
// Output:0

}