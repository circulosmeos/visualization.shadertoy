// https://www.shadertoy.com/view/4tBcDt

#define iTime iGlobalTime

// Try changing these:
const int layerCount = 6;
const float layerAlpha = 0.3;
const float spatialFrequency = 50.0;
const float fisheyeFactor = 4.0;
const float baseMagnification = 1.1;
const float speed = .5; // circulosmeos: numbers changed

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 position = (fragCoord.xy - iResolution.xy / 2.0) / iResolution.y;
    
    float time = (iTime + 256.0) * 0.01 * speed;
    
    float totalIntensity = 0.0;
    float angle = time;
    mat2 rotation = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    for (int i = 0; i < layerCount; ++i)
    {
        position *= rotation;
        position *= pow((sin(time * 50.0)*0.01 + baseMagnification), - fisheyeFactor * length(position));
        
    	vec2 fromGrid = fract(position * spatialFrequency) * 2.0 - 1.0;
        float distanceFromGrid = length(fromGrid);
    	float circles = smoothstep(0.5, 0.6, distanceFromGrid);
        totalIntensity += circles * layerAlpha;
        
        
    }
    fragColor = vec4(vec3(1.0 - totalIntensity), 1.0);
}