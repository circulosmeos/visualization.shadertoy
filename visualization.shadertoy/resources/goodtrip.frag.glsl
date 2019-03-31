// https://www.shadertoy.com/view/4tXGWH

#define iTime iGlobalTime

#define t iTime*1.5

vec2 hash( vec2 p ) {
    // circulosmeos: numbers changed
    p = vec2( dot(p,vec2(1.271,3.117)),
              dot(p,vec2(2.695,1.833)) );
    return -1. + 2.*fract(sin(p+20.)*53.7585453123);
}
float noise( in vec2 p ) {
    vec2 i = floor((p)), f = fract((p));
    vec2 u = f*f*(3.-2.*f);
    return mix( mix( dot( hash( i + vec2(0.,0.) ), f - vec2(0.,0.) ), 
                     dot( hash( i + vec2(1.,0.) ), f - vec2(1.,0.) ), u.x),
                mix( dot( hash( i + vec2(0.,1.) ), f - vec2(0.,1.) ), 
                     dot( hash( i + vec2(1.,1.) ), f - vec2(1.,1.) ), u.x), u.y);
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    // circulosmeos: code changed to sync with music
    //float s =noise(uv+t)*14.;
    float s =noise(uv+t)*14. + texture2D( iChannel0, vec2(400.,0.) ).x*50.;
    float b=sin(s-48.*uv.x+t)*sin(s+uv.y*43.-t);
    float g =noise(uv+t-b);
    float uv2= length(uv-.5+g)-sin(b)*sin(.08*t);
    uv2=smoothstep(.49,.5,uv2+g);
	fragColor = vec4(uv2*uv.x-g,g*3.8,uv2,b);  
}
/* 2015 Passion */


