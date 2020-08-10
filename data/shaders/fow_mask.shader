shader_type canvas_item;

uniform float sampler = 400.0;
uniform vec3 gray_color = vec3(1.0, 1.0, 1.0);
uniform sampler2D overlay;

void fragment() {
	vec2 uv = UV;
	//uv.x = float(floor(uv.x * sampler)) / sampler;
	//uv.y = float(floor(uv.y * sampler)) / sampler;
	vec4 urgba = texture(TEXTURE, UV);
	vec4 orgba = texture(overlay, uv*10.0);

	//COLOR = urgba;
	COLOR = vec4(orgba.r, orgba.g, orgba.b, urgba.r);
	//COLOR = vec4(gray_color.r, gray_color.g, gray_color.b, urgba.r);
}