// https://www.shadertoy.com/view/MsSSRV

#define iTime iGlobalTime

vec2 cmul(vec2 a, vec2 b) {
    return a * mat2(b.x, -b.y, b.y, b.x);
}

vec2 cinv(vec2 z) {
    return vec2(z.x, -z.y) / dot(z, z);
}

vec2 cdiv(vec2 a, vec2 b) {
    return cmul(a, cinv(b));
}

vec2 invmobius(vec2 z, vec2 a, vec2 b, vec2 c, vec2 d) {
    return cdiv(cmul(d,z)-b, a-cmul(c,z));
}

vec2 map(vec2 p) {
    float time = iTime * 0.1;
    vec2 t = vec2(sin(time), 0.0);
    vec2 a = vec2(cos(time*5.0), sin(time*5.0));
    vec2 b = vec2(0.0, 0.0);
    vec2 c = t * cos(iTime * 0.25) * 10.0;
    vec2 d = vec2(1.0, 1.0);
    return invmobius(p, a, b, c, d);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 aspect = vec2(iResolution.x / iResolution.y, 1.0);
    
    vec2 a = ((fragCoord.xy + vec2(0.0, 0.0)) / iResolution.xy * 2.0 - 1.0) * aspect;
    vec2 b = ((fragCoord.xy + vec2(1.0, 0.0)) / iResolution.xy * 2.0 - 1.0) * aspect;
    vec2 c = ((fragCoord.xy + vec2(1.0, 1.0)) / iResolution.xy * 2.0 - 1.0) * aspect;
    vec2 d = ((fragCoord.xy + vec2(0.0, 1.0)) / iResolution.xy * 2.0 - 1.0) * aspect;

    vec2 ma = map(a);
    vec2 mb = map(b);
    vec2 mc = map(c);
    vec2 md = map(d);
    
    float da = length(mb-ma);
    float db = length(mc-mb);
    float dc = length(md-mc);
    float dd = length(ma-md);
    
    /* try to anti-alias by flattening the colours when the transformation causes too much stretch */
	float stretch = max(max(max(da,db),dc),dd);
    float aa = 1.0 / (1.0 + stretch * stretch * 10000.0);
    
    vec2 block = floor(ma * 10.0 + 0.5);
	vec2 square = abs(ma - block / 10.0);
    square *= aa;
    float an = iTime * 0.1 ;
    vec2 rot = cmul(square, vec2(cos(an), sin(an)));
    
    vec3 r;
    r.x = (0.5 + sin(rot.x * 100.0 + iTime * 0.5) * 0.5);
    r.y = (0.5 + sin(rot.y * 100.0) * 0.5);
    r.z = (0.5 + sin(square.y * 100.0 + iTime) * 0.5);
    
    fragColor = vec4(r, 1.0);
}