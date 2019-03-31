// https://www.shadertoy.com/view/XdcBRj

#define iTime iGlobalTime

// scale size   + wave characteristics
//float r = .65, Ax = .15, Lx = 1., Ay = 1., Ly = .5, Lt = 1.;
//float r = .9,  Ax = .15, Lx = 1., Ay = 0., Ly = .5, Lt = 1.;
  float r = .9,  Ax = .15, Lx = 1., Ay = 2., Ly = .5, Lt = 4.;

vec2 disp(vec2 U) {
    U.x += Ax*sin(Lx*U.x +Lt*iTime +Ay*sin(Ly*U.y));
    return U;
}
vec2 invdisp(vec2 V) {
    float x = V.x;
    for (int i=0; i<3; i++)              // converges ultra-fast for small Ax
        x = V.x - Ax*sin(Lx*x+ Lt*iTime +Ay*sin(Ly*V.y));
    return vec2(x,V.y);
}
      
void mainImage( out vec4 O, vec2 U ) {
    float p = 10./iResolution.y;         // scales = relative size
  //float p = 1./30.;                    // scales = absolute size
    U *= p;
    O -= O;
    
    for (int k=0; k<4; k++) {                                  // 4 covering scales
        // circulosmeos: code changed to fit GLESv2
        //vec2  D = ( vec2(k%2,k/2)+.75*vec2(0,k%2 )) * .5,
        vec2  D = ( vec2(mod(float(k),2.),k/2)+.75*vec2(0,mod(float(k),2.) )) * .5,
              V = disp(U),
             U0 = invdisp( floor(V-D)+D+.5 ),                  // cell center 
           // F = fract(V)*2.-1.;                              // distorted scales
              F = 2.*(U-U0);                                   // rigid scales
        //O += cos(6.28*vec4(10,5,1,0)*length(F)); return;     // debug
        float m = smoothstep(0.,-3.*p,length(F)-r),            // scale mask
              z = m*(.5+.5*(F.x+F.y)/1.4/r);                   // scale z
        if (z>O.a) O = vec4(  mix(vec3(.3,0,0),vec3(1),clamp(-1.5+3.*z,0.,1.)) // color gradient
                            * smoothstep(0.,-3.*p,length(F)-(r-.1)), // dark border
                              z);
    }   
    O = sqrt(O);                                               // gamma correction
}