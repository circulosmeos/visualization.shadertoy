// https://www.shadertoy.com/view/MlGcz3

#define iTime iGlobalTime

/*
	Psychedelic Grid test
*/
#define R iResolution.xy
#define T iTime

float mlength(vec2 uv) {
	uv = abs(uv);
    return uv.x + uv.y;
}

mat2 rotate(float a) {
	float c = cos(a), 
        s = sin(a);
    return mat2(c, -s, s, c);
}

float sinp(float v) {
	return .5 + .5 * sin(v);
}

float sinr(float v, float a, float b) {
	return mix(a, b, sinp(v));
}

float shape(vec2 uv) {

    vec2 f = fract(uv) - .5;
	
    // trying manhattan dist
    vec2 st = vec2(atan(f.x, f.y), mlength(f));

	float k = sinr(T * .05, 2., 12.);
    float a = 4.;
    
    return cos(st.y * k + st.x * a + T) * 
        	cos(st.y * k - st.x * a + T) * 
        	smoothstep(.2, .8, st.y);
    
}

vec3 render(vec2 uv) {

    uv = abs(uv) - sinr(T * .5, .25, .5);
   	// find better method than clamping
    float t = shape(uv) + 
        clamp(abs(.2 / shape(uv)) * .25, .0, 2.); // glow
   
    // rotate, scale and layer
    uv *= rotate(.785);
    t *= shape(uv) + 
        clamp(abs(.03 / shape(uv)) * .25, .0, .9);
    //t *= length(uv);
   
    
    return mix(vec3(t, .4, sinr(T, .3, .8)), // osc channel
               vec3(.1, .0, .3), t);
}

void mainImage(out vec4 C, in vec2 U) {
   	vec2 uv = rotate(T * .05) * 
        sinr(T * .25, .5, 2.) * (2. * U - R) / R.y;
   	C = vec4(render(uv), 1.);
}

