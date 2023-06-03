shader_type canvas_item;
uniform vec4 fog_color = vec4(0,0,0,1);
uniform vec4 reveal_color = vec4(0,0,0,0);
uniform vec4 explored_color = vec4(0,0,0,.5);
uniform vec3 visibility_modifiers[3000];
uniform int count = 0;
uniform sampler2D occlusion_mask ;
global uniform sampler2D FogData;
global uniform vec2 FogDimensions;

int iabs(int i){return (i ^ (i >> 31)) - (i >> 31);}
int isign(int i){return iabs( (i | -i) >>31 ) | (i >> 31);}
int when_gt(int x, int y) {return max(isign(x - y), 0);}
int when_lt(int x, int y) {return max(isign(y - x), 0);}
int when_ge(int x, int y) {return 1 - when_lt(x, y);}
int when_le(int x, int y) {return 1 - when_gt(x, y);}
float fwhen_lt(float x, float y) {return max(sign(y - x), 0.0);}
float fwhen_gt(float x, float y) {return max(sign(x - y), 0.0);}

bool bresenham(ivec2 p0, ivec2 p1,vec2 scaler){
	int dx = iabs(p1.x - p0.x);
	int dy = -iabs(p1.y - p0.y);
	int err = dx + dy;
	int e2 = 2 * err;
	int sx = 2 * when_lt(p0.x,p1.x) -1;
	int sy = 2 * when_lt(p0.y,p1.y) -1;
	float walls_hit = 0.0;
	float last = 0.0;
	while (true){
		last = walls_hit;
		walls_hit += fwhen_gt(texture(occlusion_mask,vec2(float(p0.x),float(p0.y)) * scaler).r,0.0);
		if (walls_hit != 0.0 && last == walls_hit){
			return false;	
		}
		if (p0==p1){
			return true;
		}
		e2 = 2 * err;
		int ge = when_ge(e2,dy);
		err += dy * ge;
		p0[0] += sx * ge;
		int le = when_le(e2,dx);
		err += dx * le;
		p0[1] += sy * le;
	}
}

vec4 get_color(vec2 uv, vec4 sample, vec2 scaler, ivec2 iuv){
	vec4 color;
	for (int i = 0; i < count; i++){
		vec3 circlePos = visibility_modifiers[i];
		vec2 d = uv-circlePos.xy;
		if (d.x * d.x + d.y * d.y < circlePos.z * circlePos.z){
			if (bresenham(ivec2(int(circlePos.x),int(circlePos.y)),iuv,scaler)){
				return reveal_color;
			}else{
				if (sample.a < 1.0){
					color = explored_color;
					
				}else{
					color = sample;
				}
				return color;
			}
		}
	}
	if (sample.a < 1.0){
		color =explored_color;
	}else{
		color = sample;
	}
	return color;
}

void fragment(){
	vec2 uv = UV * FogDimensions;
	COLOR = get_color(
		uv,
		texture(FogData,UV),
		1.0/FogDimensions,
		ivec2(int(round(uv.x)),int(round(uv.y)))
	);
}