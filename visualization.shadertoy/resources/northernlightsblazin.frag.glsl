// https://www.shadertoy.com/view/wdf3Rf

#define iTime iGlobalTime

// circulosmeos: numbers changed

// CC0 licensed, do what thou wilt.
const float SEED = 4.20;

float swayRandomized(float seed, float value)
{
    float f = floor(value);
    float start = sin((cos(f * seed) + sin(f * 10.24)) * 3.45 + seed);
    float end   = sin((cos((f+1.) * seed) + sin((f+1.) * 10.24)) * 3.45 + seed);
    return mix(start, end, smoothstep(0., 1., value - f));
}

float cosmic(float seed, vec3 con)
{
    float sum = swayRandomized(seed, con.z + con.x);
    sum = sum + swayRandomized(seed, con.x + con.y + sum);
    sum = sum + swayRandomized(seed, con.y + con.z + sum);
    return sum * 0.3333333333 + 0.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    // aTime, s, and c could be uniforms in some engines.
    float aTime = iTime * 0.2;
    vec3 s = vec3(swayRandomized(-164.0531527, aTime - 1.11),
                  swayRandomized(-776.648142, aTime + 1.41),
                  swayRandomized(-509.935190, aTime + 2.61)) * 5.;
    vec3 c = vec3(swayRandomized(-105.2792407, aTime - 1.11),
                  swayRandomized(-615.576687, aTime + 1.41),
                  swayRandomized(-435.278990, aTime + 2.61)) * 5.;
    vec3 con = vec3(0.0004375, 0.0005625, 0.0008125) * aTime + c * uv.x + s * uv.y;
    con.x = cosmic(SEED, con);
    con.y = cosmic(SEED, con);
    con.z = cosmic(SEED, con);
    
    fragColor = vec4(sin(con * 3.14159265) * 0.5 + 0.5,1.0);
}