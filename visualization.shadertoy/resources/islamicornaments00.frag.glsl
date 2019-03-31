// https://www.shadertoy.com/view/XlscWf

#define iTime iGlobalTime

/*
Islamic geometric art ornament. Obtained through foldings and ray mirroring. There is still
some work to do:
- More comments :P

Ref: G.S. Kaplan: "Computer Graphics and Geometric Ornamental Design", P.H.D. thesis, 2002.
[url]www.cgl.uwaterloo.ca/csk/phd/kaplan_diss_full_print.pdf[/url]

Shader by knighty.

Licence: public domain.

*/

//Gamma attempt
#define GAMMA 2.2

//uncomment me!
//#define SIMPLE

//Make it dance!
#define WOBBLE 0.7

//Comment me! Looks better and less complicated but without animation.
//There is an "error" thought.
#define VARIANT2

float aaScale;
float lineWidth = 0.;
vec3 linesCol = vec3(0.6,0.75,.8);
vec3 linesBorderCol = vec3(0.,0.,0.);

//foldings constants
const vec2 rect = vec2(1.,1.3763819204711735382072095819109);// vec2(1, tan(3PI/10))
const vec3 f0 = vec3(0.80901699437494742410229341718282, -0.58778525229247312916870595463907, 0.);// vec3(cos(2PI/10, -sin(2PI/10),0)
const vec3 f1 = vec3(-0.58778525229247312916870595463907,-0.80901699437494742410229341718282, 0.85065080835203993218154049706301);// vec3(-sin(2PI/10), -cos(2PI/10),1/(2cos(3PI/10)))
const vec3 f2 = vec3(0.30901699437494742410229341718282,-0.95105651629515357211643933337938, 0.);// vec3(sin(PI/10), -cos(PI/10),0)
const vec3 f3 = vec3(0.,1., 0.);// for reference. We'll simply use abs(p.y)
const vec3 f4 = vec3(-0.58778525229247312916870595463907,-0.80901699437494742410229341718282, 0.52573111211913360602566908484788);// vec3(-sin(2PI/10), -cos(2PI/10),1/2*cos(2PI/10)*tg(PI/10))
const vec3 f5 = vec3(0.,1., 0.);// for reference. We'll simply use abs(p.y)
#ifdef VARIANT2
const vec3 f6 = vec3(-0.95105651629515357211643933337938,-0.30901699437494742410229341718282, 0.85065080835203993218154049706301);// vec3(-cos(PI/10), -sin(PI/10),1/(2cos(3PI/10)))
#endif

//Ray
struct Ray{
    vec2 O;
    vec2 D;
};
//Starting ray
#ifdef VARIANT2
Ray firstRay = Ray(vec2(0.80901699437494742410229341718282,0.26286555605956680301283454242394),//vec2(cos(PI/10),0)/(2cos(3PI/10))
                   vec2(0.,1.));
#else
Ray firstRay = Ray(vec2(1.,0.12410828034667904628607373958239),//vec2(1,2sin(PI/10)tg²(PI/10))
                   vec2(-0.95105651629515357211643933337938,-0.30901699437494742410229341718282));// -vec2(cos(PI/10),sin(PI/10));
#endif

void reflectRay(inout Ray ray, in vec3 mirror){
    //we assume that ray direction and mirror normal are normalized.
    float nd = dot(mirror.xy, ray.D);
    float t = -(mirror.z + dot(mirror.xy, ray.O))/nd;
    ray.O += t * ray.D;
    ray.D -= 2. * nd * mirror.xy;
}

float sideRay(in Ray ray, vec2 p){
    p -= ray.O;
    return ray.D.y * p.x - ray.D.x * p.y;
}

float sideRay(in Ray ray, vec2 p, inout float r){
    float t = (sideRay(ray, p) < 0.) ? 1. : 0.;
    t += r; if(t > 1.) t=0.;//xor with r... I haven't integer support.
    r = (r == 0.) ? 1. : 0.; 
    return t;
}

//Mirrors that reflect the ray
// are f2 and f3 for default variant and f2,f3 and f4 for the variant 2

// Folds the plane about the line L
int lineFold(inout vec2 p, in vec3 L){
	float t = -(dot(p,L.xy) + L.z);
	p += 2. * max(0.,t) * L.xy;
	return int(t > 0.);
}

// Folds the plane about some symmetry lines.
// Returns the number of folds performed.
int fold(in vec2 p, out vec2 z){
	int nbrFold = 0;
	//fold into the rectangle rect. first translation by 2*rect then mirror about faces of rect.
	z=mod(p, 2.*rect);
	z -= rect;
	nbrFold += int(z.x>0.); nbrFold += int(z.y>0.);
	z = -abs(z) + rect;
    
	// Other folds
	nbrFold += lineFold(z, f0);
	nbrFold += lineFold(z, f1);
    nbrFold += lineFold(z, f2);
	nbrFold += int(z.y < 0.); z.y = abs(z.y);//same as lineFold(z, f3);
#ifdef VARIANT2
    nbrFold += lineFold(z, f6);
#endif
    nbrFold += lineFold(z, f4);
	nbrFold += int(z.y < 0.); z.y = abs(z.y);//same as lineFold(z, f5);
		
	return nbrFold;
}

