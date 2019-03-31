// https://www.shadertoy.com/view/MlKfWm

#define iTime iGlobalTime

// FabriceNeyret2 346 chars
#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))

void mainImage(out vec4 O,  vec2 U) {
    vec2 R = iResolution.xy;
    U = 2.* (2. * U - R) / R.y;
    
    for (int i = 0; i < 4; i++) {
        float n = 8.,
              a = atan(U.x, U.y),
              l = length(U);
        n = 6.28 / n;
        a = mod(a + n/2., n) - n/2.;
        U = l * vec2(cos(a), sin(a)) - vec2(1, 0);
    }
    
    float s = .5;
    for (int i = 0; i < 8; i++) {
    	U = abs(U) / dot(U, U) - s;
        U *= rot(iTime * .1);
        s *= .9;
    }
    O = vec4( .1 / length(U) );
}

/* original 598 chars

#define R iResolution.xy
#define T iTime

mat2 rotate(float a) {
	float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

vec2 modPolar(vec2 uv, float n) {
	float a = atan(uv.x, uv.y);
    float l = length(uv);
    n = 6.28 / n;
    a = mod(a + n * .5, n) - n * .5;
    return l * vec2(cos(a), sin(a)) - vec2(1., 0.);
}


float fractal(vec2 uv) {
    float s = .5;
    for (int i = 0; i < 8; i++) {
    	uv = abs(uv) / dot(uv, uv);
        uv -= s;
        uv *= rotate(T * .1);
        s *= .9;
    }
    return .1 / length(uv);
}


vec3 render(vec2 uv) {
    uv *= 2.;
    vec3 col = vec3(0.);
    for (int i = 0; i < 4; i++)
        uv = modPolar(uv, 8.);
    col += fractal(uv);
    return col;
}

void mainImage(out vec4 O, in vec2 I) {
    vec2 uv = (2. * I - R) / R.y;
    vec3 col = render(uv);
    O = vec4(col, 1.);
}
*/