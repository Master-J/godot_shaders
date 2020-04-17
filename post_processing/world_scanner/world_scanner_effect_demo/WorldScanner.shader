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

//Original source code :
//https://github.com/Broxxar/NoMansScanner/blob/master/Assets/Scanner%20Effect/ScannerEffect.shader


//World scanner post process effect

//How to use :
//	(1) Create quad mesh, make it a child of a camera
//	(2) Set width and height to 2
//	(3) Add shader material and assign this shader
//	(4) Edit the z-near and z-far to fit those of your current camera
//	(5) In the Material's properties, change the render priority to -1, if you don't do that the shader won't blend properly with transparent geometry

shader_type spatial;

render_mode unshaded, depth_draw_never;

uniform vec3		scanner_position	= vec3(0.0);	//Center position of the effect's circle
uniform float		scanning_range		= 0.0;			//Current radius of the effect's circle
uniform float		scan_width			= 1.0;			//Thickness of the effect's circle

uniform sampler2D	scan_gradient		: hint_albedo;	//Color gradient of the effect's circle
uniform sampler2D	scan_pattern		: hint_white;	//Give this texture should be a tileable grayscale to give the effect a custom look, white is opaque, black is transparent
uniform vec2		pattern_scale		= vec2(1.0);	//UV scale of the pattern texture
uniform float		emission_strength	: hint_range(0.0, 10.0)	= 1.0;	//Emission strenght of the effect, in tandem with a glow post process effect to get nice results
uniform float		alpha_blend			: hint_range(0.0, 1.0)	= 1.0;	//Overall transparency for the effect, animate this property for nice fade-in/fade-out transitions

uniform float		z_far = 1000.0;	//Z-Far value of the current camera, you must set this to prevent the effect from artefacting with the far plane

varying mat4 CAMERA;

float remap_value (float value, float old_min, float old_max, float new_min, float new_max)
{
	return new_min + (value - old_min) * (new_max - new_min) / (old_max - old_min);
}

void vertex() {
	//Turn the quat into a full screen quat matching the camera's view
	POSITION = vec4(VERTEX, 1.0);
	CAMERA = CAMERA_MATRIX;
}

void fragment() {
	//Compute the fragment's world position from depth (taken from the official godot documentation)
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	vec4 world = CAMERA * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	//Distance between the current fragment and the effect's origin
	float dist = distance(scanner_position, world_position);

	vec4 scan_color = vec4(0.0);

	//Test if we're in the effect's circle or not
	if (dist < scanning_range && dist > scanning_range - scan_width && -view.z < (z_far - 0.01))
	{
		//Compute a gradient within the effect's border
		float gradient = 1.0 - (scanning_range - dist) / scan_width;

		vec2 gradient_uv = vec2(gradient, 0.0);
		
		//Compute the direction from the effect's origin and the fragment's position
		vec3 scan_direction = normalize(scanner_position - world_position);

		//Compute the angle between the global forward vector and the scan direction in order to generate the X uv coordinate of the effect's circle
		vec2 pattern_uv = vec2(acos(dot(scan_direction, vec3(0.0, 0.0, 1.0))), 1.0 - gradient);
		//Remap the X coordinate to simplify pattern scaling
		pattern_uv.x = remap_value(pattern_uv.x, 0.0, 6.28318530718, 0.0, 1.0);

		//Sample the effect's color
		scan_color = texture(scan_gradient, gradient_uv);
		scan_color.a = texture(scan_pattern, pattern_uv * pattern_scale).r;
	}

	ALBEDO = scan_color.rgb * emission_strength;
	ALPHA = scan_color.a * alpha_blend;
}