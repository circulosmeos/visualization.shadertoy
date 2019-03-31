// https://www.shadertoy.com/view/4sfyWB

#define iTime iGlobalTime

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define res_       iResolution
#define time_      iTime
#define shear(g)   mat2(1., 0., g, 1.)

const float PI = 3.1415926;
float scale = 22.8;

float function(float r, float t);
float solve(vec2 p);
float value(vec2 p, float size);
float voronoi_noise2(vec2 p);
vec2 hash2_2(vec2 p);
vec2 domain(vec2 uv, float s);
vec3 butterfly_mat(vec2 p, float snd);


// ----------------------------------------------------------------------------------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 uv = domain(fragCoord, .7);
    float snd = .5*texture2D(iChannel0, fragCoord).x;
    
    uv.x *= 1. - sin(time_*2.)*.2;
    if(uv.x > 0.)
    	uv *= shear((.3+sin(snd*.2))*sin(1.2*time_));
    else
        uv *= shear(-(.3+sin(snd*.2))*sin(1.2*time_));
    
    float butterfly = value(uv*scale, 0.005*scale);
    
	vec3 c = vec3(0.);
	vec3 bfmat = butterfly_mat(uv*33., snd);
    vec3 solar = smoothstep(.05, .01, butterfly)+bfmat;
    vec3 frozen = smoothstep(.05, .01, butterfly)/bfmat;
    c = mix(solar, frozen, abs(sin(time_)));
 	c = mix(c, vec3(0.), -butterfly*8.);
    
    fragColor = vec4(c, 1.);
}
// ----------------------------------------------------------------------------------------------------------------------------------


vec2 domain(vec2 uv, float s) {
    return (2.*uv.xy-res_.xy) / res_.y*s;
}

vec3 butterfly_mat(vec2 p, float snd) {
   	float r = length(p);
	float t = atan(p.y, p.x);
    
    float butterfly = 
        7. - .5*sin(t) + 2.5*sin(3.*t) + 2.*sin(5.*t) - 1.7*sin(7.*t) +
        3.*cos(2.*t) - 2.*cos(4.*t) - 0.4*cos(16.*t) - r;
	float vor = voronoi_noise2(abs(p));
    
    vec3 c = vec3(0.+snd*.5);
    c.g += .4*smoothstep(-5.1, .3, butterfly);
    c.r += .6*smoothstep(-6.1, .3, butterfly/vor);
    
    c.r += .2*smoothstep(.1, 0., butterfly);
    c.g += .1*smoothstep(-.2, 0., butterfly*vor);
    
   
    return c;
}

float function(float r, float t) {
	float butterfly = 
        7.2 - .5*sin(t) + 2.5*sin(3.*t) + 2.*sin(5.*t) - 1.7*sin(7.*t) +
        3.*cos(2.*t) - 2.*cos(4.*t) - 0.4*cos(16.*t) - r;
    return butterfly;
}

float solve(vec2 p) {
	float r = length(p);
	float t = atan(p.y, p.x);
	
	float v = 1000.;
	for(int i=0; i<32; i++ ) {
		v = min(v, abs(function(r,t)));
		t += PI*2.;
	}
    
	return v;
}

float value(vec2 p, float size) {
	float error = size;
	return 1. / max(solve(p) / error, 1.);
}

vec2 hash2_2(vec2 p) {
	p = vec2( dot(p,vec2(127.1,311.7)),
			  dot(p,vec2(269.5,183.3)));
    return -1.0 + 2.0 * fract(sin(p)*43758.5453123);
}

float voronoi_noise2(vec2 p){
	vec2 g = floor(p), o; p -= g;
	vec3 d = vec3(1.); 
    
	for(int y = -2; y <= 2; y++){
		for(int x = -2; x <= 2; x++){
            
			o = vec2(x, y);
            o += hash2_2(g + o) - p;
            
			d.z = max(dot(o.x, o.x), dot(o.y, o.y));    
            d.y = max(d.x, min(d.y, d.z));
            d.x = min(d.x, d.z); 
                       
		}
	}
    return max(d.y/1.2 - d.x*1., 0.)/1.2;  
}