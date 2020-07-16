shader_type canvas_item;

uniform vec3 gray_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D overlay;

void fragment() {
	vec4 urgba = texture(TEXTURE, UV);
	vec4 orgba = texture(overlay, UV*10.0);

	//COLOR = urgba;
	COLOR = vec4(orgba.r, orgba.g, orgba.b, urgba.r);
	//COLOR = vec4(gray_color.r, gray_color.g, gray_color.b, urgba.r);
}