shader_type canvas_item;
uniform int count = 0;
global uniform sampler2D FogDataLocal;
global uniform sampler2D FogData;
global uniform vec2 FogDimensions;
global uniform vec2 InverseFogDimensions;
global uniform vec4 FogRevealColor;
global uniform vec4 FogExploredColor;
global uniform vec4 FogUnexploredColor;
global uniform int FogPlayerBit;

int color_to_bit(vec3 color){
	ivec3 new = ivec3(round(color * 255.0));
	return (new.x << 16) | (new.y << 8) | new.z;
}

void fragment(){
	vec4 sample = texture(FogData,UV);
	vec4 second_pass = texture(FogDataLocal,UV);
	int bit_sample = color_to_bit(sample.rgb);
	if ((FogPlayerBit & bit_sample) == FogPlayerBit){ //Is revealed
		COLOR = FogRevealColor;
	}else{
		if (second_pass.a < 1.0){
			COLOR = FogExploredColor;
		}else{
			COLOR = FogUnexploredColor;
		}
	}
}