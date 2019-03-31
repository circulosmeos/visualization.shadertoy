// https://www.shadertoy.com/view/XtGcWK

#define iTime iGlobalTime

/*
	Psychedelic Fractal test
	
	Derived from a shader by Kali -
		https://www.shadertoy.com/view/ltB3DG

*/
/*
//------------------------------------------------
// Fabrice Neyret V2 [195 chars]
#define mainImage(O,I)                             \
    vec2 R = iResolution.xy,                       \
         p = ( I+I - R ) / R.y;                    \
    for (int c = 0; c < 3; c++)                    \
        for (float s = 1.; s > .2; s *= .8 )       \
            O[c] += s * .064 /                     \
            length( p = ( abs(p) / dot(p, p) - s ) \
                       * mat2(cos( iTime*.5+.05*float(c) + vec4(0,33,11,0))) )
*/

// Fabrice Neyret golfed version ;) [199 chars]
/*            
#define mainImage(O,I)                    \
    vec2 R = iResolution.xy,              \
         p = ( I+I - R ) / R.y;           \
    for (int c = 0; c < 3; c++)           \
        for (float t = iTime+.1*float(c),s = 1.; s > .2; s *= .8 ) \
            p = abs(p) / dot(p, p) - s,   \
            O[c] += s * .064 / length( p *= mat2(cos( t*.5 + vec4(0,33,11,0))) )

*/

// Expanded Original Version [432 chars]


#define R iResolution.xy
#define T iTime

mat2 rotate(float a) {
    float c = cos(a),
        s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 render(vec2 uv) {

    vec3 color = vec3(0.);
    vec2 p = uv;
	
    // per channel iters
    float t = T;
    for (int c = 0; c < 3; c++) {
    
        t += .1; // time offset per channel
        
		float l = 0.;
        float s = 1.;
        for (int i = 0; i < 8; i++) {
            // from Kali's fractal iteration
            p = abs(p) / dot(p, p);
            p -= s;
            p *= rotate(t * .5);
            s *= .8;
            l += (s  * .08) / length(p);
        }
        color[c] += l;
    
    }

	return color;

}

void mainImage(out vec4 O, in vec2 I) {
	vec2 uv = (2. * I - R) / R.y;
    vec3 color = render(uv);
	O = vec4(color, 1.);
}

