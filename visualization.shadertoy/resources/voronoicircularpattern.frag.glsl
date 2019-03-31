// https://www.shadertoy.com/view/tdsGRS

#define iTime iGlobalTime

#define PI acos(-1.)
#define TWO_PI PI*2.

mat2 r2(float a){
    float s =sin(a);
    float c = cos(a);
    return mat2(s,c,-c,s);
}

vec2 rnd(vec2 p){
    vec3 a = fract(p.xyx*vec3(0.12312, 0.25645, 0.35988)); // circulosmeos: numbers changed
    a += dot(a, a+.4788); // circulosmeos: numbers changed
    return fract(vec2(a.x*a.y, a.z*a.y));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x/iResolution.y;
    float t =iTime;
	uv *= 1.+dot(uv,uv)*.0911275;
      
    uv *= 4.+sin(t/2.);
    uv+=vec2(sin(t),cos(t));
    uv*=r2(sin(t/3.)*.5)*1.12;
    
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    float minDist = 100.;
    vec2 cid = vec2(0);
    for(int y = -1; y<1; y++){
        for(int x =-1; x<1; x++){
            vec2 offset = vec2(x, y);
            vec2 rand = rnd(id + offset);
            
            vec2 point = offset + sin(rand*iTime)*.5+.5;
            
            point-=gv;
            point*=r2(cid.x-t);
            float d = length(point);
            float md = abs(point.x)+abs(point.y);
            
            float dst = mix(d,md,sin(rnd(cid).x+rnd(cid).y));
            
            if(d<minDist){
                minDist = d;
                cid = id+offset;
            }
        }
    }
    
    vec3 col = vec3(0); 
    
    float c = length(minDist)-.3;
    
    float grd = step(.46,gv.x)+step(.46,gv.y);   
    fragColor =  vec4(smoothstep(0.05,0.03, c*sin(3.*t-c*22.+sin(t-rnd(cid).x*12.))));   // vec4(minDist);
    // circulosmeos: code changed to sync with music
    float amp = texture2D( iChannel0, vec2(400.,0.) ).x;
    //if(iMouse.z>0.0){
    if( amp > .015 ){
        fragColor +=vec4(cos(rnd(cid)*4.).xyxy);
        fragColor.r += grd;
    }
}