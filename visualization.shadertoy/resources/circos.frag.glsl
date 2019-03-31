// https://www.shadertoy.com/view/XltSRr

#define iTime iGlobalTime

float trad = 1.0;
float tdz = 0.0;

float map(vec3 p)
{
    tdz = p.z;
    return trad - length(p.xy);
}

vec3 normal(vec3 p)
{
	vec3 o = vec3(0.01, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy) - map(p-o.xyy),
                          map(p+o.yxy) - map(p-o.yxy),
                          map(p+o.yyx) - map(p-o.yyx)));
}

float trace(vec3 o, vec3 r)
{
    float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        t += map(o + r * t);
    }
    return t;
}

vec3 textex(sampler2D channel, vec3 p)
{
    vec3 ta = texture2D(channel, vec2(p.y,p.z)).xyz;
    vec3 tb = texture2D(channel, vec2(p.x,p.z)).xyz;
    vec3 tc = texture2D(channel, vec2(p.x,p.y)).xyz;
    return (ta*ta + tb*tb + tc*tc) / 3.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    uv = uv * 2.0 - 1.0;
    
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 o = vec3(0.0, 0.0, 10.0 + iTime);
    vec3 r = normalize(vec3(uv, 1.0));
    
    float rt = iTime * 0.5;
    r.xz *= mat2(cos(rt), sin(rt), -sin(rt), cos(rt));
    
    float fa = 3.14158 * 0.25;
    r.xy *= mat2(cos(fa), sin(fa), -sin(fa), cos(fa));
    
    vec3 rc = vec3(0.0);
    float bn = 1.0;
    
    for (int i = 0; i < 4; ++i) {
        float ni = float(i) / 8.0;
    
        trad = mix(0.25, 10.0, ni);
        vec3 to = o + vec3(0.0, 0.0, ni);
        float t = trace(to, r);
        vec3 w = to + r * t;

        float c = floor(mix(2.0, 8.0, ni));

        float rad = fract(w.z * c);
        float frad = floor(tdz * c);
        float th = atan(w.y, w.x) + frad;
        th = th / 3.14159 * 0.5 + 0.5;
        th += 0.05 * iTime * cos(frad * 3.14159);

        vec3 ac = vec3(1.0);
        ac /= (1.0 + t * t * 0.1);
        
        vec3 tw = w * vec3(1.0, 1.0, 1.0);
        float tt = th * frad;
        tw.xy *= mat2(cos(tt), -sin(tt), sin(tt), cos(tt));
		vec3 cm = textex(iChannel0, tw);
        
        vec3 sn = normal(w);

        float td = fract(th * c);
        float tdn = mix(0.8, 0.95, ni);
        float bin = max(sign(tdn - td), 0.0);
        float bk = 1.0 / (1.0 + td * max(tdn - td, 0.0) * 200.0);
        
        float edge = 0.5;
		float ain = max(sign(edge - rad), 0.0);
        float ak = 1.0 / (1.0 + rad * max(edge - rad, 0.0) * 100.0);
        
        float mask = ain * bin;
        vec3 fullc = ac * cm;
        vec3 alphc = ac * cm * 0.125;
        
        rc += mix(fullc, alphc, ak + bk) * bn * mask;
        bn = min(bn * (1.0 - mask), ak + bk);
    }
    
	fragColor = vec4(sqrt(rc), 1.0);
}
