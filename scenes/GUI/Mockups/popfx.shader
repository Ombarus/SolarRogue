shader_type canvas_item;

uniform float percent = 1.0;
uniform float width = 0.1;

varying float test;
void vertex() {
	test = (UV.x + UV.y) / 2.0;
}

void fragment() {
	float x = 449.0 / TEXTURE_PIXEL_SIZE.x;
	float y = 0.0;
	float w = 63.0 / TEXTURE_PIXEL_SIZE.x;
	float h = 92.0 / TEXTURE_PIXEL_SIZE.x;
	
	vec4 bleh = texture(TEXTURE, UV);
	
	float a = 1.0;
	if (test < (percent-width)) {
		a = bleh.a;
	} else if (test > (percent + width)) {
		a = 0.0;
	} else {
		float pp = percent+width;
		float pm = percent-width;
		a = -1.0 / (pp - pm) * test + (1.0/(pp-pm)*pp);
		a *= bleh.a
	}
	
	//float a = mix(bleh.a, 0.0, test * percent);
	
	
	
	//COLOR = vec4(UV.x, UV.y, 0.0, 1.0);
	COLOR = vec4(bleh.r, bleh.g, bleh.b, a);
	//COLOR = vec4(bleh.r, bleh.g, bleh.b, bleh.a);
}