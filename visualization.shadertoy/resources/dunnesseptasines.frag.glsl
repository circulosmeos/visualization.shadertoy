// https://www.shadertoy.com/view/4ddGDf

#define iTime iGlobalTime

const float p2 = 2.0 * 3.1415926;

float oneWheel(float theta, float frequency, float phase, vec2 xy)
{
    // xy presumed centered on screen, for best wheel-like action.
    float s = sin(theta);
    float c = cos(theta);
    mat2 m = mat2(c, -s, +s, c);
    xy = m * xy;
    float v = sin(xy.x * frequency + phase);
    //v = v < 0.0 ? -1.0 : +1.0;
    return v;
}

float rs = 0.0;

float rg(float centerFrequency, float deviation, float amplitude)
{
    rs = rs + 13.3 * 23948.1; // repeatable sequence
    float f = sin(rs);
    float v = cos(iTime  * (centerFrequency + deviation * f) * p2);
    v = v * amplitude;
    return v;
}

float rf(float centerFrequency)
{
    return rg(centerFrequency, 1.0, 1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy - iResolution.xy / 2.0) / iResolution.xx;
    
    
    float v = 0.0;
    float f = 52.30*6.; // circulosmeos: numbers changed
    float w = 0.3; // warble
    float u = 0.02; // slower warble
    float oo = iTime * 0.2;
    v += oneWheel(1.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), 0.0, uv);
    v += oneWheel(2.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), 0.0, uv);
    v += oneWheel(3.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), 0.0, uv);
    v += oneWheel(4.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), oo, uv);
    v += oneWheel(5.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), -oo * 3.0102, uv);
    v += oneWheel(6.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), 0.0, uv);
    v += oneWheel(7.0 * p2 / 7.0 + rg(u, u / 2.0, 0.021), f + rf(w), 0.0, uv);
    
    v = pow(v, 5.0);
    v = clamp(v, 0.0, 1.0);
//        v = v < 0.0 ? -1.0 : +1.0;

    float d = length(uv) * 2.0;
    float a = 1.0 / (d + 1.0);
    
    fragColor = vec4(v, v, v, 1.0);
    fragColor.rgb *= a;
}