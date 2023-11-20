shader_type canvas_item;
render_mode unshaded, blend_disabled, skip_vertex_transform;
uniform vec4 visibility_modifiers[2000];
uniform vec4 visiblity_data[2000];
uniform int count = 0;
global uniform sampler2D FogData : filter_nearest;
global uniform sampler2D OcclusionMap : filter_nearest ;
global uniform vec2 FogDimensions;

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

bool bresenham(ivec2 p0, ivec2 p1, float height){
	int dx = iabs(p1.x - p0.x);
	int dy = -iabs(p1.y - p0.y);
	int err = dx + dy;
	int sx = 2 * when_lt(p0.x,p1.x) -1;
	int sy = 2 * when_lt(p0.y,p1.y) -1;
	float walls_hit = 0.0;
	while (true){
		vec4 sample = texture(OcclusionMap,vec2(p0)/FogDimensions);
		walls_hit += fwhen_gt(sample.r + sample.g + sample.b - sample.a,height);
		if (p0==p1 || walls_hit > 1.0){
			return p0==p1 || walls_hit <= 1.0;
		}
		int c = when_gt(err * 2 - dy, dx - err * 2);
		err += c * dy + (1 - c) * dx;
		p0.x += c * sx;
		p0.y += (1 - c) * sy;
	}
}

vec4 get_color(vec2 uv, vec2 scaler){
	vec4 color = vec4(0);
	ivec2 iuv = ivec2(uv);
	int bit_color = 0;
	for (int i = 0; i < count; i++){
		vec4 circlePos = visibility_modifiers[i];
		vec4 circleData = visiblity_data[i];
		vec2 d = circlePos.xy - uv;
		vec2 cn = normalize(-vec2(sin(circleData.z),cos(circleData.z)));
		float a = acos(dot(normalize(d),cn));
		d *= d;
		float dist = d.x + d.y;
		if ((bit_color & int(circleData.y)) == 0 && dist < circlePos.z * circlePos.z && (a <= circleData.a || dist < circlePos.a * circlePos.a) && bresenham(ivec2(circlePos.xy),iuv,circleData.x)) {
			bit_color = bit_color | int(circleData.y);
			color = bit_to_color(bit_color);
		}
	}
	return color;
}

void fragment(){
	vec2 uv = UV * FogDimensions;
	COLOR = get_color(uv,FogDimensions);
}