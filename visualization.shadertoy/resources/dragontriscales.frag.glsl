// https://www.shadertoy.com/view/4d2BRy

#define iTime iGlobalTime/1.7

#define SHOW_DUAL_POINTS 1
#define SHOW_SEGMENTS 1

#define dx (iMouse.x/iResolution.x)
#define PI 3.14159265359

float fft(float x)
{
    //return .8; // circulosmeos: code commented out
    return max( texture2D(iChannel0,vec2(x,.25)).x - .2 , .0 )*2.;
}
        
vec2 polar( float k , float t )
{
  return k*vec2(cos(t),sin(t));
}

vec2 cmuli( vec2 z )  { return vec2( -z.y , z.x ); }
vec2 cconj( vec2 z )  { return vec2( z.x , -z.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cexp( vec2 z ) { return polar(exp(z.x) , z.y ); }
vec2 clog( vec2 z ) { return vec2( log(length(z)) , atan(z.y , z.x) ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 cpow( vec2 z , float k ) { return polar(pow(length(z),k) , k*atan(z.y,z.x) ); }

// segment.x is distance to closest point
// segment.y is barycentric coefficient for closest point
// segment.z is length of closest point on curve, on the curve, starting from A
// segment.a is approximate length of curve
vec4 segment( vec2 p, vec2 a, vec2 b )
{
  a -= p;
  b -= p;
  vec3 k = vec3( dot(a,a) , dot(b,b) , dot(a,b) );
  float t = (k.x - k.z)/( k.x + k.y - 2.*k.z );
  float len = length(b-a);
    
  if( t < 0. ){
      return vec4( sqrt(k.x) , 0. , 0. , len );
  } else if( t > 1. ){
      return vec4( sqrt(k.y) , 1. , len , len );
  } else {
    return vec4( length(a*(1.-t) + b*t) , t , t*len , len );
  }
}

// https://www.shadertoy.com/view/4djSRW
#define ITERATIONS 4


// *** Change these to suit your range of random numbers..

// *** Use this for integer stepped ranges, ie Value-Noise/Perlin noise functions.
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(1031, .1030, .0973, .1099)
//----------------------------------------------------------------------------------------
///  3 out, 2 in...
vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+.1919); // circulosmeos: numbers changed
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 hash3point(vec2 p)
{
    //vec3 col = hash32(p);
    vec3 col = 
            hash32(p*1.25672+vec2(.2,.8))
          * hash32(vec2(p.y,p.x)/3.42464-vec2(.5,.0))
          - hash32(vec2(3.0+p.y,1.2))
    ;
    
    return pow(
        (abs(col)+max(col,0.0))/2.0
        , vec3(.6,.5,.4)
    );
}

float smoothFunction(float k)
{
    return 1.0 / ( 1.0 + k*k );
}

vec3 smoothFunction(vec3 k)
{
    return 1.0 / ( 1.0 + k*k );
}


float coeffDistPoint(vec2 uv,vec2 colPoint,float scale)
{    
    //float dist = length(uv - colPoint) * scale;
    //dist = pow(dist,0.25);
    //dist = 1.0 - smoothstep(0.0,1.0,dist);
    
    vec2 uv_ = (uv - colPoint)*scale*24.0;
    float dist = dot(uv_,uv_);
    return  1.0 / ( 1.0 + dist );
}

void mixColorPoint(vec2 uv,inout vec3 col,vec2 colPoint,float scale)
{
    col = mix(
        col , 
        hash3point(colPoint) ,
        coeffDistPoint(uv,colPoint,scale)
    );
}


vec3 mixColorLine(vec2 uv,vec3 currentCol,vec3 colLine,vec2 lineA,vec2 lineB,float scale)
{
    return mix(
        currentCol , 
        colLine ,
        1.0 - smoothstep(0.0,1.0,sqrt(sqrt( segment(uv,lineA,lineB).x * scale )))
    );
}

bool pointsOnSameSideOfLine(vec2 pointA,vec2 pointB,vec2 lineA, vec2 lineB)
{
    vec2 n = lineB - lineA;
    n = vec2(n.y,-n.x);
    return  dot(pointA-lineA,n)
          * dot(pointB-lineA,n)
    > 0.0;
}


float viewportMagnify = 1.0;
vec2 screenToViewport(vec2 uv)
{
    return (uv - iResolution.xy/2.0 ) / min(iResolution.x,iResolution.y) * viewportMagnify;
}

vec2 viewportToScreen(vec2 uv,vec2 base)
{
    return (uv - base/4.0) / viewportMagnify * min(iResolution.x,iResolution.y) +  iResolution.xy/2.0;
    //return (uv - iResolution.xy/2.0 ) / min(iResolution.x,iResolution.y) * viewportMagnify;
}

// there is three kind of points
// in kisrhombille
// named here A,B,C
struct Equerre
{
    vec2 A; // Right angle  => 4 connections
    vec2 B; // Acute angle  => 12 connections
    vec2 C; // Obtuse angle => 6 connections
    
    vec2 D; // on AB
    vec2 E; // on BC
    
    float r;
    float ID;
};
    
// when decomposing an A,B,C triangle into thre subtriangles
// A & B stays respectively A & B points
// C becomes a B point
// D created is a C point
// E created is an A point
    
float det22(vec2 a,vec2 b)
{
    return a.x*b.y - a.y*b.x;
}

vec3 barycentricCoordinate(vec2 P,Equerre T)
{
    vec2 PA = P - T.A;
    vec2 PB = P - T.B;
    vec2 PC = P - T.C;
    
    vec3 r = vec3(
        det22(PB,PC),
        det22(PC,PA),
        det22(PA,PB)
    );
    
    return r / (r.x + r.y + r.z);
}

/*    
#define EQUERRE_COPY(T,Q) \
    T.A = Q.A; \
    T.B = Q.B; \
    T.C = Q.C;
    
#define EQUERRE_COMPUTE_DE(T) \
    T.D = (2.0 * T.A + T.B)/3.0; \
    T.E = (T.B + T.C)/2.0;
    
#define EQUERRE_GET1(T,Q) \
    T.A = Q.A; \
    T.B = Q.C; \
    T.C = Q.D;

#define EQUERRE_GET2(T,Q) \
    T.A = Q.E; \
    T.B = Q.B; \
    T.C = Q.D;

#define EQUERRE_GET3(T,Q) \
    T.A = Q.E; \
    T.B = Q.C; \
    T.C = Q.D;


#define EQUERRE_GET_NEIGHBOUR_AB(T,Q) \
    T.A = Q.A; \
    T.B = Q.B; \
    T.C = 2.0 * Q.A - Q.C;

#define EQUERRE_GET_NEIGHBOUR_AC(T,Q) \
    T.A = Q.A; \
    T.B = 2.0 * Q.A - Q.B; \
    T.C = Q.C;

#define EQUERRE_GET_NEIGHBOUR_BC(T,Q) \
    T.A = (3.0 * Q.C + Q.B)/2.0 - Q.A; \
    T.B = Q.B; \
    T.C = Q.C;

#define EQUERRE_COND1(X,T) \
    pointsOnSameSideOfLine(uv,T.A,T.D,T.C)
 
#define EQUERRE_COND2(X,T) \
    pointsOnSameSideOfLine(uv,T.B,T.D,T.E)

#define EQUERRE_CENTER(T) ((T.A+T.B+T.C)/3.0)
*/
        

// Base Triangle
Equerre Tri;

float TriangleAngle;
//float k = 1./(1. - sqrt(3.)*.5);
float RadiusCoeff;
float AngleCoeff;
float k;

vec2 A,B,C,D,E,F,G,H;
bool AB,BC,CD,DA;


float logZoom = 0.;
float angleShift = 0.;

#define POINT_SPIRAL(n,m) (polar( pow(k,(n + logZoom)/2.) , (n)*AngleCoeff + m*PI/2. - angleShift ))
// why nPI/3 and not nPI/6 ???????????????????????????

void ComputeSpiralPoints(float r)
{
    A = POINT_SPIRAL(r,0.);
    B = POINT_SPIRAL(r,1.);
    C = POINT_SPIRAL(r,2.);
    D = POINT_SPIRAL(r,3.);
    
    E = POINT_SPIRAL(r+1.,3.);
    F = POINT_SPIRAL(r+1.,0.);
    G = POINT_SPIRAL(r+1.,1.);
    H = POINT_SPIRAL(r+1.,2.);
}


bool FindEquerre(float r,vec2 uv)
{
    ComputeSpiralPoints(r);
    
    AB = !pointsOnSameSideOfLine(uv,C,A,B);
    BC = !pointsOnSameSideOfLine(uv,D,B,C);
    CD = !pointsOnSameSideOfLine(uv,A,C,D);
    DA = !pointsOnSameSideOfLine(uv,B,D,A);
    
    Tri.r = r;
    bool ret = true;
    
    if(AB && !BC)
    {
        Tri.A = B;
        Tri.B = E;
        Tri.C = F;
        Tri.ID = r*4.+0.;
    }
    else if(BC && !CD)
    {
        Tri.A = C;
        Tri.B = F;
        Tri.C = G;
        Tri.ID = r*4.+1.;
    }
    else if(CD && !DA)
    {
        Tri.A = D;
        Tri.B = G;
        Tri.C = H;
        Tri.ID = r*4.+2.;
    }
    else if(DA && !AB)
    {
        Tri.A = A;
        Tri.B = H;
        Tri.C = E;
        Tri.ID = r*4.+3.;
    }
    else
    {
        //return AB || BC || CD || DA;
        ret = false;
    }
    
    return ret;
}

vec2 deformation_pole = vec2(.5,.0);

vec2 deformation( vec2 uv )
{
    float nbPoles = 2.;
    vec2 ret = vec2(1.,0.);
    
    for(float i = 0. ; i < nbPoles ; i += 1. )
    {
        ret = cmul(ret,uv - polar(deformation_pole.x,2.*PI*i/nbPoles));
    }
    
    //return cdiv( ret/nbPoles , uv );
    return cdiv( ret/nbPoles , cmul(uv,uv) );
    
   // uv = cdiv( cmul( uv + deformation_pole , uv - deformation_pole ) , cmul( uv , uv ) );
    //uv = cdiv(vec2(1.,0.),uv);
    //return uv;
    //return clog( uv + deformation_pole ) - clog( uv - deformation_pole );
    //return cexp( cdiv( uv + deformation_pole , clog( uv - deformation_pole ) ) );
}

vec2 deformation_inverse(vec2 def )
{
    return cdiv(2.*deformation_pole,def -  vec2(1.,0.)) + deformation_pole;
}

float mmod(float x,float y)
{
    return mod(mod(x,y)+y,y);
}

// circulosmeos: code added: define reconverted in function
// 3 subtriangles : ABD BCD CAD
bool CHECK_TRIANGLE(in vec2 uv_s, in vec2 X,in vec2 Y,in vec2 Z, in float n, inout Equerre Tri, out float ScaleID) {
    if( pointsOnSameSideOfLine(uv_s,X,Y,Z) && pointsOnSameSideOfLine(uv_s,Y,X,Z) ) {
        Tri.A = X;
        Tri.B = Y;
        Tri.C = Z;
        ScaleID = n;
        return true;
    } else
        return false;
}

// circulosmeos: code added: define reconverted in function
void OPERATION1(in vec2 uv_s, inout vec3 col, in vec3 EquerreColor, in vec2 x, in vec2 y, in float scale) {
    col = mixColorLine(uv_s,col,EquerreColor,x,y,scale);
}

// circulosmeos: code added
float tanh_func( float n ) {
    float sinhv = .5 * (exp(n) - exp(-n));
    float coshv = .5 * (exp(n) + exp(-n));
    return (sinhv / coshv);
    //return ( ( exp(2.*n) - 1. ) / ( exp(2.*n) + 1. ) );
}
// circulosmeos: code added
vec3 tanh_func( vec3 n ) {
    return vec3( tanh_func(n[0]), tanh_func(n[1]), tanh_func(n[2]) );
}

vec3 color(vec2 uv_s)
{
    float r = floor( log(dot(uv_s,uv_s))/log(k) - logZoom );
    
    
    if( !FindEquerre(r+1.,uv_s) )
    {
        // inside circle
        FindEquerre(r,uv_s);
    }
    
    vec2 D = (Tri.A+Tri.B+Tri.C)/3.0;
    float ScaleID = 0.;
    //vec2 E = (Tri.A*.8 + Tri.B)/(1. + .8);
    //vec2 E = (Tri.A*RadiusCoeff + Tri.B)/(1. + RadiusCoeff);//(Tri.A*dx + Tri.B)/(1. + dx);//

    /*    
    // 3 subtriangles : ABD BCD CAD
    #define CHECK_TRIANGLE(X,Y,Z,n) \
        if( pointsOnSameSideOfLine(uv_s,X,Y,Z) && pointsOnSameSideOfLine(uv_s,Y,X,Z) ) \
        { \
            Tri.A = X; \
            Tri.B = Y; \
            Tri.C = Z; \
            ScaleID = n; \
        }
    
    CHECK_TRIANGLE(Tri.A,Tri.B,D,0.)
    else
        CHECK_TRIANGLE(Tri.B,Tri.C,D,1.)
    else
       CHECK_TRIANGLE(Tri.A,Tri.C,D,2.)
    */

    // circulosmeos: code added: define reconverted in function
    if ( CHECK_TRIANGLE(uv_s, Tri.A,Tri.B,D,0., Tri, ScaleID) ) {
        ;
    }
    else {
        if ( CHECK_TRIANGLE(uv_s, Tri.B,Tri.C,D,1., Tri, ScaleID) ) {
            ;
        }
        else
            CHECK_TRIANGLE(uv_s, Tri.A,Tri.C,D,2., Tri, ScaleID);
    }
        
    /*
    CHECK_TRIANGLE(Tri.A,E,D,0.)
    else
        CHECK_TRIANGLE(E,Tri.B,D,1.)
    else
       CHECK_TRIANGLE(Tri.C,Tri.B,D,2.)
    else
       CHECK_TRIANGLE(Tri.A,Tri.C,D,3.)
      */  
    vec3 col = hash3point(vec2(Tri.ID,Tri.ID*Tri.ID));
    
    col.r *= 1.2 + .5* cos(log(length(Tri.A)));
    col = mix( col , vec3( dot(col,vec3(.3,.5,.2)) ) ,-.8 );

    float freq = mmod(Tri.ID/sqrt(17.),1.)*.9+.1;
    col *= pow( 1.2*max( fft( freq ) - .25 , 0. ) , 2. );

    float scale = 1./viewportMagnify/(1. + dot(uv_s,uv_s)*.3); // LOG correction
    vec3 EquerreColor = vec3(0.0,0.0,0.0);
    
    if(ScaleID == 1.)
    {
        col = vec3(1.2,.8,.5)*col.gbr;
    }
    
    if(ScaleID == 2.)
    {
        col = vec3(.7,.6,1.3)*col.brg;
    }
    
    #if SHOW_SEGMENTS==1
        // circulosmeos: code commented out: define reconverted in function
        /*
        #define OPERATION1(x,y) col = mixColorLine(uv_s,col,EquerreColor,x,y,scale);
        OPERATION1(Tri.A,Tri.B);
        OPERATION1(Tri.B,Tri.C);
        OPERATION1(Tri.C,Tri.A);        
        */
        OPERATION1(uv_s,col,EquerreColor,Tri.A,Tri.B,scale);
        OPERATION1(uv_s,col,EquerreColor,Tri.B,Tri.C,scale);
        OPERATION1(uv_s,col,EquerreColor,Tri.C,Tri.A,scale);
    #endif
    
    
    scale /= 6.;
    //vec3 coeffs = vec3( 1. , tan(PI/2. - TriangleAngle) , tan(TriangleAngle) ) ;//vec3(1.);
    vec3 coeffs = vec3( 1.4 );
    //coeffs.xy -= normalize(uv_s);
    coeffs.xy += polar(1. , - atan(uv_s.y , uv_s.x) ); //  + vec2( fft(.3),fft(.9) )
    
    vec2 TriCenterMix =
          (Tri.A * coeffs.x + Tri.B * coeffs.y + Tri.C * coeffs.z)
        / (coeffs.x + coeffs.y + coeffs.z);
    
    
    
   // TriCenterMix = Tri.B;
    
    #if SHOW_DUAL_POINTS==1
        col *= 3.*(.5 + coeffDistPoint(uv_s,TriCenterMix,scale));
        //col *= 1. - coeffDistPoint(uv_s,TriCenterMix,scale);
    #endif
    
    return col;//mix(vec3(1.),col,1./(1. + dot(uv_s,uv_s)/1e7 ));
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    TriangleAngle = PI * mix(
        1./3.9 ,
        1./2.4 , // cannot go lower than this value :-( 
        //iMouse.x/iResolution.x
        sqrt( -cos(iTime/29.*PI)*.5+.51 )
    );
    
    //TriangleAngle = atan(2.); // Pinwheel
    //TriangleAngle = PI/3.; // Equerre 
    
    //PI * ( mix( 1./12. ,  1./4. ,  iMouse.x/iResolution.x ) + .333 );
    
    angleShift = -iTime*2.;
    logZoom = iTime/sqrt(5.);
    
    RadiusCoeff = 1. / ( 1./tan(TriangleAngle) - 1. );
    k = 1. + 2.*(RadiusCoeff * (1. + RadiusCoeff ) );
    
    AngleCoeff = asin( - RadiusCoeff / sqrt(k) );
    
    vec2 uv = screenToViewport(fragCoord.xy );
    //uv *= mat2(cos(iTime/6.+vec4(0.,1.6,-1.6,0.)));
    
    
    viewportMagnify = 1./mix(4. , 1. , -cos(iTime*PI/17.)*.5 + .5 );
    uv *= viewportMagnify;
    
    vec2 uv_s = deformation(uv);
    
    
    
    
    fragColor.rgb = color(uv_s);

    // circulosmeos: code changed to fit GLESv2: tanh
    //fragColor.rgb = tanh(fragColor.rgb*3.  ); // LOG correction
    fragColor.rgb = tanh_func(fragColor.rgb*3.  ); // LOG correction
}