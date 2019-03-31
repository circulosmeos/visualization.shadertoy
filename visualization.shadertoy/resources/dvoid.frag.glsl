// https://www.shadertoy.com/view/ltfSzM

#define iTime iGlobalTime

float wave(float p, float f, float a){
    return sin(p * f + iTime)*a;
}

const int num = 6;
float xoff[num];
float yoff[num];

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    
    uv -= vec2(0.5);
    uv.x *= iResolution.x/iResolution.y;
    uv += vec2(0.5);
    
    float t = iTime;
    float r = 0.5;
    
    float df = 0.0;
    for (int i = 0; i < num; i++) {
    	float angle = 6.28/float(num)*float(i);
    	xoff[i] = cos(angle) * r + (0.5);
    	yoff[i] = sin(angle) * r + (0.5);
        
        float x = abs(uv.x-xoff[i]);
   		float y = abs(uv.y-yoff[i]);
        
        float d = sqrt(x*x+y*y); //euclidean
        //d = (x+y); //manhattan
        //d = max(x,y); //chebyshev
        
        df += wave(d, 64.0, 1.0);
  	}
    
    float b = sin(df);
    b = smoothstep(0.1, 0.9, b);
    
    fragColor = vec4(vec3(b), 1.0);
}