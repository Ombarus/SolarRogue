shader_type canvas_item;

uniform vec2 swirl_center = vec2(0.5,0.5);

uniform float swirl_radius = 0.2;
uniform float swirl_amount = 0.2;
uniform float swirl_power = 2;
uniform vec4 center_color = vec4(0.7, 0.7, 0.4, 1.0);

float shelf_curve(float x) {
	return clamp(1.0 - ((2.0*x)*(2.0*x)), 0.0, 1.0);
}

vec2 swirl4(vec2 tex_uv, vec2 screen_uv, vec2 center, float rad, float amount) {
	vec2 offset = screen_uv - center;
	float d = length(offset);
	vec2 dir = normalize(offset);
	
	float shelf = shelf_curve(length(tex_uv-vec2(0.96875, 0.09375)));
	
	float displacement = amount / (d * d + 0.01);
	
	vec2 uv = screen_uv + dir * (displacement);
	return uv;
}

vec2 swirl3(vec2 screen_uv, vec2 center, float _rad, float amount) {
	vec2 offset = screen_uv - center;
	float rad = length(offset);
	float deformation = 1.0 / pow(rad * pow(amount, 0.5), 2.0) * _rad * 0.1;
	offset = offset * (1.0 - deformation);
	
	
	offset += center;
	
	if (rad < 0.04) {
		offset = vec2(-1.0, -1.0);
	}
	return offset;
}

vec2 swirl2(vec2 screen_uv, vec2 center, float rad, float amount) {
	vec2 coords_polar = screen_uv - center;
	float r = length(coords_polar);
	if (r <= rad) {
		float percent = (rad - r) / rad;
		float theta = percent * percent * amount * 8.0;
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

	vec2 aspect = vec2(2048.0,2048.0) / vec2(1024.0,1024.0);
	vec2 screen_uv = SCREEN_UV;
	vec2 tex_uv = UV;
	vec2 center = ((vec2(0.96875, 0.09375) - tex_uv) * aspect) + screen_uv;
	//vec2 coords = swirl2(screen_uv, center, swirl_radius, swirl_amount);
	vec2 coords = swirl2(screen_uv, center, swirl_radius, swirl_amount);
	vec4 c = vec4(0.0, 0.0, 0.0, 1.0);
	vec2 coord_tex = swirl3(UV, vec2(0.96875, 0.09375), 0.06, 4);
	vec4 c_tex = texture(TEXTURE, coord_tex).rgba;
	coords = swirl3(coords, center, swirl_radius, swirl_amount);
	c = textureLod(SCREEN_TEXTURE, coords, 0.0).rgba;
		
	if (coords.x < 0.0) {
		c = center_color;
	}
	
	float blend_alpha = 0.0;
	c = vec4(c.r + (c_tex.r*c_tex.a*blend_alpha), c.g + (c_tex.g*c_tex.a*blend_alpha), c.b + (c_tex.b*c_tex.a*0.0), 1.0);
	
    COLOR.rgba = c;
	//COLOR.rgb = vec3(r, 0.0, 0.0);
}