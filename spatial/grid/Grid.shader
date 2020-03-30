//MIT License
//Copyright (c) 2020 Master-J
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

//Procedural grid shader

shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass;

uniform vec4 grid_color : hint_color = vec4(vec3(0.0),1.0);
uniform vec4 background_color : hint_color = vec4(vec3(0.0),0.0);

uniform vec4 emission_color : hint_color = vec4(vec3(0.0),1.0);
uniform float emission_strength : hint_range(0.0, 10.0) = 1.0;

uniform float line_thickness : hint_range(0.001, 0.5) = 0.01;
uniform int cell_count = 10;

void fragment()
{
    float x = fract(UV.x * float(cell_count));
    x = min(x, 1.0 - x);
    x = smoothstep(x - fwidth(x), x + fwidth(x), line_thickness);

    float y = fract(UV.y * float(cell_count));
    y = min(y, 1.0 - y);
    y = smoothstep(y - fwidth(y), y + fwidth(y), line_thickness);

    float grid = clamp(x + y, 0.0, 1.0);

	vec4 color = mix(background_color, grid_color, grid);
	
	ALBEDO = color.rgb;
	EMISSION = emission_color.rgb * emission_strength * color.a;
    ALPHA = color.a;
}
