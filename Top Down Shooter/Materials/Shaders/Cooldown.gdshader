shader_type canvas_item;
uniform float percent = 0.0;

void fragment() {
    vec2 center = UV - vec2(0.5);
    float ang = atan(center.x, center.y) + PI; // Convert coordinate to angle, relative to center
    float ang2 = percent * PI * 2.0;
    COLOR = mix(COLOR,COLOR * vec4(vec3(0.4), 1.0),  step(ang,ang2));
}