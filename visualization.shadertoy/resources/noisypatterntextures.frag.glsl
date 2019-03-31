// https://www.shadertoy.com/view/Xdyfzc

#define iTime iGlobalTime

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 u = fragCoord.xy * .03;
    
    u += sin(u.yx*69.)*3.*acos(cos(iTime*.2))/3.14159265359;
    
    vec2 fl = floor(u);
    float l = fract(sin(dot(fl,vec2(1.,1.123)))*1.111); // circulosmeos: numbers changed
    
    u = fract(u)*2.-1.;
    
    vec4 c = vec4(
        fract(sin(dot(fl,vec2(1.123,1.234)))*1.111), // circulosmeos: numbers changed
        fract(sin(dot(fl,vec2(1.345,1.456)))*1.112),
        fract(sin(dot(fl,vec2(1.567,1.678)))*1.113),
        1.);
 
	fragColor = c*(dot(u,u)-l);
    fragColor = c*(l-dot(u,u));
}