shader_type spatial;

#include "res://addons/zylann.hterrain/shaders/include/heightmap.gdshaderinc"
#include "res://Materials/Shaders/SimplexNoise3D.gdshaderinc"
#include "res://Materials/Shaders/Blur.gdshaderinc"

uniform sampler2D u_terrain_heightmap;
uniform sampler2D u_terrain_normalmap;
uniform sampler2D u_terrain_colormap;
uniform sampler2D u_terrain_splatmap;
uniform sampler2D u_terrain_splatmap_1;
uniform sampler2D u_terrain_splatmap_2;
uniform sampler2D u_terrain_splatmap_3;
uniform sampler2D u_terrain_globalmap : source_color;
uniform mat4 u_terrain_inverse_transform;
uniform mat3 u_terrain_normal_basis;
global uniform vec2 InverseFogDimensions;
global uniform sampler2D FogDataLocal : filter_linear_mipmap_anisotropic;
global uniform sampler2D CreepData : filter_linear_mipmap_anisotropic;
global uniform sampler2D CreepTexture : filter_linear_mipmap_anisotropic;
uniform vec4 FogExploredColor;
uniform sampler2DArray u_ground_albedo_bump_array : source_color;
uniform sampler2DArray u_ground_normal_roughness_array;

uniform float u_ground_uv_scale = 20.0;
uniform bool u_depth_blending = true;
uniform float u_globalmap_blend_start;
uniform float u_globalmap_blend_distance;
uniform bool u_tile_reduction = false;

varying float v_hole;
varying vec3 v_tint;
varying vec2 v_terrain_uv;
varying vec3 v_ground_uv;
varying float v_distance_to_camera;

vec3 unpack_normal(vec4 rgba) {
	vec3 n = rgba.xzy * 2.0 - vec3(1.0);
	n.z *= -1.0;
	return n;
}

vec4 pack_normal(vec3 n, float a) {
	n.z *= -1.0;
	return vec4((n.xzy + vec3(1.0)) * 0.5, a);
}
vec4 get_depth_blended_weights(vec4 splat, vec4 bumps) {
	float dh = 0.2;
	vec4 h = bumps + splat;
	h *= smoothstep(0, 0.05, splat);
	vec4 d = h + dh;
	d.r -= max(h.g, max(h.b, h.a));
	d.g -= max(h.r, max(h.b, h.a));
	d.b -= max(h.g, max(h.r, h.a));
	d.a -= max(h.g, max(h.b, h.r));
	return clamp(d, 0, 1);
}

vec3 get_triplanar_blend(vec3 world_normal) {
	vec3 blending = abs(world_normal);
	blending = normalize(max(blending, vec3(0.00001))); // Force weights to sum to 1.0
	float b = blending.x + blending.y + blending.z;
	return blending / vec3(b, b, b);
}

