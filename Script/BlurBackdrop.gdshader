shader_type canvas_item;
// Blurs and dims everything drawn behind it. Used behind the settings popup.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 6.0) = 3.0;
uniform float dim : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 px = blur_lod * 1.5 / vec2(textureSize(screen_tex, 0));
	vec3 c = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb * 0.4;
	c += textureLod(screen_tex, SCREEN_UV + vec2(px.x, px.y), blur_lod).rgb * 0.15;
	c += textureLod(screen_tex, SCREEN_UV + vec2(-px.x, px.y), blur_lod).rgb * 0.15;
	c += textureLod(screen_tex, SCREEN_UV + vec2(px.x, -px.y), blur_lod).rgb * 0.15;
	c += textureLod(screen_tex, SCREEN_UV + vec2(-px.x, -px.y), blur_lod).rgb * 0.15;
	COLOR = vec4(c * (1.0 - dim), 1.0);
}
