// https://www.shadertoy.com/view/XlKXRy

#define iTime iGlobalTime

precision highp float;

#define sin1(x) (.5+sin(x)*.5)
#define cos1(x) (.5+cos(x)*.5)
#define saw1(x) abs(fract(x))
#define saw(x) (abs(fract(x)-.5)*2.)
#define ss smoothstep

const float pi = 3.14159265;
const float pi2 = pi*2.;
const float pi4 = pi*4.;
#define resolution iResolution.xy
#define time (iTime*.5)

vec3 rgb2hsv(vec3 c)
{
	vec4 X = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, X.wz), vec4(c.gb, X.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
	vec4 k= vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

vec2 mm(vec2 p)
{
	return vec2(min(p.x,p.y),max(p.x,p.y));
}
vec2 rc(vec2 p)
{
	vec2 m=mm(p);
	float r=m.y/m.x;
	float s=step(p.y,p.x);
	return vec2(mix(1.,r,s),mix(r,1.,s));
}

mat2 rot(float a)
{
	float c=cos(a);
	float s=sin(a);
	return mat2(-s,c,c,s);
}

float gr(float t,float d)
{
	return smoothstep(.0,clamp(.0,1.,d),fract(time*t))+floor(time*t);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy/resolution.xy;
	vec3 col=vec3(.0);
	vec2 p=-1.+2.*uv;
	p*=rc(resolution);
	float t=gr(.25,.5);
	float g=gr(.5,.5);

	vec2 q=p;
    q*=3.;
	q=saw(q+.5)-.5;
    q*=rot(t*pi/4.);
	float a=atan(q.y,q.x);
	float d=length(q);
	float m=max(abs(q.x),abs(q.y));

	col=mix(vec3(1.,.8,.0),
		vec3(.1,.4,.8)
		,ss(.5,.495,saw1(a*4./pi4
			+sin((g*.5+t)*pi)*ss(.5,.0,d)
			)));

    vec3 hsv = rgb2hsv(col);
    hsv.x += t*.1;
    col = hsv2rgb(hsv);
    vec2 r = saw(50.*p);     // circulosmeos: numbers changed
	col*= r.x*r.y;

	col*=1.3;
    col*=ss(2.,1.,length(p));

	fragColor = vec4( col, 1.0 );
}