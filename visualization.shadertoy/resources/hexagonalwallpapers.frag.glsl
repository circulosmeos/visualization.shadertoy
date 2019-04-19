// https://www.shadertoy.com/view/llsXDf

#define iTime iGlobalTime/1.6

// circulosmeos: code heavily changed to comply with GLESv2

//Hexagonal wallpapers by nmz (twitter: @stormoid)

/*
	For more info: https://en.wikipedia.org/wiki/Wallpaper_group

	p6: 0.5s
	p6mm: 8s
	p3: 12s
	p3m1: 21s
	p31m: 31s (not 100% sure about that one, can anyone confirm?)

	You should see new patterns up to ~80seconds
*/

#define tau 6.2831853
#define time iTime
mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}

// circulosmeos: code added
vec2 rotate2D(vec2 position, float theta) { 
    return vec2(position.x*cos(theta)+position.y*sin(theta), position.y*cos(theta)-position.x*sin(theta)); 
}

//From mattz (https://www.shadertoy.com/view/4d2GzV)
//-------------------------------------------------------------
vec2 pick3(vec2 a, vec2 b, vec2 c, float u) 
{
	float v = fract(u * 0.3333333333333);
	return mix(mix(a, b, step(0.3, v)), c, step(0.6, v));
}

const float s3 = 1.7320508075688772;
const float i3 = 0.5773502691896258;
const mat2 tri2cart = mat2(1.0, 0.0, -0.5, 0.5*s3);
const mat2 cart2tri = mat2(1.0, 0.0, i3, 2.0*i3);
vec2 closestHexCenters(vec2 p){
    p = cart2tri*p;
	vec2 ip = floor(p), fp = fract(p);
	vec2 nn = pick3(vec2(0), vec2(1), vec2(1.0, 0.0), ip.x + ip.y);
    return tri2cart*(mix(nn, nn.yx, step(fp.x, fp.y)) + ip);
}

//-------------------------------------------------------------

float tri(in vec2 p){ return max(abs(p.x)*1.73205+p.y, -p.y*2.);}

float smoothfloor(in float x, in float k)
{
    float xk = x+k*0.5;
    return floor(xk)+smoothstep(0.,k,fract(xk));
}

//The main texture function, could be different shapes
vec4 tex(in vec2 p, in float a, in float typ)
{
    float t = mod(time,23.5);
    // circulosmeos: code changed
    //p *= mm2(a + smoothfloor(t*0.4,0.25)*0.5 + smoothfloor(t*0.2,0.25)*.83);
    p = rotate2D( p, a + smoothfloor(t*0.4,0.25)*0.5 + smoothfloor(t*0.2,0.25)*.83 );
    float rz = tri(p*mix(1.,1.4,smoothstep(0.1,-0.1,sin(time*0.4))));
    float rz2 = rz;
    rz = smoothstep(0.7,.8,rz);
    vec3 tri = (1.-rz)*abs(sin(vec3(1.,2.,3.)+typ*.8))*smoothstep(0.7,0.6,rz2);
    tri *= texture2D(iChannel1, p).r*0.6+0.5; // circulosmeos: code changed
    return vec4(tri, 1.-rz);
}

vec3 tiles(in vec2 p)
{
    vec3 col = pow(texture2D(iChannel1, p).rgb,vec3(0.37)); // circulosmeos: code changed
    vec2 ofst = vec2(0.5,.866);
    
    vec4 rez = tex(p,-0.5236, 0.5)*smoothstep(0.2,.3,sin(time*0.3+3.));
    col = mix(col,rez.rgb,rez.a);
    
    float a = atan(p.x, -p.y)*3./tau;
    float id = floor(a+.8);
    vec2 bp = p;
    p *= mm2(id*tau/3.);
    
    rez = tex(p+ofst,2.094+id*4.1889+ 1.05, 2.);
    col = mix(col,rez.rgb,rez.a);
    
    id = floor(a+.3);
    p = bp;
    p *= mm2(id*tau/3. + 1.0472);
    rez =  tex(-p-ofst,.0+2.094+id*4.1889, 3.);
    col = mix(col,rez.rgb,rez.a);
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{			
    vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = q-0.5;
	p.x *= iResolution.x/iResolution.y;
    p*= 8.;
    p *= mm2(smoothstep(-0.1,.1,sin(time*0.25+0.1))*1.5708);
    p.x += time*0.4;
    
    vec2 h = closestHexCenters(p);
    vec3 col = tiles(p-h);

    col *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.15 );
    
    fragColor = vec4(col, 1.);
}

