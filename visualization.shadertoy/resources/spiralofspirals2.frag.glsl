// https://www.shadertoy.com/view/lsdBzX

#define iTime iGlobalTime

//////////////////////////////////////////////////////////////////////////////////
// Spiral of Spirals - Copyright 2018 Frank Force
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////

const float pi = 3.14159265359;

vec3 hsv2rgb(vec3 c)
{
    float s = c.y * c.z;
    float s_n = c.z - s * .5;
    return vec3(s_n) + vec3(s) * cos(2.0 * pi * (c.x + vec3(1.0, 0.6666, .3333)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy;
    uv -= iResolution.xy / 2.0;
    uv /= iResolution.x;
   
    //vec4 mousePos = (iMouse.xyzw / iResolution.xyxy);
    vec2 mousePos = texture2D( iChannel0, vec2(.07, .37) ).xy; // circulosmeos: make sound dependent
 	uv *= 100.0;
    if (mousePos.y > 0.0)
    	uv *= 4.0 * mousePos.y;
    
    float a = atan(uv.y, uv.x);
    float d = length(uv);
    
    // make spiral
    float i = d;
    float p = a/(2.0*pi) + 0.5;
    i -= p;
    a += 2.0*pi*floor(i);
    
    // change over time
    float t = .0005*(iTime +  4.0*mousePos.x); // circulosmeos: numbers adjusted
    //t = pow(t, 0.4);
    
    /*float h = 0.5*a;
    h *= t;
    //h *= 0.1*(floor(i)+p);
    h = 0.5*(sin(h) + 1.0);
    h = pow(h, 3.0);
    h += 4.222*t + 0.4;
    
    float s = 2.0*a;
    s *= t;
    s = 0.5*(sin(s) + 1.0);
    s = pow(s, 2.0);*/  // circulosmeos: second method chosen
    
    float h = d*.01 + t*1.33;
    float s = sin(d*.1 + t*43.11);
    s = 0.5*(s + 1.0);
    
    // fixed size
    a *= (floor(i)+p);
    
    // apply color
    float v = a;
    v *= t;
    v = sin(v);
    v = 0.5*(v + 1.0);
    v = pow(v, 4.0);
    //v *= pow(sin(fract(i)*pi), 0.4); // darken edges
    v *= min(d, 1.0); // dot in center
    
    //vec3 c = vec3(h, s, v);
    vec3 c = vec3(h, s, v);
	fragColor = vec4(hsv2rgb(c), 1.0);
}