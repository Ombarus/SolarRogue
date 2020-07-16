shader_type canvas_item;

uniform int iterations = 17;
uniform float formuparam = 0.53;
uniform int volsteps = 20;
uniform float stepsize = 0.1;
uniform float zoom = 0.8;
uniform float tile = 0.850;
uniform float speed = 0.001;
uniform float brightness = 0.0015;
uniform float darkmatter = 0.300;
uniform float distfading = 0.730;
uniform float saturation = 0.850;

void fragment() {
	vec2 uv = UV / 1000.0;
	uv = uv / SCREEN_PIXEL_SIZE * 2.0;
	uv.y *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec3 dir = vec3(uv*zoom, 1.);
	float time = 1.0 * speed + 0.25;
	
	vec3 from = vec3(1., 0.5, 0.5);
	from += vec3(time*2., time, -2.);
	
	float s = 0.1;
	float fade = 1.0;
	
	vec3 v = vec3(0.);
	for (int r=0; r < volsteps; r++) {
		vec3 p = from + s * dir * 0.5;
		p = abs(vec3(tile) - mod(p, vec3(tile * 2.)));
		float pa = 0.;
		float a = 0.;
		
		for (int i=0; i < iterations; i++) {
			p = abs(p) / dot(p, p) - formuparam;
			a += abs(length(p)-pa);
			pa = length(p);
		}
		
		float dm = max(0., darkmatter - a * a * 0.001);
		a *= a * a;
		if (r > 6) {
			fade *= 1. - dm;
		}
		v += fade;
		v += vec3(s, s*s, s*s*s*s)*a*brightness*fade;
		fade *= distfading;
		s += stepsize;
	}
	
	v = mix(vec3(length(v)), v, saturation);
	COLOR = vec4(v * 0.01, 1.);
}