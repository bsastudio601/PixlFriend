
shader_type canvas_item;
render_mode unshaded;

uniform float scanline_strength : hint_range(0.0, 0.15) = 0.025;
uniform float scanline_density : hint_range(50.0, 800.0) = 220.0;
uniform float flicker_strength : hint_range(0.0, 0.02) = 0.002;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float scanline = 1.0 - scanline_strength *
	    (0.5 + 0.5 * sin(
	        (UV.y * scanline_density) - TIME * 3.5
	    ));

    float flicker = 1.0 +
        flicker_strength * sin(TIME * 5.0);

    COLOR = vec4(
        min(tex.rgb * scanline * flicker, vec3(1.0)),
        tex.a
    );
}
