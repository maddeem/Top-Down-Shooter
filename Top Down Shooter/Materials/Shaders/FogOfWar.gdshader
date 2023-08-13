shader_type canvas_item;
render_mode unshaded, blend_disabled, skip_vertex_transform;
uniform int count = 0;
global uniform sampler2D FogDataLocal : filter_nearest;
global uniform sampler2D FogData : filter_nearest;
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
	if ((FogPlayerBit & color_to_bit(sample.rgb)) == FogPlayerBit){ //Is revealed
		COLOR = FogRevealColor;
	}else{
		if (texture(FogDataLocal,UV).a > 0.99){
			COLOR = FogUnexploredColor;
		}else{
			COLOR = FogExploredColor;
		}
	}
}