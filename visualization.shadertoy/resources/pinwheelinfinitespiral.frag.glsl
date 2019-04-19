// https://www.shadertoy.com/view/MdjBDm

#define iTime iGlobalTime/2.

#define SHOW_DUAL_POINTS 0
#define SHOW_SEGMENTS 1

#define PI 3.14159265359
        
vec2 polar( float k , float t )
{
  return k*vec2(cos(t),sin(t));
}

vec2 cnorm( vec2 z )  { return z/length(z); }
vec2 cmuli( vec2 z )  { return vec2( -z.y , z.x ); }
vec2 cconj( vec2 z )  { return vec2( z.x , -z.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cexp( vec2 z ) { return polar(exp(z.x) , z.y ); }
vec2 clog( vec2 z ) { return vec2( log(length(z)) , atan(z.y , z.x) ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }


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


struct Pinwheel
{
    vec2 A; // Right angle, divided into 1 acute and 1 obtuse
    vec2 B; // Acute angle, stays acute
    vec2 C; // Obtuse angle, stays obtuse
    
    vec2 D; // on GA
    vec2 E; // on AB
    vec2 F; // on BC, close to B
    vec2 G; // on BC, close to C
    
    float r;
    float ID;
    float ID2;
};

    
float det22(vec2 a,vec2 b)
{
    return a.x*b.y - a.y*b.x;
}

vec3 barycentricCoordinate(vec2 P,Pinwheel T)
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
    
// circulosmeos: commented out: defines reconverted in functions
/*
#define EQUERRE_COPY(T,Q) \
    T.A = Q.A; \
    T.B = Q.B; \
    T.C = Q.C; \
    T.ID = Q.ID; \
    T.ID2 = Q.ID2; \
    T.r = Q.r; 
    
#define EQUERRE_COMPUTE_DEFG(T) \
    T.E = (T.A + T.B)/2.0; \
    T.F = (3.0 * T.B + 2.0 * T.C)/5.0; \
    T.G = (T.B + 4.0 * T.C)/5.0; \
    T.D = (T.G + T.A)/2.0;
    
#define EQUERRE_GET1(T,Q) \
    T.A = Q.F; \
    T.B = Q.B; \
    T.C = Q.E;

#define EQUERRE_GET2(T,Q) \
    T.A = Q.F; \
    T.B = Q.G; \
    T.C = Q.E;

#define EQUERRE_GET3(T,Q) \
    T.A = Q.D; \
    T.B = Q.E; \
    T.C = Q.G;

#define EQUERRE_GET4(T,Q) \
    T.A = Q.D; \
    T.B = Q.E; \
    T.C = Q.A;

#define EQUERRE_GET5(T,Q) \
    T.A = Q.G; \
    T.B = Q.A; \
    T.C = Q.C;

#define EQUERRE_COND_12_345(X,T) \
    pointsOnSameSideOfLine(X,T.F,T.E,T.G)
 
#define EQUERRE_COND_1_2(X,T) \
    pointsOnSameSideOfLine(X,T.B,T.E,T.F)

#define EQUERRE_COND_34_5(X,T) \
    pointsOnSameSideOfLine(X,T.E,T.A,T.G)
        
#define EQUERRE_COND_3_4(X,T) \
    pointsOnSameSideOfLine(X,T.G,T.E,T.D)
        
#define EQUERRE_CENTER(T) ((T.A+T.B+T.C)/3.0)
*/
        

// Base Triangle
Pinwheel Tri;

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


// circulosmeos: defines reconverted in functions
void EQUERRE_COPY( inout Pinwheel T, inout Pinwheel Q) {
    T.A = Q.A;
    T.B = Q.B;
    T.C = Q.C;
    T.ID = Q.ID;
    T.ID2 = Q.ID2;
    T.r = Q.r;     
}

void EQUERRE_COMPUTE_DEFG(inout Pinwheel T) {
    T.E = (T.A + T.B)/2.0;
    T.F = (3.0 * T.B + 2.0 * T.C)/5.0;
    T.G = (T.B + 4.0 * T.C)/5.0;
    T.D = (T.G + T.A)/2.0;
}
    
void EQUERRE_GET1(inout Pinwheel T, inout Pinwheel Q) {
    T.A = Q.F;
    T.B = Q.B;
    T.C = Q.E;
}

void EQUERRE_GET2(inout Pinwheel T, inout Pinwheel Q) {
    T.A = Q.F;
    T.B = Q.G;
    T.C = Q.E;
}

void EQUERRE_GET3(inout Pinwheel T, inout Pinwheel Q) {
    T.A = Q.D;
    T.B = Q.E;
    T.C = Q.G;
}

void EQUERRE_GET4(inout Pinwheel T, inout Pinwheel Q) {
    T.A = Q.D;
    T.B = Q.E;
    T.C = Q.A;
}

void EQUERRE_GET5(inout Pinwheel T, inout Pinwheel Q) {
    T.A = Q.G;
    T.B = Q.A;
    T.C = Q.C;
}

bool EQUERRE_COND_12_345( vec2 X, Pinwheel T) {
    return pointsOnSameSideOfLine(X,T.F,T.E,T.G);
}
 
bool EQUERRE_COND_1_2( vec2 X, Pinwheel T) {
    return pointsOnSameSideOfLine(X,T.B,T.E,T.F);
}

bool EQUERRE_COND_34_5( vec2 X, Pinwheel T) {
    return pointsOnSameSideOfLine(X,T.E,T.A,T.G);
}
        
bool EQUERRE_COND_3_4( vec2 X, Pinwheel T) {
    return pointsOnSameSideOfLine(X,T.G,T.E,T.D);
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


bool FindTriangle(float r,vec2 uv)
{
    ComputeSpiralPoints(r);
    
    AB = !pointsOnSameSideOfLine(uv,C,A,B);
    BC = !pointsOnSameSideOfLine(uv,D,B,C);
    CD = !pointsOnSameSideOfLine(uv,A,C,D);
    DA = !pointsOnSameSideOfLine(uv,B,D,A);
    
    Tri.r = r;
    bool k = true;
    
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
        k = false;
    }
    
    return k;
}

vec2 deformation_pole = vec2(.5,.0);

vec2 deformation( vec2 uv )
{
    //uv = cdiv( uv + deformation_pole , uv - deformation_pole );
    //uv = cdiv(vec2(1.,0.),uv);
    return uv;
    //return clog( uv + deformation_pole ) - clog( uv - deformation_pole );
    //return cexp( cdiv( uv + deformation_pole , clog( uv - deformation_pole ) ) );
}

vec2 deformation_inverse(vec2 def )
{
    return cdiv(2.*deformation_pole,def -  vec2(1.,0.)) + deformation_pole;
}

float qLimit;

// circulosmeos: code added: define reconverted in function
void OPERATION1(in vec2 uv_s, inout vec3 col, in vec3 EquerreColor, in vec2 x, in vec2 y, in float scale) {
    col = mixColorLine(uv_s,col,EquerreColor,x,y,scale);
}

vec3 colorTriangle(vec2 uv_s,Pinwheel Tri)
{
    
    vec3 col = hash3point(vec2(
        // coloring algorithm
        Tri.ID+cos(Tri.ID2),sin(Tri.ID*3.)-Tri.ID2
    ));
    
    //col = vec3(1.);
    
    //vec3 col = hash3point(vec2(Tri.ID,Tri.ID*Tri.ID));
    
    /*Tri.A = deformation_inverse(Tri.A);
    Tri.B = deformation_inverse(Tri.B);
    Tri.C = deformation_inverse(Tri.C);
    uv_s = uv;*/

    float scale = 1./viewportMagnify/(1. + dot(uv_s,uv_s)*1.); // LOG correction
    vec3 EquerreColor = vec3(0.0,0.0,0.0);
    
    
    
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
    
    
    scale /= 3.;
    vec2 TriCenterMix = (Tri.A + Tri.B + Tri.C)/3.;
   // TriCenterMix = Tri.B;
    
    #if SHOW_DUAL_POINTS==1
        col *= 3.*(.5 + coeffDistPoint(uv_s,TriCenterMix,scale));
        //col *= 1. - coeffDistPoint(uv_s,TriCenterMix,scale);
    #endif
    
    return col*2./(1. + dot(uv_s,uv_s)/1e3 );
}

vec3 color(vec2 uv_s)
{
    float r = floor( log(dot(uv_s,uv_s))/log(k) - logZoom );
    
    
    if( !FindTriangle(r+1.,uv_s) )
    {
        // inside circle
        FindTriangle(r,uv_s);
    }
    
    
    
    int nbIterations = 6;
    
    Pinwheel Tri_TMP;
    Tri.ID2 = 0.;
    
    bool direction = false;
    #define ID_DIRECTION(x) (direction ? 4.-x : x)
      
    EQUERRE_COPY(Tri_TMP,Tri);
    float q;
    
    // circulosmeos: code changed to sync with music
    //qLimit = ( 1. / mix( 1. , 1./.14  , iMouse.x/iResolution.x ) )/5.*viewportMagnify;
    float bass = texture2D( iChannel0, vec2(400.,0.) ).x * iResolution.x;
    qLimit = ( 1. / mix( 1. , 1./.14  , ((bass>0.2)?bass:2.)/iResolution.x ) )/3.*viewportMagnify;
    
    for(int i = 0 ; i < nbIterations ; i++)
    {
        Tri_TMP.ID2 *= 5.;
        EQUERRE_COMPUTE_DEFG(Tri);
        
        if( EQUERRE_COND_12_345(uv_s,Tri) )
        {
            if( EQUERRE_COND_1_2(uv_s,Tri) )
            {
                EQUERRE_GET1(Tri_TMP,Tri);
                Tri_TMP.ID2 += ID_DIRECTION(0.);
            }
            else
            {
                EQUERRE_GET2(Tri_TMP,Tri);
                Tri_TMP.ID2 += ID_DIRECTION(1.);
                direction = !direction;
            }
        }
        else if( EQUERRE_COND_34_5(uv_s,Tri) )
        {
            if( EQUERRE_COND_3_4(uv_s,Tri) )
            {
                EQUERRE_GET3(Tri_TMP,Tri);
                Tri_TMP.ID2 += ID_DIRECTION(2.);
                direction = !direction;
            }
            else
            {
                EQUERRE_GET4(Tri_TMP,Tri);
                Tri_TMP.ID2 += ID_DIRECTION(3.);
            }
        }
        else 
        {
            EQUERRE_GET5(Tri_TMP,Tri);
            Tri_TMP.ID2 += ID_DIRECTION(4.);
        }
        
        q = length(Tri_TMP.B - Tri_TMP.A)/qLimit;
        if( q < 1. )
        {
            break;
        }
        else
        {
            EQUERRE_COPY(Tri,Tri_TMP);
        }
    }
    
    
    
    
    q = max( 
        (q-1./sqrt(5.))/(1. - 1./sqrt(5.))
        // nice effects here
        * pow(viewportMagnify/length(uv_s),.75)
        * 1.
    , 0. );
    
    return mix(
        colorTriangle(uv_s,Tri),
        colorTriangle(uv_s,Tri_TMP),
        smoothstep(0.,1.,sqrt(q))
    );
    
    //return colorTriangle(uv_s,Tri);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    TriangleAngle = atan(2.); // Pinwheel
    //TriangleAngle = PI/3.; // Equerre 
    
    //PI * ( mix( 1./12. ,  1./4. ,  iMouse.x/iResolution.x ) + .333 );
    
    angleShift = -iTime*.3;
    logZoom = iTime/sqrt(3.);
    
    RadiusCoeff = 1. / ( 1./tan(TriangleAngle) - 1. );
    k = 1. + 2.*(RadiusCoeff * (1. + RadiusCoeff ) );
    
    AngleCoeff = asin( - RadiusCoeff / sqrt(k) );
    
    vec2 uv = screenToViewport(fragCoord.xy );
    //uv *= mat2(cos(iTime/6.+vec4(0.,1.6,-1.6,0.)));
    
    vec2 uv_s = deformation(uv);
    
    viewportMagnify = 1.;
    //uv_s *= viewportMagnify;
    
    
    fragColor.rgb = color(uv_s);
    // circulosmeos: code changed to fit GLESv2: tanh
    //fragColor.rgb = tanh(fragColor.rgb * 26. / (.2 + qLimit/viewportMagnify*16.)  ); // LOG correction
    fragColor.rgb = tanh_func(fragColor.rgb * 26. / (.2 + qLimit/viewportMagnify*16.)  ); // LOG correction
}