shader_type canvas_item;

uniform float density = 0.01;
uniform float brightness = 1.0;

uniform vec3 color = vec3(1.0, 0.0, 0.0);
uniform float scale = 10.0;
uniform float neb_density = 0.25;
uniform float falloff = 8.;

uniform vec2 offset = vec2(0.0, 0.0);

float smootherstep(float a, float b, float r) {
	r = clamp(r, 0.0, 1.0);
	r = r * r * r * (r * (6. * r - 15.0) + 10.);
	return mix(a, b, r);
}

float rand(vec2 coord) {
	return fract(sin(dot(coord, vec2(12.9898, 78.233)))*43758.5453123);
}

float perlin_2d(vec2 coord) {
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));
	
	vec2 cubic = f * f * (3.0 - 2.0 * f);
	
	return mix(a,b, cubic.x) + (c-a) * cubic.y * (1.0 - cubic.x) + (d-b) * cubic.x * cubic.y;
}

float normalnoise(vec2 p) {
	return perlin_2d(p) * 0.5 + 0.5;
}

float noise(vec2 p, vec2 o) {
	p += o;
	int steps = 5;
	float s = pow(2.0, float(steps));
	float displace = 0.0;
	for (int i = 0; i < steps; i++) {
		displace = normalnoise(p * s + displace);
		s *= 0.5;
	}
	return normalnoise(p + displace);
}


float point_star(vec2 uv, float d, float b) {
	float test = rand(floor(uv*10240.0));
	float c = b * rand(uv * 3.1415);
	if (test < density) {
		return c;
	}
	else {
		return 0.0;
	}
}

vec4 nebula(vec2 uv, float s, float d, float f, float index, float time) {
	vec2 rand_offset = vec2(
		rand(vec2(index + 305.141592, index + 654.0)) * 300.0, 
		rand(vec2(index + 6548.141592, index + 104.34)) * 300.0);
	float n = noise(uv * s, rand_offset);
	n = pow(n + d, f);
	vec3 rand_col = vec3(rand(vec2(index + 45., 3.14159265)), rand(vec2(index + 877., 6.283)), rand(vec2(index * 84.,12.566)));
	return vec4(rand_col, n);
}

void fragment() {
	vec4 stars = vec4(point_star(UV, density, brightness));
	vec4 nebs = vec4(0.0, 0.0, 0.0, 0.0);
	for (int i = 0; i < 4; i++) {
		int i2 = i + 4;
		float s2 = rand(vec2(float(i2)*100., float(i2)*100.)) * scale + 5.0;
		float d2 = rand(vec2(float(i2+1)*100., float(i2+1)*100.)) * neb_density;
		float f2 = rand(vec2(float(i2+2)*100., float(i2+2)*100.)) * falloff;
		vec4 neb = nebula(UV, s2, d2, f2, float(i2), TIME * 0.0001);
		nebs = vec4(mix(nebs.rgb, neb.rgb, neb.a), max(neb.a, nebs.a));
	}
	COLOR = vec4(mix(stars.rgb, nebs.rgb, nebs.a), 1.);
}