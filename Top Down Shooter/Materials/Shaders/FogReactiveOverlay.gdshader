shader_type spatial;
#include "res://Materials/Shaders/Blur.gdshaderinc"
render_mode unshaded;
global uniform sampler2D FogDataLocal : filter_linear_mipmap_anisotropic;
global uniform vec2 InverseFogDimensions;
global uniform vec4 FogExploredColor;
uniform vec4 color_override : source_color = vec4(0);

void fragment() {
	vec2 uv = (INV_VIEW_MATRIX  * vec4(VERTEX, 1.0)).xz * InverseFogDimensions - vec2(0.5);
	vec4 color = blur(uv,1.0,InverseFogDimensions,FogDataLocal);
    vec4 finalColor = mix(color_override,color,smoothstep(FogExploredColor.a,color_override.a,min(1.0,color.a + FogExploredColor.a)));

    ALBEDO = finalColor.rgb;
    ALPHA = finalColor.a;
}
