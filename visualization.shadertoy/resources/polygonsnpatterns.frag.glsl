// https://www.shadertoy.com/view/lsBSDz

#define iTime iGlobalTime

// Created by Vinicius Graciano Santos - vgs/2014
// https://www.shadertoy.com/view/lsBSDz

#define TAU 6.28318530718

float segment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    vec2 ap = p - a;
    float k = clamp(dot(ap, ab)/dot(ab, ab), 0.0, 1.0);
    return smoothstep(0.0, 5.0/iResolution.y, length(ap - k*ab) - 0.001);
}

float shape(vec2 p, float angle) {
    float d = 100.0;
    vec2 a = vec2(1.0, 0.0), b;
    vec2 rot = vec2(cos(angle), sin(angle));
    
    for (int i = 0; i < 6; ++i) {
        b = a;
        for (int j = 0; j < 18; ++j) {
        	b = vec2(b.x*rot.x - b.y*rot.y, b.x*rot.y + b.y*rot.x);
        	d = min(d, segment(p,  a, b));
        }
        a = vec2(a.x*rot.x - a.y*rot.y, a.x*rot.y + a.y*rot.x);
    }
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 cc = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;
        
    float col = shape(abs(cc), cos(0.01*(iTime+22.0))*TAU);
    col *= 0.5 + 1.5*pow(uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.3);
    
    
	fragColor = vec4(vec3(pow(col, 0.45)),1.0);
}