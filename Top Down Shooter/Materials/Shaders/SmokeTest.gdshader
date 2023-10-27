shader_type spatial;
#include "SmokeNoise.gdshaderinc"
render_mode depth_draw_opaque;


void fragment()
{
	float noise = smoke_noise(UV,3.5,0.2,2,1.,1.5);
    ALBEDO = vec3(noise, noise, noise);
	ALPHA = 0.9 - noise;
}