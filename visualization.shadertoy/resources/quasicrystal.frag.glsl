// https://www.shadertoy.com/view/XlfBRn

#define iTime iGlobalTime

const float tau = 6.2831;

// Feel free to change these:
const float magnification = 3.0;
const float periodTimeInSeconds = 10.0;
const int waveCount = 15; // odd numbers are more interesting
const bool stepped = false;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy - iResolution.xy / 2.0) / iResolution.y * 1000.0;
    float totalIntensity = 0.0;
	float recipWaveCount = 1.0 / float(waveCount);
    float angle = tau * recipWaveCount;
    mat2 rotation = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    vec2 direction = vec2(0, 1);
   	for (int i = 0; i < waveCount; i++)
    {
        float spacePattern = dot(uv, direction) / magnification;
        float timePattern = tau * iTime / periodTimeInSeconds;
       	totalIntensity += sin(timePattern + spacePattern);
        direction *= rotation;
    }
    totalIntensity *= recipWaveCount;
    float smoothing = 0.02;
    float steppedIntensity = smoothstep(-smoothing, smoothing, totalIntensity);
    vec3 finalColor = vec3(stepped ? steppedIntensity : totalIntensity);
	fragColor = vec4(finalColor,1.0);
}