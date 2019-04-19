// https://www.shadertoy.com/view/wd23Rd

#define iTime iGlobalTime

// fork from https://www.shadertoy.com/view/4dBXWD
#define time iTime

vec3 rotx(vec3 p, float a){ float s = sin(a), c = cos(a);
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z); }
vec3 roty(vec3 p, float a){ float s = sin(a), c = cos(a);
    return vec3(c*p.x + s*p.z, p.y, -s*p.x + c*p.z); }
vec3 rotz(vec3 p, float a){ float s = sin(a), c = cos(a);
    return vec3(c*p.x - s*p.y, s*p.x + c*p.y, p.z); }

vec3 textri(in vec2 p, in float idx)
{	
    float siz = iResolution.x *.001;
    p*=1.31;
    vec2 bp = p;
    p.x *= 1.732;
	vec2 f = fract(p)-0.5;
    float d = abs(f.x-f.y);
    d = min(abs(f.x+f.y),d);
    
    float f1 = fract((p.y-0.25)*2.);
    d = min(d,abs(f1-0.5));
    d = 1.-smoothstep(0.,.1/(siz+.7),d);
    
    vec2 q = abs(bp);
    p = bp;
    d -= smoothstep(1.,1.3,(max(q.x*1.73205+p.y, -p.y*2.)));
    vec3 col = (sin(vec3(1.,1.5,5)*idx)+2.)*((1.-d)+0.25);
    col -= sin(p.x*10.+time*8.)*0.15-0.1;
    return col;
}

//10 mirrored triangles for the icosahedron
vec3 ico(in vec3 p)
{
    vec3 col = vec3(1);
    vec2 uv = vec2(0);
    
    //center band
    const float n1 = .7297;
    const float n2 = 1.0472;
    for (float i = 0.;i<5.;i++)
    {
        if(mod(i,2.)==0.)
        {
            p = rotz(p,n1);
        	p = rotx(p,n2);
        }
		else
        {
            p = rotz(p,n1);
        	p = rotx(p,-n2);
        }
        uv = vec2(p.z,p.y)/((p.x));
    	col = min(textri(uv,i+1.),col);
    }
    p = roty(p,1.048);
    p = rotz(p,.8416);
    p = rotx(p,.7772);
    //top caps
    for (float i = 0.;i<5.;i++)
    {
        p = rotz(p,n1);
        p = rotx(p,n2);

    	uv = vec2(p.z,p.y)/((p.x));
    	col = min(textri(uv,i+6.),col);
    }
    
    return 1.-col;
}

vec2 iSphere2(in vec3 ro, in vec3 rd)
{
    vec3 oc = ro;
    float b = dot(oc, rd);
    float c = dot(oc,oc) - 1.;
    float h = b*b - c;
    if(h <0.0) return vec2(-1.);
    else return vec2((-b - sqrt(h)), (-b + sqrt(h)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
	vec2 p = fragCoord.xy/iResolution.xy-0.5;
    vec2 bp = p+0.5;
	p.x*=iResolution.x/iResolution.y;
	// circulosmeos: code changed
    //vec2 um = iMouse.xy / iResolution.xy-.5;
    vec2 um = iTime / iResolution.xy-.5;
	um.x *= iResolution.x/iResolution.y;
	
    //camera
	vec3 ro = vec3(um.x,um.y,3.5);
    vec3 rd = normalize(vec3(p,-1.4));
    
    vec2 t = iSphere2(ro,rd);

	vec3 pos = ro+rd*t.x;
    vec3 pos2 = ro+rd*t.y;       
    vec3 col2  = max(ico(pos2)*0.6,ico(pos)*2.);

    // circulosmeos: code added to sync with music
    float bass = texture2D( iChannel0, vec2(400.,0.) ).x * 2.;
    col2[1] += (col2[0]>.1)?bass:0.;
    col2[2] += (col2[0]>.1)?bass:0.;

	fragColor = vec4(col2, 1.0);
}