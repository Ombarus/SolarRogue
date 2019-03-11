shader_type canvas_item;

uniform vec2 swirl_center = vec2(0.5,0.5);

uniform float swirl_radius = 0.2;
uniform float swirl_amount = 0.2;
uniform float swirl_power = 2;

vec2 swirl2(vec2 screen_uv, vec2 center) {
	vec2 coords_polar = screen_uv - center;
	float r = length(coords_polar);
	if (r <= swirl_radius) {
		float percent = (swirl_radius - r) / swirl_radius;
		float theta = percent * percent * swirl_amount * 8.0;
		float s = sin(theta);
		float c = cos(theta);
		coords_polar = vec2(dot(coords_polar, vec2(c, -s)), dot(coords_polar, vec2(s, c)));
	}
	
	coords_polar += center;
	return coords_polar;
}


vec2 swirl(vec2 screen_uv, vec2 center) {
	// Convert to polar coordinates
	// Get the relative position to the swirl_center
	vec2 coords_polar = screen_uv - center;
	float r = length(coords_polar);
	if (r <= swirl_radius) {
		float phi = atan(coords_polar.y, coords_polar.x);
		float distortion = pow(swirl_amount * ((swirl_radius - r) / swirl_radius), swirl_power);
		if (swirl_amount >= 0.0) {
			phi = phi + distortion;
		}
		else {
			phi = phi - distortion;
		}
		
		coords_polar.x = r * cos(phi);
		coords_polar.y = r * sin(phi);
	}
	
	// Convert it back to global space
	return coords_polar + center;
}

void fragment() {

	vec2 aspect = vec2(2048.0,2048.0) / vec2(1024.0,600.0);
	vec2 screen_uv = SCREEN_UV;
	vec2 tex_uv = UV;
	vec2 center = ((vec2(0.96875, 0.09375) - tex_uv) * aspect) + screen_uv;
	vec2 coords = swirl2(screen_uv, center);
	
	vec4 c = textureLod(SCREEN_TEXTURE, coords, 0.0).rgba;
	//vec4 tex_col = textureLod(TEXTURE, tex_uv, 0.0).rgba;

	//c = mix(c, vec4(1.0,1.0,1.0,1.0), 1.0-(length(((vec2(0.96875, 0.09375) - tex_uv) * aspect)))*2.0);
	
    COLOR.rgba = c;
	//COLOR.rgb = vec3(r, 0.0, 0.0);
}