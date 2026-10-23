shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength = 0.0;
void fragment() {
 vec2 shift = SCREEN_PIXEL_SIZE * (strength * 5.0);
 vec3 color = texture(screen_texture, SCREEN_UV).rgb * 0.4;
 color += texture(screen_texture, SCREEN_UV + vec2(shift.x, 0.0)).rgb * 0.15;
 color += texture(screen_texture, SCREEN_UV - vec2(shift.x, 0.0)).rgb * 0.15;
 color += texture(screen_texture, SCREEN_UV + vec2(0.0, shift.y)).rgb * 0.15;
 color += texture(screen_texture, SCREEN_UV - vec2(0.0, shift.y)).rgb * 0.15;
 COLOR = vec4(color, 1.0);
}
