shader_type canvas_item;

uniform sampler2D bit_map;
uniform vec4 test_color;

void fragment() {
	// sample the texture
	ivec2 map_size = textureSize(bit_map,0);
    //vec4 tex_color = texture(TEXTURE, UV);
	//uint r = texture(bit_map, UV).r;
	//float fr = float(r) / 255.0;
	//tex_color = vec4(fr, 0.0, 0.0, 1.0);
	vec4 urgba = texture(bit_map, UV);
	float r = float(urgba.r) / float(1);
	float g = float(urgba.g) / float(1);
	float b = float(urgba.b) / float(1);
	
	//COLOR = vec4(r, g, b, 1.0);
	//COLOR = texture(bit_map, UV);
	COLOR = texture(TEXTURE, UV);
}