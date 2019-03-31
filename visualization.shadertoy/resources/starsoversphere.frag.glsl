// https://www.shadertoy.com/view/lsGGWt

#define iTime iGlobalTime

/*
Original work:
http://gif.flrn.nl/post/140050674884
*/

/*
Original sphere code from tenderfoot
https://www.shadertoy.com/view/XdXXRj
*/

vec3 light = vec3(2., 2., 1.); // circulosmeos: numbers changed
vec3 light_color = vec3(1, 1, 1);

vec3 sphere = vec3(0, 0, 2);
float sphere_size = 1.3;
vec3 sphere_color = vec3(1, 1, 1);

float raySphere(vec3 rpos, vec3 rdir, vec3 sp, float radius, inout vec3 point, inout vec3 normal) {
	radius = radius * radius;
	float dt = dot(rdir, sp - rpos);
	if (dt < 0.0) {
		return -1.0;
	}
	vec3 tmp = rpos - sp;
	tmp.x = dot(tmp, tmp);
	tmp.x = tmp.x - dt*dt;
	if (tmp.x >= radius) {
		return -1.0;
	}
	dt = dt - sqrt(radius - tmp.x);
	point = rpos + rdir * dt;
	normal = normalize(point - sp);
	return dt;
}

#define TWO_PI 6.28318530718

vec3 texture2(vec2 uv){
    vec2 st = uv;
    
    float radius = 0.8;
    
    //tile
    vec2 frequency = vec2(8.0, 8.0);
    vec2 index = floor(frequency * st)/frequency;
    float centerDist = 1.0-length(index-0.5);
    vec2 nearest = 2.0 * fract(frequency * st) - 1.0;
    
    //movement
    // circulosmeos: code changed to sync with music: bass
    float bass = texture2D( iChannel0, vec2(400.,0.) ).x * 30.;
    float velocity = 10.0;
    nearest.x += cos(iTime * velocity + centerDist * TWO_PI)*(1.0-radius)/2.0;
    //nearest.y += sin(iTime * velocity + centerDist * TWO_PI)*(1.0-radius)/2.0;
    nearest.y += sin(iTime * velocity + (centerDist+bass) * TWO_PI)*(1.0-radius)/2.0;
    
    //astroid
    float astroid = length(nearest)<radius ? 1.0 : 0.0;
    float dist = length(nearest-vec2(radius, radius));
    astroid *= step(radius, dist);
    dist = length(nearest-vec2(-radius, radius));
    astroid *= step(radius, dist);
    dist = length(nearest-vec2(-radius, -radius));
    astroid *= step(radius, dist);
    dist = length(nearest-vec2(radius, -radius));
    astroid *= step(radius, dist);
    astroid = 1.0 - astroid;
    
    //colors
    vec3 bgColor = vec3(0.1, 0.1, 0.1);
    
    float totalColors = 8.0;
    float cIndex = floor((index.x+(index.y*4.0))*totalColors);
    cIndex = mod(cIndex, totalColors);
    vec3 color = vec3(0.0);
    if(cIndex==0.0) color = vec3(0.92, 0.35, 0.20);
    else if(cIndex==1.0) color = vec3(0.50, 0.77, 0.25);
    else if(cIndex==2.0) color = vec3(0.00, 0.63, 0.58);
    else if(cIndex==3.0) color = vec3(0.08, 0.45, 0.73);
    else if(cIndex==4.0) color = vec3(0.38, 0.18, 0.55);
    else if(cIndex==5.0) color = vec3(0.76, 0.13, 0.52);
    else if(cIndex==6.0) color = vec3(0.91, 0.13, 0.36);
    else if(cIndex==7.0) color = vec3(0.96, 0.71, 0.17);
    
    color = mix(color, bgColor, astroid);
    
    return color;   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	light.xy = iMouse.xy / iResolution.xy * 2.0 - 1.0;
	light.y = -light.y;
    
    vec3 point; 
	vec3 normal;
	vec2 uv = fragCoord.xy / iResolution.xy * 2.0 - 1.0;
	uv.x *= iResolution.x / iResolution.y;
	uv.y = -uv.y;
    
	vec3 ray = vec3(uv.x, uv.y, 1.0);
	ray = normalize(ray);
	fragColor = vec4(vec3(0.1), 1.0);
	
	float dist = raySphere(vec3(0.0), ray, sphere, sphere_size, point, normal);
	
	if (dist > 0.0) {
		vec3 tmp = normalize(light - sphere);
		float u = atan(normal.z, normal.x) / 3.1415*2.0 + iTime / 5.0;
		float v = asin(normal.y) / 3.1415*2.0 + 0.5;
	    fragColor.xyz = vec3(dot(tmp, normal)) * light_color * sphere_color * texture2(vec2(u, v));
	}
}