float segDist(vec2 p, vec2 a, vec2 b){
	p -= a; b -=a;
	float t = clamp(dot(p,b) / dot(b,b), 0., 1.);
	return length(p - t * b);
}

float segDistNoClamp(vec2 p, vec2 a, vec2 b){
	p -= a; b -=a;
	float t = dot(p,b) / dot(b,b);
	return length(p - t * b);
}

//The profile of the lines for opacity and color
float profile(float x, float width, float pixWidth){
    float a = -.5/pixWidth;
    float b = -a * (width + pixWidth);
    return smoothstep(0., 1., a * x + b);
}

vec4 combine(vec4 up, vec4 dn){
    if(up.w*dn.w == 1.)
        return vec4(0.,0.,0.,1.);
    return vec4(mix(up.rgb, dn.rgb * (1.-dn.w), up.w)/(1. - up.w * dn.w),
                up.w * dn.w);
}

vec4 stepIt(vec4 pcol, vec2 z, Ray ray, float parity){
    float d = segDistNoClamp(z, ray.O, ray.O + ray.D);
    float po = 1. - profile(d, lineWidth+2.*aaScale, aaScale);
    float pc = profile(d, lineWidth, aaScale);
    //vec3 col = pc * linesCol;
    vec3 col = mix(linesBorderCol, linesCol, pc);
    
    if(parity < .5)
        return combine(vec4(col,po), pcol);
    else
        return combine(pcol, vec4(col,po));
}

#ifndef SIMPLE
vec4 drawIt(vec2 z, float parity){
    Ray ray = firstRay;
    vec4 col = vec4(1., 1., 1., 1.);
    float tc = 0., r = 0.;
    
    col = stepIt(col, z, ray, parity);
    tc += sideRay(ray, z, r);
#ifdef VARIANT2
    reflectRay(ray, f4);
    col = stepIt(col, z, ray, parity);
    tc += sideRay(ray, z, r);
#endif
    reflectRay(ray, f3);
    col = stepIt(col, z, ray, parity);
    tc += sideRay(ray, z, r);
    
    reflectRay(ray, f2);
    col = stepIt(col, z, ray, parity);
    tc += sideRay(ray, z, r);
    
#ifdef VARIANT2
    reflectRay(ray, f3);
    col = stepIt(col, z, ray, parity);
    tc += sideRay(ray, z, r);
    
    /*reflectRay(ray, f2);
    col = stepIt(col, z, ray, parity);
	tc += sideRay(ray, z, r);
    */
#endif
    vec4 col1 = vec4(pow(vec3(0.75+0.25*sin(tc*tc*3.2+iTime),
               0.75+0.25*sin(tc*1.5+iTime*.7),
               0.75+0.25*sin(tc*tc*4.2+iTime*.3)), vec3(GAMMA)),
               0.);
    return combine(col, col1);
}

#else

//Simple drawing. Not used. useful to see the action of the folding.
//in order to use it, uncomment the "#define SIMPLE" above ^^^ 
vec4 drawIt(vec2 z, float parity){
    
    Ray ray = firstRay;
    
    float d = segDist(z, ray.O, ray.O + ray.D);
#ifdef VARIANT2
    reflectRay(ray, f4);
    d = min(d, segDist(z, ray.O, ray.O + ray.D));
#endif
    reflectRay(ray, f3);
    d = min(d, segDist(z, ray.O, ray.O + ray.D));
    reflectRay(ray, f2);
    d = min(d, segDist(z, ray.O, ray.O + ray.D));
    /*reflectRay(ray, f3);
    d = min(d, segDist(z, ray.O, ray.O + ray.D));
    reflectRay(ray, f2);
    d = min(d, segDist(z, ray.O, ray.O + ray.D));
    */
    return vec4(vec3(0.7 + 0.6* (parity)) *clamp(d*100., 0., 1.), 1.);
}

#endif

//
void initRay(vec2 p){
    linesCol = pow(linesCol,vec3(GAMMA));
    linesBorderCol = pow(linesBorderCol,vec3(GAMMA));
    lineWidth = sin(0.2 * iTime)*0.01+0.015;
#ifdef VARIANT2 
    float ang = 0.12 * sin(iTime + WOBBLE * p.x);
    float d = firstRay.O.y * tan(ang);
    firstRay.O.x -= d; firstRay.O.y =0.;
    firstRay.D = vec2(sin(ang), cos(ang));
#endif    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float scaleFactor= 5.;//0.05*iMouse.y;
	vec2 p = scaleFactor*(fragCoord.xy-0.5*iResolution.xy) / iResolution.y;
	aaScale=0.75*scaleFactor/iResolution.y;
    
    initRay(p);
    
    vec2 z = vec2(0.);
	int nbrFold = fold(p, z);
    float parity = 1. - fract(float(nbrFold) * 0.5) * 2.;

	fragColor = drawIt(z, parity);
    fragColor.xyz = pow(fragColor.xyz, vec3(1./GAMMA));
}