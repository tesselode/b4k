uniform vec2 offset;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 c = vec4(0);
	c += 5.0 * Texel(tex, texture_coords - offset);
	c += 6.0 * Texel(tex, texture_coords);
	c += 5.0 * Texel(tex, texture_coords + offset);
    return c / 16.0 * color;
}
