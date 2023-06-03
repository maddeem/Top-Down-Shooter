shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float point_size : hint_range(0,128);
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_metallic : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float specular;
uniform float metallic;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
global uniform vec3 FogDimensions;
global uniform sampler2D FogData;

void vertex() {
	UV=UV*uv1_scale.xy+uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = UV;
	vec2 vertex_world_pos = ((INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xyz).xz / FogDimensions.xz - vec2(0.5);
	//vec2 pixel_pos = vec2(vertex_world_pos.x / SCREEN_SIZE.x, vertex_world_pos.y / SCREEN_SIZE.y);
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	vec4 fog_sample = texture(FogData,vertex_world_pos);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	if (fog_sample.a > 0.0){
		ALBEDO = mix(ALBEDO,fog_sample.rgb,fog_sample.a);
	}
	float metallic_tex = dot(texture(texture_metallic,base_uv),metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;
}
