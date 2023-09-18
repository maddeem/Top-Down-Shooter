shader_type canvas_item;
render_mode unshaded, blend_disabled, skip_vertex_transform;
uniform vec3 visibility_modifiers[2000];
uniform vec4 visiblity_data[2000];
uniform int count = 0;
global uniform sampler2D FogData : filter_nearest;
global uniform sampler2D OcclusionMap : filter_nearest ;
global uniform vec2 FogDimensions;
global uniform vec2 InverseFogDimensions;

int iabs(int i){return (i ^ (i >> 31)) - (i >> 31);}
int isign(int i){return iabs( (i | -i) >>31 ) | (i >> 31);}
int when_gt(int x, int y) {return max(isign(x - y), 0);}
int when_lt(int x, int y) {return max(isign(y - x), 0);}
int when_ge(int x, int y) {return 1 - when_lt(x, y);}
int when_le(int x, int y) {return 1 - when_gt(x, y);}
float fwhen_lt(float x, float y) {return max(sign(y - x), 0.0);}
float fwhen_gt(float x, float y) {return max(sign(x - y), 0.0);}

vec4 bit_to_color(int value) {
    return vec4(
        float((value >> 24) & 0xFF) / 255.0,
        float((value >> 16) & 0xFF) / 255.0,
        float((value >> 8) & 0xFF) / 255.0,
        float(value & 0xFF) / 255.0
    );
}

bool bresenham(ivec2 p0, ivec2 p1,vec2 scaler, float height){
	int dx = iabs(p1.x - p0.x);
	int dy = -iabs(p1.y - p0.y);
	int err = dx + dy;
	int sx = 2 * when_lt(p0.x,p1.x) -1;
	int sy = 2 * when_lt(p0.y,p1.y) -1;
	float walls_hit = 0.0;
	float last = 0.0;
	while (true){
		last = walls_hit;
		vec4 sample = texture(OcclusionMap,vec2(p0)*scaler);
		float result = sample.r + sample.g + sample.b - sample.a;
		walls_hit += min(1.0,fwhen_gt(result,height));
		if (walls_hit != 0.0 && last == walls_hit || walls_hit == 4.0){
			return false;	
		}
		if (p0==p1){
			return true;
		}

        if (err * 2 - dy > dx - err * 2) {
            // horizontal step
            err += dy;
            p0.x += sx;
        } else {
            // vertical step
            err += dx;
            p0.y += sy;
        }
	}
}

vec4 get_color(vec2 uv, vec2 scaler){
	vec4 color = vec4(0);
	ivec2 iuv = ivec2(uv);
	int bit_color = 0;
	for (int i = 0; i < count; i++){
		vec3 circlePos = visibility_modifiers[i];
		vec4 circleData = visiblity_data[i];
		vec2 d = circlePos.xy - uv;
		vec2 n = normalize(d);
		vec2 cn = normalize(-vec2(sin(circleData.z),cos(circleData.z)));
		float a = acos(dot(n,cn));
		d *= d;
		float dist = d.x + d.y;
		if ((bit_color & int(circleData.y)) == 0 && dist < circlePos.z * circlePos.z && a <= circleData.a) {
			if (bresenham(ivec2(circlePos.xy),iuv,scaler,circleData.x)){
				bit_color = bit_color | int(circleData.y);
				color = bit_to_color(bit_color);
			}
		}
	}
	return color;
}

void fragment(){
	vec2 uv = UV * FogDimensions;
	COLOR = get_color(uv,InverseFogDimensions);
}