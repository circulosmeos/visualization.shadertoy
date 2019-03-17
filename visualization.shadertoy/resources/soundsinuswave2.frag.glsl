// Modified from https://www.shadertoy.com/view/XsX3zS

#define WAVES 12.0

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;

	float time = iGlobalTime * 6.;
	
	vec3 color = vec3(0.0, 0.0, 0.0);

	for (float i=WAVES; i>0.0; i-=2.0) {
		float freq = texture2D(iChannel0, vec2(i / WAVES, 0.0)).x * 7.0;

		vec2 p = vec2(uv);

		p.x += i * 0.04 + freq * 0.03;
		p.y += sin((p.x-time*0.2)*1.3) * 0.4 + sin(p.x * 10.0 + time) * cos(p.x * 2.0) * freq * 0.2 * ((i + 1.0) / (WAVES-3.0));
		float intensity = abs(0.01 / p.y) * clamp(freq, 0.35, 2.0);
		color += vec3(1.0 * intensity * (i / 5.0), 0.5 * intensity, 1.75 * intensity) * (3.0 / (WAVES/1.2) );
	}

	fragColor = vec4(color, 1.0);
}
