// https://www.shadertoy.com/view/XdVcWW

#define iTime iGlobalTime*.25

const float PI = acos(-1.0);
const float TwoPI = PI * 2.0;

mat2 r2(float a){
    float s = sin(a);
    float c = cos(a);
    return mat2(s, c, -c, s);
}
float rand (float r){
    //return fract(sin(r*768.65)*7589.89);
    return fract(sin(r*7.6865)*75.8989); // circulosmeos: numbers changed
}
float triangle(vec2 uv, float i){
  // Number of sides of your shape
  int N = int(i);

  // Angle and radius from the current pixel
  float a = atan(uv.x,uv.y)+PI;
  float r = TwoPI/float(N);

  // Shaping function that modulate the distance
  return cos(floor(.5+a/r)*r-a)*length(uv);
}

vec3 effect(vec2 uv, float t){
    t*=2.;
    uv*=3.5;
    
    vec2 a = vec2(3., 1.);
    vec2 a2 = vec2(1.0, 2.0);
    
    vec2 st = vec2(uv*a);
    vec2 id = floor(st);
    
    float n = rand(id.x);  //fract(sin(id.x*714.65)*7426.56);
    st.y += t*.3;
    st.y += n;

    id = floor(st);
    st = fract(st)-.5;
    
    t += rand(id.x+id.y)*TwoPI; //fract(sin(id.x*72.45+id.y*1488.88)*765.23)*TwoPI; //6.284;
    
    float y = -sin(t+sin(t+sin(t)*.5))*.40;
    float x = .5* rand(id.y)-.24; //fract(sin(id.y*768.34)*7689.43)-.24;
    
    vec2 p1 = vec2(x, y);
    vec2 p1t = ((st-p1) / a) * r2((-y*2.)+t*.5);
    float d = triangle(p1t, n*4.+3.);
    float m1 = smoothstep(.07, .0524, d);
        
    // circulosmeos: code changed to sync with music
    float amp = texture2D( iChannel0, vec2(400.,0.) ).x * 10.;
    //if(iMouse.z>0.1)
    /*if( amp > 1. )
        m1 = (st.x > .44 || st.y > .49) ? 1.0 : m1;*/
    
    // circulosmeos: code changed to sync with music
    vec3 rcol = vec3(rand(id.x+id.y) + amp,
                     rand(id.x),
                     rand(id.y));
    
    return mix(vec3(m1), rcol, m1);   
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = (fragCoord/iResolution.xy) - .5;
    vec2 uv = (fragCoord -.5*iResolution.xy) / iResolution.y;

    //uv.x *= iResolution.x / iResolution.y;
    uv /= 1.3-dot(uv,uv)*.33;
    float t = iTime;//*.75;
    uv.x += sin(t/5.)*4.;
    uv.y -= cos(t/6.)*2.;
    
    
    vec3 col = effect(uv*.8, t*1.8);
    
    uv*=r2(1.7);  //+sin(t/4.)
    col+=effect(uv*1.3, t*1.75);
    
    uv*=r2(1.12);
    uv.x += iTime*.25;
    col+=effect(uv*1.2, t*1.25);
    
    uv*=r2(1.6);
    uv.x-=iTime*.15;
    col+=effect(uv*1.7, t*2.);
    
    
    // Output to screen
    //col = st; //vec3(st,0.0);
    fragColor = vec4(col,1.0);
}