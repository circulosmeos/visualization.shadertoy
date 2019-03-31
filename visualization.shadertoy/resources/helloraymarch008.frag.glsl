// https://www.shadertoy.com/view/MtyyDR

#define iTime iGlobalTime

#define R iResolution.xy
#define T iTime

// toggle to observe reflections on distorted surfaces
#define DISTORT_SPHERE 1

float map(vec3 p) {
	
	vec3 v = p;
	float dMin = 1000.;
	float d = 0.;

	//v.x -= (1.5 + 2. * sin(T));
    v.xy += 1.25 * vec2(cos(T), sin(T));
	d = length(v) - .5;
	if (d < dMin) dMin = d;
	
	v = p;
    v.y += .5;
    v.xz += 2.25 * vec2(cos(-T), sin(-T));
	d = length(v) - .3;
	if (d < dMin) dMin = d;
    
    v = p;
    d = length(v) - .5;
#if DISTORT_SPHERE
    // d += .1 * cos(v.x * 6. + T) * cos(v.y * 6. - T) * cos(v.z * 6. + T);
	// circulosmeos: make sound dependent
	float sound = texture2D( iChannel0, vec2(0.1, 0.0) ).x;
    d += fract(sound)/2. * cos(v.x * 6. + T) * cos(v.y * 6. - T) * cos(v.z * 6. + T);
#endif
    if (d < dMin) dMin = d;

	return dMin;

}

vec3 calcNormal(in vec3 p) {
    vec2 E = vec2(.001, 0.);
    return normalize(vec3(
        map(p + E.xyy) - map(p - E.xyy),
        map(p + E.yxy) - map(p - E.yxy),
        map(p + E.yyx) - map(p - E.yyx)
    ));
}

void mainImage(out vec4 O, in vec2 I) {
	
	vec2 uv = (2. * I - R) / R.y;
	
	vec3 ro = vec3(0., 0., -3.25);
	vec3 rd = vec3(uv, 1.);
	vec3 l = vec3(1., 2., -3.);
	
	float t = 0.;
	for (int i = 0; i < 128; i++) {
		vec3 p = ro + rd * t;
		float d = map(p);
		if (d < .001 || t > 10.) break;
		t += .5 * d;
	}
	
	O = vec4(0.);

	if (t < 10.) {
	
		
		vec3 p = ro + rd * t;
		vec3 n = calcNormal(p);
		vec3 lp = normalize(l - p);
        vec3 sref = reflect(-lp, n);
		
		float diff = .5 * max(dot(lp, n), 0.);
        float spec = .04 * max(dot(sref, ro), 0.);
		float fog = 1. / (1. + t * t * 2.);
		
        O  = vec4(vec3(fog + diff + spec), 1.);
        
        // Reflection raymarch
		vec3 ref = reflect(rd, n);
		float r = .1;
		for (int i = 0; i < 32; i++) {
			vec3 rp = p + ref * r;
			float d = map(rp);
			if (d < .001 || t > 10.) break;
			r += .8 * d;
		}
		
		vec3 rsp = p + ref * r;
		vec3 rn = calcNormal(rsp);
        vec3 srf = reflect(-lp, rn);
		float rdiff = .5 * max(dot(lp, rn), 0.);
        float rspec = .04 * max(dot(srf, rsp), 0.);
        //
		
        // add the reflected scene
		O  += (rdiff + rspec);
  
	
	}
	

}