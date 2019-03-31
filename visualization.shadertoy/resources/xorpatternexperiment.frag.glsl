// https://www.shadertoy.com/view/XtSGWV

#define iTime iGlobalTime

const int iterationCount = 9;

// square method
// 1 = mod()
// 2 = sin()
// 3 = fract()
#define SQUARE_METHOD 3

// it turns out that the 3 methods here really have no performance difference
// set iterationCount to 1000 and change the method.

//--------------------------------------------------------

const float pi = 3.14159;
const float pi2 = 2. * 3.14159;

// c64 palette because why not.
vec3 color0 = vec3(0,0,0);// black
vec3 color1 = vec3(1,1,1);// white
vec3 color2 = vec3(0.41,0.22,0.17);// red
vec3 color3 = vec3(0.44,0.64,0.70);// cyan
vec3 color4 = vec3(0.44,0.24,0.53);// violet
vec3 color5 = vec3(0.35,0.55,0.26);// green
vec3 color6 = vec3(0.21,0.16,0.47);// blue
vec3 color7 = vec3(0.72,0.78,0.44);// yellow
vec3 color8 = vec3(0.44,0.31,0.15);// orange
vec3 color9 = vec3(0.26,0.22,0);// brown
vec3 colorA = vec3(0.60,0.40,0.35);// light red
vec3 colorB = vec3(0.27,0.27,0.27);// grey1
vec3 colorC = vec3(0.42,0.42,0.42);// grey2
vec3 colorD = vec3(0.60,0.82,0.52);// light green
vec3 colorE = vec3(0.42,0.37,0.71);// light blue
vec3 colorF = vec3(0.58,0.58,0.58);// grey3

float saturate(float a)
{
    return clamp(a,0.,1.);
}
vec2 saturate(vec2 a)
{
    return clamp(a,0.,1.);
}
vec3 saturate(vec3 a)
{
    return clamp(a,0.,1.);
}


#if SQUARE_METHOD == 1
float square(float x, float period)
{
    // using mod()+sign().
    // my feeling is that this is the fastest method, but it makes no difference.
    return sign(mod(x, period)-(period/2.0));
}
#endif
#if SQUARE_METHOD == 2
float square(float x, float period)
{
    // using sin() is obvious
    return sign(sin(x / period * pi2));
}
#endif
#if SQUARE_METHOD == 3
float square(float x, float period)
{
    // this is clever, but is not faster.
    float ret = x / (period);// now fractional part is the mod.
    ret = fract(ret);// now it's 0-1 in the period.
    ret -= 0.5;
    return sign(ret);
}
#endif




vec3 getPalette(int i)
{
    if(i == 0) return color6;
    if(i == 1) return color3;
    if(i == 2) return color5;
    if(i == 3) return color9;
    if(i == 4) return color7;
    return color8;
}


mat2 rot2D(float r)
{
    float c = cos(r), s = sin(r);
    return mat2(c, s, -s, c);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = (fragCoord.xy / iResolution.y * 2.0) - 1.0;// -1 to 1

    // warp & rotate for fun
    float someCycleThing = sin(iTime * 1.2) * 0.5;
    float angle = (1.3 * sin(((uv.x * someCycleThing) + 2.1) * ((uv.y * someCycleThing) + 2.2) * 0.2)) + sin(iTime * 0.22) * cos(iTime * 0.5);
    uv = rot2D(angle) * uv;

    // set up some variables for iteration. the main goal is to calculate 'color'
    // by iteratively mixing colors on it.
    vec3 color = colorE;
    float mixAmt = 1.0;// influence of iteration
    float tileSize = 5.0;
    for(int i = 0; i < iterationCount; ++ i)
    {
       	float z = square(uv.x, tileSize) * square(uv.y, tileSize);
        z = (z+1.0)/2.0;// make 0-1 range
      	color = mix(color, getPalette(i), mixAmt * z);
        tileSize /= 2.;
        mixAmt /= 1.25;
	}
    fragColor = vec4(color,1.0);
    
    // brighten
	fragColor.rgb *= 2.1;
    
    // add a little vignette
    float va = distance(fragCoord, iResolution.xy / 2.0) / max(iResolution.x, iResolution.y);
    va = pow(va, 0.96);
    va = 1.0 - va;
	fragColor.rgb = saturate(fragColor.rgb * va);
    
	//if(length(uv)<.05) fragColor = vec4(1.0);// show a dot at (0,0)
}

