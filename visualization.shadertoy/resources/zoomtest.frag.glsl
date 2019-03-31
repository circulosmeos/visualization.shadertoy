// https://www.shadertoy.com/view/lt23WV

#define iTime iGlobalTime*0.3

const float pi = 3.14159;

mat3 xrot(float t)
{
    return mat3(1.0, 0.0, 0.0,
                0.0, cos(t), -sin(t),
                0.0, sin(t), cos(t));
}

mat3 yrot(float t)
{
    return mat3(cos(t), 0.0, -sin(t),
                0.0, 1.0, 0.0,
                sin(t), 0.0, cos(t));
}

mat3 zrot(float t)
{
    return mat3(cos(t), -sin(t), 0.0,
                sin(t), cos(t), 0.0,
                0.0, 0.0, 1.0);
}

vec3 paxis(vec3 p)
{
    vec3 a=abs(p),r = vec3(1.0,0.0,0.0);
    if(a.z>=max(a.x,a.y))r=r.yzx;
    else if(a.y>=a.x)r=r.zxy;
    return r*sign(p);
}

vec3 ddt(vec3 s)
{
    vec3 r;
    vec3 as = abs(s);
    r.x = s.x * min((1.0 - as.y),(1.0 - as.z));
    r.y = s.y * min((1.0 - as.x),(1.0 - as.z));
    r.z = s.z * min((1.0 - as.x),(1.0 - as.y));
    return r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sdBoxInfinite( vec3 p, vec3 b )
{
  vec2 d = abs(p.xy) - b.xy;
  return min(max(d.x,d.y),0.0) +
         length(max(d,0.0));
}

vec2 map(vec3 p)
{
    float k = 12.0;

    p.z = (fract(p.z/k) * 2.0 - 1.0) * k * 0.5;
    
    vec3 op = p;
    
    float d = 1000.0;
    
    vec3 ip = p;
    
    float bs = 1.0;
    float r = 0.0;
    
    const int it = 6;
    for (int i = 0; i < it; ++i) {

        float nbs = bs;
        bs = nbs * 0.5;

        vec3 pn = paxis(ip);
        
        vec3 apn = abs(pn);
        
        pn += sign(pn) * max(apn.x,max(apn.y,apn.z));
        
        vec3 disp = ddt(normalize(ip));
        
        pn += disp * 3.0;

        ip -= pn * nbs;

        float fd = length(ip) - nbs;
        
        if (fd < d) {
            d = fd;
            r = float(i);
        }
        
        float nm = float(i) / float(it-1);
        float rd = mix(1.5, 0.5, nm);
        //d = max(d, rd-length(op.xy));
        d = max(d, -sdBoxInfinite(op,vec3(rd)));
    }
    
    return vec2(d,r);
}

vec3 normal(vec3 p)
{
    vec3 o = vec3(0.01, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy).x - map(p-o.xyy).x,
                          map(p+o.yxy).x - map(p-o.yxy).x,
                          map(p+o.yyx).x - map(p-o.yyx).x));
}

float trace(vec3 o, vec3 r)
{
    float t = 0.0;
    for (int i = 0; i < 32; ++i) {
        vec3 p = o + r * t;
        float d = map(p).x;
        t += d * 0.5;
    }
    return t;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 r = normalize(vec3(uv, 0.25 - dot(uv,uv) * 0.33));
    r *= zrot(iTime);
    vec3 o = vec3(0.0, 0.0, -10.0);
    o.z += iTime;
    
    float t = trace(o, r);
    vec3 w = o + r * t;
    vec2 mp = map(w);
    float fd = mp.x;
    float it = mp.y;
    vec3 sn = normal(w);
    float prod = max(dot(sn,-r),0.0);
    
    vec3 lpos = o + vec3(0.0, 0.0, 4.0);
    vec3 ldir = normalize(lpos - w);
    float lprod = max(dot(sn,ldir), 0.0);
    vec3 ref = reflect(sn, ldir);
    float rprod = max(dot(r, ref), 0.0);
    rprod = pow(rprod, 4.0);

    float fog = 1.0 / (1.0 + t * t * 0.001);
    float edge = 1.0 / (1.0 + fd * 100.0);
    
    vec3 diff = 0.5 + 0.5 * vec3(1.0-cos(it), cos(it), sin(w.z));
    
    diff *= prod * 4.0;
    
    diff += rprod;
    
    diff *= fog * edge;
        
    fragColor = vec4(diff,1.0);
}