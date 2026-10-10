shader_type canvas_item;
//BLEND

uniform sampler2D layer_tex : filter_nearest, repeat_enable;
uniform sampler2D palette_tex : filter_nearest, repeat_disable;
uniform bool palette_enabled = false;
uniform float palette_index = 0.0;

uniform vec2 canvas_size = vec2(320.0, 180.0);
uniform vec2 tex_scale = vec2(1.0);
uniform vec2 tex_offset = vec2(0.0);
uniform ivec2 axis_mode = ivec2(0);
uniform vec2 axis_frequency = vec2(16.0);
uniform vec2 axis_amplitude = vec2(0.0);
uniform vec2 axis_shift = vec2(0.0);
uniform float opacity = 1.0;
uniform vec4 modulate_color : source_color = vec4(1.0);
uniform float plane_amplitude = 0.0;

const float DB_PI = 3.14159265;

float distort(int mode, vec2 p, float freq, float amp, float shift_amt) {
	float f = (freq == 0.0) ? 1.0 : freq;
	float wave_y = amp * sin((1.0 / f) * DB_PI * (p.y + shift_amt));
	float wave_x = amp * sin((1.0 / f) * DB_PI * (p.x + shift_amt));
	if (mode == 0) {
		return trunc(wave_y);
	}
	if (mode == 1) {
		float s = trunc(wave_y);
		return (mod(p.y, 2.0) < 1.0) ? -s : s;
	}
	if (mode == 2) {
		return trunc(wave_x);
	}
	return trunc((p.x + shift_amt) * (amp / f));
}

vec2 fisheye(vec2 p, float amp) {
	vec2 m = vec2(0.5);
	vec2 d = p - m;
	float r = length(d);
	if (r < 0.00001) {
		return p;
	}
	float corner = length(m);
	float power = (2.0 * DB_PI / (2.0 * corner)) * amp;
	if (power > 0.0) {
		return m + normalize(d) * tan(r * power) * corner / tan(corner * power);
	} else if (power < 0.0) {
		return m + normalize(d) * atan(r * -power * 10.0) * m.y / atan(-power * m.y * 10.0);
	}
	return p;
}

void fragment() {
	vec2 uv = UV;
	if (plane_amplitude != 0.0) {
		uv = fisheye(uv, plane_amplitude);
	}
	vec2 px = floor(uv * canvas_size);
	vec2 d = vec2(
		distort(axis_mode.x, px, axis_frequency.x, axis_amplitude.x, axis_shift.x),
		distort(axis_mode.y, px.yx, axis_frequency.y, axis_amplitude.y, axis_shift.y)
	);
	vec2 tsize = vec2(textureSize(layer_tex, 0));
	vec2 tex_px = (px + vec2(0.5) + d + tex_offset) / tex_scale;
	vec4 c = texture(layer_tex, tex_px / tsize);
	if (palette_enabled) {
		c = texture(palette_tex, vec2(c.r, palette_index));
	}
	COLOR = vec4(c.rgb * modulate_color.rgb, c.a * opacity * modulate_color.a);
}
