// https://www.shadertoy.com/view/ld2BRw

#define iTime iGlobalTime

void mainImage(out vec4 f,vec2 c)
{
    f-=f;
	vec2 u=c/iResolution.y*-4.+.5,t=vec2(3,1)*.006*iTime+.45; // circulosmeos: numbers changed
    float w=.04;
    
    // circulosmeos: code changed to sync with music
    float bass = texture2D( iChannel0, vec2(400.,0.) ).x;
    w+= bass / 20.; //(bass>.2)?(bass/10.):(0.);
    
    for(int i=0;i<20;++i)
    {
        u=u*sin(t.x)+cos(t.y)*vec2(-u.y,u.x);
        u*=1.2+f.xy*.06;
        w*=.96;
    	f+=w*(abs(sin(u.x))+abs(cos(u.y)));
    }
    f.x=sin(f.x*4.);
    f*=f;
    f*=f;
}