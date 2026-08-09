shader_type canvas_item;
render_mode blend_mix;

uniform vec4 tint_color : source_color = vec4(0.78, 0.84, 0.9, 0.92);
uniform vec4 shadow_color : source_color = vec4(0.08, 0.12, 0.15, 1.0);
uniform vec4 outline_color : source_color = vec4(0.015, 0.02, 0.025, 1.0);
uniform float desaturate : hint_range(0.0, 1.0) = 0.35;
uniform float contrast : hint_range(0.5, 2.0) = 1.18;
uniform float posterize_steps : hint_range(2.0, 16.0) = 7.0;
uniform float outline_pixels : hint_range(0.0, 4.0) = 1.35;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_pixels;
	float neighbor_alpha = 0.0;
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(px.x, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(-px.x, px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV + vec2(px.x, -px.y)).a);
	neighbor_alpha = max(neighbor_alpha, texture(TEXTURE, UV - vec2(px.x, px.y)).a);

	if (tex.a < 0.03 && neighbor_alpha > 0.08) {
		COLOR = vec4(outline_color.rgb, neighbor_alpha * outline_strength * tint_color.a);
	} else {
		float value = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
		vec3 color = mix(tex.rgb, vec3(value), desaturate);
		color = clamp((color - vec3(0.5)) * contrast + vec3(0.5), vec3(0.0), vec3(1.0));
		color = floor(color * posterize_steps) / posterize_steps;
		color = mix(shadow_color.rgb, color * tint_color.rgb, clamp(value + 0.25, 0.0, 1.0));
		float edge = smoothstep(0.05, 0.55, tex.a);
		color = mix(outline_color.rgb, color, edge);
		COLOR = vec4(color, tex.a * tint_color.a);
	}
}
