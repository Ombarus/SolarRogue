shader_type canvas_item;

uniform sampler2D bit_map;

void vertex() {
}

void fragment() {
	//COLOR = texture(bit_map, UV);
	vec4 col = texture(TEXTURE, UV);
	if (col.r > 0.5) {
		COLOR = vec4(1,1,1,0);
	} else {
		COLOR = vec4(0,0,0,1);
	}
}