// https://www.shadertoy.com/view/WdjGzV

#define iTime iGlobalTime

#define UP vec3(0., -1., 0.)
#define EPS .00001
#define AA (10./iResolution.y)
#define PI 3.14159265359
#define TAU (2.*PI)
#define PTNTS_CNT 3

struct Ray{vec3 origin, dir;};
struct HitRecord{float dist; vec3 point; vec3 normal;};
struct Plane{vec3 origin, normal;};

//noise by iq
float noise(in vec3 x){
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2DLodEXT( iChannel0, (uv+0.5)/256.0, 0.0).yx;
    // circulosmeos: tried to sync with music, but didn't succeed
    //vec2 rg = texture2DLodEXT( iChannel1, (uv+0.5)/256.0, 0.0).yx;
    return mix( rg.x, rg.y, f.z );
}

float remappedNoise(in vec3 p){
    return .5 + .5 * (noise(p)/.6);
}
    
bool plane_hit(in Ray inray, in Plane plane, out float dist) {
    float denom = dot(plane.normal, inray.dir);
    if (denom > 1e-6) {
        vec3 p0l0 = plane.origin - inray.origin;
        float t = dot(p0l0, plane.normal) / denom;
        if(t >= EPS){
            dist = t;
            return true;
        }
    }
    return false;
}
    
bool hit(in Ray inray, in Plane top, out float dist){
    return plane_hit(inray, top, dist);
}
    
vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.;
    float z = size.y / tan(radians(fieldOfView) / 2.);
    return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye),
         s = normalize(cross(f, up)),
         u = cross(s, f);
    return mat4(vec4(s, 0.), vec4(u, 0.), vec4(-f, 0.), vec4(vec3(0.), 1.));
}

// circulosmeos: code changed
/*
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}
*/
vec3 rotateY(vec3 position, float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    )*position;
}

// circulosmeos: code changed to fit GLESv2
//const vec2[PTNTS_CNT] points = vec2[PTNTS_CNT](vec2(-2., 0.), vec2(0., -3.), vec2(2., 0.));
float calcClr(in Ray ray){

    float dist;
    for(float i=0.; i>-10.; i-=.15){
        if (hit(ray, Plane(vec3(0., i, 0.), UP), dist)) {
            float time = iTime + i * .25;
            vec3 p = ray.origin + ray.dir * dist;
            // circulosmeos: code changed
            //p *= rotateY(remappedNoise(vec3(time * 1.5)));
            p = rotateY(p, remappedNoise(vec3(time * 1.5)));
            int k=-1; // circulosmeos: code added
            for(float j=0.; j<float(PTNTS_CNT); j++){
                k++; // circulosmeos: code added
                float noisedRad = remappedNoise(vec3(time * 1.78 + j)) +
                    noise(vec3(p.xy + j * .25, time));
                /*float noisedRad = 1.-length(p)*.5 + remappedNoise(vec3(time * 2.78) * .5) +
                    noise(vec3(p.xy, time*1.)); // circulosmeos: as per Ultraviolet suggestion*/
                //float l = distance(p.xz, points[int(j)]);
                // circulosmeos: code changed
                float l;
                if (k==0)
                    l = distance(p.xz, vec2(-2., 0.));
                else if (k==1)
                    l = distance(p.xz, vec2(0., -3.));
                else if (k==2)
                    l = distance(p.xz, vec2(2., 0.)); 

                if(l < noisedRad)
                   return smoothstep(.0125 + AA, .0125, abs(noisedRad - l - AA));
            }
        }
    }
    return 0.;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec3 viewDir = rayDirection(45.0, iResolution.xy, fragCoord);
    vec3 eye = vec3(7.+sin(iTime), 7., 7. + cos(iTime));
    // circulosmeos: code changed
    //mat4 viewToWorld = viewMatrix(eye, vec3(1., sin(iTime) - .5, 0.), normalize(vec3(.25 + .25 * noise(vec3(iTime)), 1., 0.)));
    mat4 viewToWorld = viewMatrix(eye, vec3(1., sin(iTime) - .5, 0.), normalize(vec3(.25 + .25, 1., 0.)));
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.)).xyz;
    
    float dist;
    Ray r = Ray(eye, worldDir);
    fragColor = vec4(vec3(calcClr(r)), 1.);
}