vec4 texture_triplanar(sampler2D tex, vec3 world_pos, vec3 blend) {
	vec4 xaxis = texture(tex, world_pos.yz);
	vec4 yaxis = texture(tex, world_pos.xz);
	vec4 zaxis = texture(tex, world_pos.xy);
	// blend the results of the 3 planar projections.
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

void get_splat_weights(vec2 uv, out vec4 out_high_indices, out vec4 out_high_weights) {
	vec4 ew0 = texture(u_terrain_splatmap, uv);
	vec4 ew1 = texture(u_terrain_splatmap_1, uv);
	vec4 ew2 = texture(u_terrain_splatmap_2, uv);
	vec4 ew3 = texture(u_terrain_splatmap_3, uv);
	
	float weights[16] = {
		ew0.r, ew0.g, ew0.b, ew0.a,
		ew1.r, ew1.g, ew1.b, ew1.a,
		ew2.r, ew2.g, ew2.b, ew2.a,
		ew3.r, ew3.g, ew3.b, ew3.a
	};
	int high_indices_array[4] = {0, 0, 0, 0};
	float high_weights_array[4] = {0.0, 0.0, 0.0, 0.0};
	int count = 0;
	float pivot = /*weights_sum*/1.0 / 5.0;
	
	for (int i = 0; i < 16; ++i) {
		if (weights[i] > pivot) {
			high_weights_array[count] = weights[i];
			high_indices_array[count] = i;
			weights[i] = 0.0;
			++count;
		}
	}
	
	while (count < 4 && pivot > 0.0) {
		float max_weight = 0.0;
		int max_index = 0;
		for (int i = 0; i < 16; ++i) {
			if (/*weights[i] <= pivot && */weights[i] > max_weight) {
				max_weight = weights[i];
				max_index = i;
				weights[i] = 0.0;
			}
		}
		high_indices_array[count] = max_index;
		high_weights_array[count] = max_weight;
		++count;
		pivot = max_weight;
	}
	out_high_weights = vec4(
		high_weights_array[0], high_weights_array[1], 
		high_weights_array[2], high_weights_array[3]);
	
	out_high_indices = vec4(
		float(high_indices_array[0]), float(high_indices_array[1]),
		float(high_indices_array[2]), float(high_indices_array[3]));
	
	out_high_weights /= 
		out_high_weights.r + out_high_weights.g + out_high_weights.b + out_high_weights.a;
}

vec4 depth_blend2(vec4 a_value, float a_bump, vec4 b_value, float b_bump, float t) {
	float d = 0.1;
	float ma = max(a_bump + (1.0 - t), b_bump + t) - d;
	float ba = max(a_bump + (1.0 - t) - ma, 0.0);
	float bb = max(b_bump + t - ma, 0.0);
	return (a_value * ba + b_value * bb) / (ba + bb);
}

vec2 rotate(vec2 v, float cosa, float sina) {
	return vec2(cosa * v.x - sina * v.y, sina * v.x + cosa * v.y);
}

vec4 texture_array_antitile(sampler2DArray albedo_tex, sampler2DArray normal_tex, vec3 uv,
	out vec4 out_normal) {
	float frequency = 2.0;
	float scale = 1.3;
	float sharpness = 0.7;
	float rot = 3.14 * 0.6;
	float cosa = cos(rot);
	float sina = sin(rot);
	vec3 uv2 = vec3(rotate(uv.xy, cosa, sina) * scale, uv.z);
	
	vec4 col0 = texture(albedo_tex, uv);
	vec4 col1 = texture(albedo_tex, uv2);
	vec4 nrm0 = texture(normal_tex, uv);
	vec4 nrm1 = texture(normal_tex, uv2);
	vec3 n = unpack_normal(nrm1);
	n.xz = rotate(n.xz, cosa, -sina);
	nrm1 = pack_normal(n, nrm1.a);
	float t = 1.1 + 0.5
		* sin(uv2.x * frequency + sin(uv.x) * 2.0) 
		* cos(uv2.y * frequency + sin(uv.y) * 2.0); // Result in [0..2]
	t = smoothstep(sharpness, 2.0 - sharpness, t);
	out_normal = depth_blend2(nrm0, col0.a, nrm1, col1.a, t);
	return depth_blend2(col0, col0.a, col1, col1.a, t);
}

void vertex() {
	vec4 wpos = MODEL_MATRIX * vec4(VERTEX, 1);
	vec2 cell_coords = (u_terrain_inverse_transform * wpos).xz;
	cell_coords += vec2(0.5);
	UV = cell_coords / vec2(textureSize(u_terrain_heightmap, 0));
	float h = sample_heightmap(u_terrain_heightmap, UV);
	VERTEX.y = h;
	wpos.y = h;
	vec3 base_ground_uv = vec3(cell_coords.x, h * MODEL_MATRIX[1][1], cell_coords.y);
	v_ground_uv = base_ground_uv / u_ground_uv_scale;
	vec4 tint = texture(u_terrain_colormap, UV);
	v_hole = tint.a;
	v_tint = tint.rgb;
	
	// Need to use u_terrain_normal_basis to handle scaling.
	NORMAL = u_terrain_normal_basis * unpack_normal(texture(u_terrain_normalmap, UV));

	v_distance_to_camera = distance(wpos.xyz, CAMERA_POSITION_WORLD);
}



void fragment() {
	if (v_hole < 0.5) {
		// TODO Add option to use vertex discarding instead, using NaNs
		discard;
	}
	vec2 uv2 = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz;
	vec2 uv = uv2 * InverseFogDimensions - vec2(0.5);
	vec4 color = blur(uv,2.0,InverseFogDimensions,FogDataLocal);
	if (color.a < 1.0){
	
		vec3 terrain_normal_world = 
			u_terrain_normal_basis * (unpack_normal(texture(u_terrain_normalmap, UV)));
		terrain_normal_world = normalize(terrain_normal_world);
		vec3 normal = terrain_normal_world;
		float globalmap_factor = clamp((v_distance_to_camera - u_globalmap_blend_start)
			 * u_globalmap_blend_distance, 0.0, 1.0);
		globalmap_factor *= globalmap_factor; // slower start, faster transition but far away
		vec3 global_albedo = texture(u_terrain_globalmap, UV).rgb;
		ALBEDO = global_albedo;
		if (globalmap_factor < 1.0) {
			vec4 high_indices;
			vec4 high_weights;
			get_splat_weights(UV, high_indices, high_weights);
			vec4 ab0, ab1, ab2, ab3;
			vec4 nr0, nr1, nr2, nr3;
			if (u_tile_reduction) {
				ab0 = texture_array_antitile(
					u_ground_albedo_bump_array, u_ground_normal_roughness_array, 
					vec3(v_ground_uv.xz, high_indices.x), nr0);
				ab1 = texture_array_antitile(
					u_ground_albedo_bump_array, u_ground_normal_roughness_array, 
					vec3(v_ground_uv.xz, high_indices.y), nr1);
				ab2 = texture_array_antitile(
					u_ground_albedo_bump_array, u_ground_normal_roughness_array, 
					vec3(v_ground_uv.xz, high_indices.z), nr2);
				ab3 = texture_array_antitile(
					u_ground_albedo_bump_array, u_ground_normal_roughness_array, 
					vec3(v_ground_uv.xz, high_indices.w), nr3);
			} else {
				ab0 = texture(u_ground_albedo_bump_array, vec3(v_ground_uv.xz, high_indices.x));
				ab1 = texture(u_ground_albedo_bump_array, vec3(v_ground_uv.xz, high_indices.y));
				ab2 = texture(u_ground_albedo_bump_array, vec3(v_ground_uv.xz, high_indices.z));
				ab3 = texture(u_ground_albedo_bump_array, vec3(v_ground_uv.xz, high_indices.w));
				nr0 = texture(u_ground_normal_roughness_array, vec3(v_ground_uv.xz, high_indices.x));
				nr1 = texture(u_ground_normal_roughness_array, vec3(v_ground_uv.xz, high_indices.y));
				nr2 = texture(u_ground_normal_roughness_array, vec3(v_ground_uv.xz, high_indices.z));
				nr3 = texture(u_ground_normal_roughness_array, vec3(v_ground_uv.xz, high_indices.w));
			}
			vec3 col0 = ab0.rgb * v_tint;
			vec3 col1 = ab1.rgb * v_tint;
			vec3 col2 = ab2.rgb * v_tint;
			vec3 col3 = ab3.rgb * v_tint;
			vec4 rough = vec4(nr0.a, nr1.a, nr2.a, nr3.a);
			vec3 normal0 = unpack_normal(nr0);
			vec3 normal1 = unpack_normal(nr1);
			vec3 normal2 = unpack_normal(nr2);
			vec3 normal3 = unpack_normal(nr3);
			vec4 w;
			// TODO An #ifdef macro would be nice! Or copy/paste everything in a different shader...
			if (u_depth_blending) {
				w = get_depth_blended_weights(high_weights, vec4(ab0.a, ab1.a, ab2.a, ab3.a));
			} else {
				w = high_weights;
			}
			float w_sum = (w.r + w.g + w.b + w.a);
			ALBEDO = (
				w.r * col0.rgb +
				w.g * col1.rgb +
				w.b * col2.rgb +
				w.a * col3.rgb) / w_sum;

			ROUGHNESS = (
				w.r * rough.r +
				w.g * rough.g +
				w.b * rough.b +
				w.a * rough.a) / w_sum;

			vec3 ground_normal = /*u_terrain_normal_basis **/ (
				w.r * normal0 +
				w.g * normal1 +
				w.b * normal2 +
				w.a * normal3) / w_sum;
			normal = normalize(vec3(
				terrain_normal_world.x + ground_normal.x,
				terrain_normal_world.y,
				terrain_normal_world.z + ground_normal.z));
			normal = mix(normal, terrain_normal_world, globalmap_factor);
			ALBEDO = mix(ALBEDO, global_albedo, globalmap_factor);
			ROUGHNESS = mix(ROUGHNESS, 1.0, globalmap_factor);
		}
		vec4 sample = texture(CreepData,uv);
		float alpha = min(sample.a,blur(uv,2.0,InverseFogDimensions,CreepData).a * (snoise(vec3(uv2 * 0.1,TIME*0.1)) + 1.0) * 0.5);
		ALBEDO = mix(ALBEDO,texture(CreepTexture,uv2 * 0.1).rgb,alpha * sample.g);
		NORMAL = (VIEW_MATRIX * (vec4(terrain_normal_world, 0.0))).xyz;
		ALBEDO = mix(ALBEDO,color.rgb,color.a);
		SPECULAR = clamp(1.0-color.a,0.0,0.5);
	}else{
		ALBEDO = color.rgb;
		SPECULAR = 0.0;
	}
}
