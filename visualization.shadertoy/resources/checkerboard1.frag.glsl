// https://www.shadertoy.com/view/XdsyW4

#define iTime iGlobalTime

// This shader by vug is very similar and served as inspiration: 
// https://www.shadertoy.com/view/Xs2GDd

#define PI 3.14159265

// number of tiles in y direction
const float numOfTilesY = 5.0;
    
// palette by Inigo Quilez
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 color(float c) {
// 0.0 < c < 1.0 covers the full palette
    return pal( c, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );
}

vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}


// Value Noise by Inigo Quilez - iq/2013
// https://www.shadertoy.com/view/lsf3WH
float vnoise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    uv.x *= iResolution.x/iResolution.y;
    
    // aa is used in smoothstep for antialiasing. It scales with the number of tiles
    // and with iResolution.
    float aa = 3.0/min(iResolution.x, iResolution.y)*numOfTilesY;

    // distort the uv plane with a shift per pixel
    // the noise has to be scaled by the number of tiles
    float noise = 2.0*PI*vnoise(.5*numOfTilesY*uv+0.2*iTime);
    vec2 shift = .1/(numOfTilesY) * vec2(cos(noise), sin(noise));
    uv += shift;

    // tile the image
    uv *= numOfTilesY;
    vec2 fuv = fract(uv); // fractional part within tile, runs from 0-1
    vec2 iuv = floor(uv); // integer-part index vector of tile
    
    // distance function to the edges of the tiles, based on the fractional part
    // later it will be used as a basis for drawing different sized disks
    vec2 dist = 1.0-2.0*abs(fuv);
    
    // background color
    vec3 col = vec3(0.);
    
    // parameters for moving two layers of disks around, using the integer part of the tiles for randomness
    // circulosmeos: code changed to sync with music
    float amp = texture2D( iChannel0, vec2(400.,0.) ).x * 10.;
    float phase1 = 10.0*random(iuv);
	vec2 shapeShift1 = 0.2*vec2(cos(iTime+phase1+amp),sin(iTime+phase1));
    float phase2 = -4.3*random(iuv);
	vec2 shapeShift2 = 0.3*vec2(cos(2.*iTime+phase2+amp),sin(iTime+phase2));
    
    // first layer of disks, fixed in the local uv coordinate system of the tile
    // colors are controlled by the integer index of the tiles.
    col = mix (color(iuv.y/numOfTilesY+0.1).xyz, col , 1.0-smoothstep(0.1, 0.1+aa, 1.0-length(dist)));
    // second layer of disks, moving around by shapeShift1
    col = mix (color(0.4*iuv.x/numOfTilesY+0.1).xyz, col , 1.0-smoothstep(0.4, 0.4+aa, 1.0-length(dist+shapeShift1)));
    // third layer of disks, moving around with shapeshift2
    col = mix (color(0.5*(iuv.x+iuv.y)/numOfTilesY+0.2).xyz, col , 1.0-smoothstep(0.6, 0.6+aa, 1.0-length(dist+shapeShift2)));

    // Output to screen
    fragColor = vec4(col,1.0);
}