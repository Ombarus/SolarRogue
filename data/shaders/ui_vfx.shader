shader_type canvas_item;

uniform float pixel = 1.0;
uniform vec2 red_offset = vec2(0.0, 0.0);
uniform vec2 green_offset = vec2(0.0, 0.0);
uniform vec2 blue_offset = vec2(0.0, 0.0);
uniform float alpha = 1.0;
uniform float rand_strength = 1.0;

uniform vec4 affected = vec4(0.0, 0.0, 1.0, 1.0);

float Hash21(vec2 p) {
	p = fract(p*vec2(123.34, 456.21));
	p += dot(p, p+45.32);
	
	return fract(p.x*p.y);
}

vec2 pixelize(vec2 uv) {
	float mult = 5000.0 / (pixel * pixel);
	uv.x = floor(uv.x * mult) / mult;
	uv.y = floor(uv.y * mult) / mult;
	return uv;
}

vec4 chroma(vec2 uv, sampler2D tex) {
	vec4 col = texture(tex, uv);
	if (abs(red_offset.x) + abs(red_offset.y) > 0.001) {
		col.r = texture(tex, vec2(uv.x + red_offset.x, uv.y + red_offset.y)).r;
	}
	if (abs(green_offset.x) + abs(green_offset.y) > 0.001) {
		col.g = texture(tex, vec2(uv.x + green_offset.x, uv.y + green_offset.y)).g;	
	}
	if (abs(blue_offset.x) + abs(blue_offset.y) > 0.001) {
		col.b = texture(tex, vec2(uv.x + blue_offset.x, uv.y + blue_offset.y)).b;
	}
	
	return col;
}

void fragment() {
	vec2 normal_uv = UV;
	vec4 normal_col = texture(TEXTURE, UV);
    if (normal_uv.x < affected.x || normal_uv.y < affected.y || normal_uv.x > affected.x + affected.z || normal_uv.y > affected.y + affected.a) {
		COLOR = normal_col;
	}
	else {
		vec2 uv = pixelize(UV);
		vec4 col = chroma(uv, TEXTURE);
		col.a = col.a * alpha;
		vec2 id = floor(uv * 10.0);
		float alpha_rand = Hash21(id + floor(TIME*10.0));
		col = col * ( alpha_rand + (rand_strength * (1.0-alpha_rand)) );
		COLOR = col;
	}
}