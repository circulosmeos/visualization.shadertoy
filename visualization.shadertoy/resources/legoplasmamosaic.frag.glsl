// https://www.shadertoy.com/view/MsGGzW

#define iTime iGlobalTime

const float pi = 3.1415926535897;
const float studRad = 0.3;
const float studHeight = 0.2;
const float studBorder = 0.03;
const vec2 halfXY = vec2(0.5, 0.5);

const float yGridDivisor = 20.;

float yGrid;
vec2 gridRes;
vec2 scaledUv;
vec2 gridC;

float atan2(float y, float x)
{
    bool s = (abs(x) > abs(y));
    return mix(pi/2.0 - atan(x,y), atan(y,x), s ? 1. : 0.);
}

// Photoshop/GIMP style multiplicative-ish style filter.
float blend(float a, float b){
    return (a < 0.5) ? 2.*a*b : (1. - 2.*(1.-a)*(1.-b));
}

vec4 blend(vec4 a, vec4 b){
    return vec4(blend(a.x, b.x),
                blend(a.y, b.y),
                blend(a.z, b.z),
                      1);
}

// Chunks up the screen into blocks.
vec2 baseXY(vec2 uv) {
	scaledUv = uv*gridRes;
    gridC = floor(scaledUv);
    return (gridC / gridRes);
}
    
// Essentially convolves a virtual pixel with the stud pattern.
vec4 brickify(vec4 baseColor) {
    vec2 subGrid = scaledUv - gridC - halfXY;
    float rad = length(subGrid);
    
    float lightFactor = smoothstep(-studRad, studRad, subGrid.y);
    
    float pixelsPerGrid = iResolution.x / gridRes.x;
	vec4 borderColor = vec4(lightFactor, lightFactor, lightFactor, (abs(rad - (studRad - 0.5*studBorder)) <= 0.5*studBorder) ? 0.5*clamp(pixelsPerGrid*(0.5 * studBorder - abs(rad - (studRad - 0.5*studBorder))), 0., 1.) : 0.);
    
    
    float rightFactor = 0.3;
    vec4 rightColor = vec4(rightFactor, rightFactor, rightFactor, (0.5 - subGrid.x) <= studBorder ? 0.3 : 0.);
    
    float bottomFactor = 0.3;
    vec4 bottomColor = vec4(bottomFactor, bottomFactor, bottomFactor, (0.5 + subGrid.y) <= studBorder ? 0.3 : 0.);
    
    vec4 fragColor = vec4(0.5,0.5,0.5,1);
    fragColor = mix(fragColor, borderColor, borderColor.w);
    
    if(abs(subGrid.x) <= studRad - 1./pixelsPerGrid && subGrid.y <= 0.){
        float angle = acos(subGrid.x / studRad);
        float yInt = -sin(angle) * studRad;
        
        float vFac = 0.5*smoothstep(0., studHeight, (yInt - subGrid.y) * 1.5*exp(-pow(subGrid.x,2.))/**/);
        float sFac = vFac;
        vec4 shadowColor = vec4(sFac, sFac, sFac, subGrid.y <= yInt ? 1. : clamp(1. - pixelsPerGrid*abs(rad - studRad), 0., 1.));
        fragColor = mix(fragColor, shadowColor, 0.5*shadowColor.w);
    }
    
    
    fragColor = mix(fragColor, rightColor, rightColor.w);
    fragColor = mix(fragColor, bottomColor, bottomColor.w);
    
    fragColor = blend(baseColor, fragColor);
    
    return fragColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    
    yGrid = iResolution.y / yGridDivisor;
	gridRes = vec2(iResolution.x/iResolution.y * yGrid,yGrid);
   
    vec2 uv = /**/baseXY/**/(fragCoord.xy / iResolution.xy);
    float time = iTime * 5.;
    
    uv = uv - halfXY;
    uv += vec2(sin(time / 47.), cos(time / 37.));
    
    float theta = atan2(uv.x, uv.y);
    float r = length(uv);
    
    vec2 rg = vec2(0.5 + 0.5*cos(theta+time / 37. + sin(7.*r + time / 5.)), 0.5 + 0.5*sin(theta+time / 13. + cos(11.*r + time / 17.)));
    
    vec2 uvN = sqrt(abs(uv - rg));
    float thetaN = atan2(uvN.y, uvN.x);
    float rN = length(uvN);
    rg = rg*halfXY + halfXY * vec2(rg.x + pow(cos(thetaN + sin(rN + time / 5.) + time / 43.),2.), rg.y + pow(sin(thetaN + cos(rN + time / 11.) + time / 31.),2.));
    rg *= vec2(abs(sin(rg.x * 17. / 5.)), abs(cos(rg.y * 23. / 3.)));
    float thetaR = atan2(rg.x, rg.y);
    float rgM = length(rg);
    rg = halfXY * (rg + (halfXY+halfXY*vec2(sin(thetaR * rgM)*cos(thetaR * rgM),cos(thetaR + time / 47.)*sin(rgM))));
    
    rg = vec2(mix(sqrt(rg.x),rg.x*rg.x,clamp(rg.y - rg.x,0.,1.)),mix(sqrt(rg.y),rg.y*rg.y,clamp(rg.x - rg.y,0.,1.)));
        
    
    vec4 baseColor = vec4(rg * rg/**/, 0.2,1.0);
	fragColor = /**/brickify/**/(baseColor);
    
}