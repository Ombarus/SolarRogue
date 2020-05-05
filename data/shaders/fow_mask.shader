shader_type canvas_item;

uniform vec3 gray_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 urgba = texture(TEXTURE, UV);

	COLOR = vec4(gray_color.r, gray_color.g, gray_color.b, length(urgba));
}