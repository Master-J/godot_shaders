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

//Original source code by Broxxar, Unlicensed :
//https://github.com/Broxxar/NoMansScanner/blob/master/Assets/Scanner%20Effect/ScannerEffect.shader

//World scanner post process effect

//How to use :
//	(1) Create quad mesh, make it a child of a camera
//	(2) Set width and height to 2
//	(3) Add shader material and assign this shader
//	(4) Edit z-far to match the camera's z_far value
//	(5) Assign a gradient texture to scan_gradient, the gradient's colors will behave like emission colors, so black is transparent, white is opaque
//	(6) scanning_range controls the current radius of the scanner effect, animate this value over time from script/animation player to grow/shrink the scanner
//	(7) scan_width controls of thick the scanner circle is
//	(8) scanner_position is the center of the scanner circle in world coordinates

shader_type spatial;

render_mode unshaded, depth_draw_never;

uniform float scanning_range = 0.0;
uniform float scan_width = 1.0;

uniform sampler2D scan_gradient : hint_albedo;

uniform vec3 scanner_position = vec3(0.0);

uniform float z_far = 100.0;

varying mat4 CAMERA;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = CAMERA_MATRIX;
}

void fragment() {
	//Compute fragment world position from depth
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	//Get the original scene render
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	
	//Distance between the fragment and the starting position of the effect
	float dist = distance(scanner_position, world_position);
	
	vec3 scan_color = vec3(0.0);
	
	//Create the scanner circle
	if (dist < scanning_range && dist > scanning_range - scan_width && -view.z < (z_far - 0.01))
	{
		//Create a 0 to 1 gradient between the circle's borders
		float gradient = 1.0 - (scanning_range - dist) / scan_width;
		scan_color = texture(scan_gradient, vec2(gradient, 0.0)).rgb;
	}
	ALBEDO = screen_color + scan_color;
}