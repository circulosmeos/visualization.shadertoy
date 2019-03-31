// https://www.shadertoy.com/view/ltGXRR

#define iTime iGlobalTime

const float PI      = 3.14159265359;
const float INVSIZE = 0.3;
const int   WAVES   = 4;  // >=4 for quasiperiodic, try 4, 5, 6 etc.
const float DA      = 1.0 / float(WAVES);


// gradient from https://www.shadertoy.com/view/4dsSzr morgan3d
float square(float s) { return s * s; }
vec3 rainbowGradient(float t) {
	vec3 c = 1.0 - pow(abs(vec3(t) - vec3(0.65, 0.5, 0.2)) * vec3(3.0, 3.0, 5.0), vec3(1.5, 1.3, 1.7));
	c.r = max((0.15 - square(abs(t - 0.04) * 5.0)), c.r);
	c.g = (t < 0.5) ? smoothstep(0.04, 0.45, t) : c.g;
	return clamp(c, 0.0, 1.0);
}



// angledWave generates a 0-1 sin wave at angle PI*a.
float angledWave( in vec2 fragCoord, in float a )
{
    float angle = a * PI;
    float phi = sin( angle ) * fragCoord.x + cos( angle ) * fragCoord.y;
    return 0.5 + 0.5*sin( phi * INVSIZE );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // circulosmeos: code changed to sync with music
    //float amp = 0.0;
    float amp = texture2D( iChannel0, vec2(400.,0.) ).x;
    for( int w = 0; w < WAVES; ++w )
    {
		amp += angledWave( fragCoord, float(w) * DA );
    }
        
	fragColor = vec4( rainbowGradient( amp * DA ), 1.0 );
}