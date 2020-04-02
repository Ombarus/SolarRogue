shader_type canvas_item;

uniform float pixel = 1.0;
uniform vec2 red_offset = vec2(0.0, 0.0);
uniform vec2 green_offset = vec2(0.0, 0.0);
uniform vec2 blue_offset = vec2(0.0, 0.0);
uniform float alpha = 1.0;

uniform vec4 affected = vec4(0.0, 0.0, 1.0, 1.0);

vec2 pixelize(vec2 uv) {
	float mult = 5000.0 / (pixel * pixel);
	uv.x = floor(uv.x * mult) / mult;
	uv.y = floor(uv.y * mult) / mult;
	return uv;
}

vec4 chroma(vec2 uv, sampler2D tex) {
	vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
	col.r = texture(tex, vec2(uv.x + red_offset.x, uv.y + red_offset.y)).r;
	col.g = texture(tex, vec2(uv.x + green_offset.x, uv.y + green_offset.y)).g;
	col.b = texture(tex, vec2(uv.x + blue_offset.x, uv.y + blue_offset.y)).b;
	col.a = texture(tex, uv).a;
	
	return col;
}

void fragment() {
	vec2 normal_uv = SCREEN_UV;
	vec4 normal_col = texture(TEXTURE, SCREEN_UV);
    if (normal_uv.x < affected.x || normal_uv.y < affected.y || normal_uv.x > affected.x + affected.z || normal_uv.y > affected.y + affected.a) {
		COLOR = normal_col;
	}
	else {
		vec2 uv = pixelize(SCREEN_UV);
		vec4 col = chroma(uv, TEXTURE);
		col.a = col.a * alpha;
		COLOR = col;
	}
}