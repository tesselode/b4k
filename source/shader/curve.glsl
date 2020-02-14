uniform float curve = 2;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 texturecolor = Texel(tex, texture_coords);
	for (int i = 0; i < 4; i++)
		texturecolor[i] = pow(texturecolor[i], curve);
    return texturecolor * color;
}
