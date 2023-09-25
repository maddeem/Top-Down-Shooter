shader_type canvas_item;
render_mode unshaded, blend_disabled, skip_vertex_transform;
uniform int count = 0;
global uniform sampler2D FogDataLocal : filter_nearest;
global uniform sampler2D FogData : filter_nearest;
global uniform vec4 FogRevealColor;
global uniform vec4 FogExploredColor;
global uniform vec4 FogUnexploredColor;
global uniform int FogPlayerBit;

int color_to_bit(vec4 color){
    ivec4 new_color = ivec4(round(color * 255.0));
    return (new_color.r << 24) | (new_color.g << 16) | (new_color.b << 8) | new_color.a;
}

void fragment(){
	vec4 sample = texture(FogData,UV);
	vec4 col;
	vec4 this_pass = texture(FogDataLocal,UV);
	if ((color_to_bit(sample) & FogPlayerBit) != 0){ //Is revealed
		col = FogRevealColor;
	}else{
		if (this_pass.a > 0.99){
			col = FogUnexploredColor;
		}else{
			col = FogExploredColor;
		}
	}
	COLOR = mix(col,this_pass,0.65);
}