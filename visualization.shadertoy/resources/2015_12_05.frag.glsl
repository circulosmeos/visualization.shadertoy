// https://www.shadertoy.com/view/Msc3DH

#define iTime iGlobalTime/2.5

#define GLSLIFY 1

vec2 geometry(vec3 p);

float sFract(float x){
  x = fract(x); 
  return min(x, x*(1.-x)*8.);
}

vec3 getRulerColor_0_2(float t) {
  float t1 = pow(sFract(t), 5.0);
  float t2 = pow(sFract(t * 10.0), 2.0);
  float t3 = clamp(t1 * 0.25 + t2 * 0.15, 0.0, 1.0);
  vec3 c = mix(mix(vec3(0.1,0.2,1.0), vec3(1.0,0.2,0.1), t*0.5), vec3(1.0), smoothstep(0.2,0.5,t*0.12));
  return vec3(c) - vec3(t3);
}

vec2 squareFrame_1_3(vec2 screenSize) {
  vec2 position = 2.0 * (gl_FragCoord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}

vec2 squareFrame_1_3(vec2 screenSize, vec2 coord) {
  vec2 position = 2.0 * (coord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}

mat3 calcLookAtMatrix_7_1(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));

  return mat3(uu, vv, ww);
}

vec3 getRay_9_4(mat3 camMat, vec2 screenPos, float lensLength) {
  return normalize(camMat * vec3(screenPos, lensLength));
}

vec3 getRay_9_4(vec3 origin, vec3 target, vec2 screenPos, float lensLength) {
  mat3 camMat = calcLookAtMatrix_7_1(origin, target, 0.0);
  return getRay_9_4(camMat, screenPos, lensLength);
}

vec3 calcNormal_2_5(vec3 pos, float eps) {
  const vec3 v1 = vec3( 1.0,-1.0,-1.0);
  const vec3 v2 = vec3(-1.0,-1.0, 1.0);
  const vec3 v3 = vec3(-1.0, 1.0,-1.0);
  const vec3 v4 = vec3( 1.0, 1.0, 1.0);

  return normalize( v1 * geometry( pos + v1*eps ).x +
                    v2 * geometry( pos + v2*eps ).x +
                    v3 * geometry( pos + v3*eps ).x +
                    v4 * geometry( pos + v4*eps ).x );
}

vec3 calcNormal_2_5(vec3 pos) {
  return calcNormal_2_5(pos, 0.002);
}

vec2 calcRayIntersection_3_6(vec3 rayOrigin, vec3 rayDir, float maxd, float precis) {
  float latest = precis * 2.0;
  float dist   = +0.0;
  float type   = -1.0;
  vec2  res    = vec2(-1.0, -1.0);

  for (int i = 0; i < 40; i++) {
    if (latest < precis || dist > maxd) break;

    vec2 result = geometry(rayOrigin + rayDir * dist);

    latest = result.x;
    type   = result.y;
    dist  += latest;
  }

  if (dist < maxd) {
    res = vec2(dist, type);
  }

  return res;
}

vec2 calcRayIntersection_3_6(vec3 rayOrigin, vec3 rayDir) {
  return calcRayIntersection_3_6(rayOrigin, rayDir, 20.0, 0.001);
}

float beckmannDistribution_6_0(float x, float roughness) {
  float NdotH = max(x, 0.0001);
  float cos2Alpha = NdotH * NdotH;
  float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha;
  float roughness2 = roughness * roughness;
  float denom = 3.141592653589793 * roughness2 * cos2Alpha * cos2Alpha;
  return exp(tan2Alpha / roughness2) / denom;
}

float cookTorranceSpecular_8_7(
  vec3 lightDirection,
  vec3 viewDirection,
  vec3 surfaceNormal,
  float roughness,
  float fresnel) {

  float VdotN = max(dot(viewDirection, surfaceNormal), 0.0);
  float LdotN = max(dot(lightDirection, surfaceNormal), 0.0);

  //Half angle vector
  vec3 H = normalize(lightDirection + viewDirection);

  //Geometric term
  float NdotH = max(dot(surfaceNormal, H), 0.0);
  float VdotH = max(dot(viewDirection, H), 0.000001);
  float LdotH = max(dot(lightDirection, H), 0.000001);
  float G1 = (2.0 * NdotH * VdotN) / VdotH;
  float G2 = (2.0 * NdotH * LdotN) / LdotH;
  float G = min(1.0, min(G1, G2));
  
  //Distribution term
  float D = beckmannDistribution_6_0(NdotH, roughness);

  //Fresnel term
  float F = pow(1.0 - VdotN, fresnel);

  //Multiply terms and done
  return  G * F * D / max(3.14159265 * VdotN, 0.000001);
}

float smin_4_8(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

float fogFactorExp2_5_9(
  const float dist,
  const float density
) {
  const float LOG2 = -1.442695;
  float d = density * dist;
  return 1.0 - clamp(exp2(d * d * LOG2), 0.0, 1.0);
}

float intersectPlane(vec3 ro, vec3 rd, vec3 nor, float dist) {
  float denom = dot(rd, nor);
  float t = -(dot(ro, nor) + dist) / denom;

  return t;
}

vec2 rotate2D(vec2 p, float a) {
  return p * mat2(cos(a), -sin(a), sin(a),  cos(a));
}

vec2 mirror(vec2 p, float v) {
  float hv = v * 0.5;
  vec2  fl = mod(floor(p / v + 0.5), 2.0) * 2.0 - 1.0;
  vec2  mp = mod(p + hv, v) - hv;

  if (iMouse.z > 0.0) fl = abs(fl);
    
  return fl * mp;
}

vec2 geometry(vec3 p) {
  p.x += cos(iTime) * 5.0;

  p.xz = mirror(p.xz, 10.0);
  p.xz = rotate2D(p.xz, iTime);
  float d = 99999.;

  d = min(d, length(p - vec3(5, 0, 0)) - 0.5);
  d = min(d, length(p - vec3(0, 0, 5)) - 0.5);
  d = min(d, length(p + vec3(5, 0, 0)) - 0.5);
  d = min(d, length(p + vec3(0, 0, 5)) - 0.5);
  d = smin_4_8(d, length(p) - 2.0 * (sin(iTime) * 0.5 + 0.75), 3.0);
  return vec2(d, 1.0);
}

vec3 draw(vec2 coord, vec3 co, vec3 cd) {
  vec2 uv = squareFrame_1_3(iResolution.xy, coord);
  cd = getRay_9_4(co, co + cd, uv, 2.0);

  vec3 bg = vec3(0.3 + 0.7 * gl_FragCoord.x / iResolution.x, 0.7, 1.2);
  bg *= 1.0 + 0.8 * max(0.0, gl_FragCoord.y / iResolution.y - 0.8);
    
  float u = intersectPlane(co, cd, vec3(0, 1, 0), 0.0);
  vec2  t = calcRayIntersection_3_6(co, cd, 75., 0.01);

  if (max(t.x, u) < 0.0) return pow(bg, vec3(0.75));

  bool plane = (u > 0.0 && t.x > u) || (t.x < 0.0 && u > 0.0);
  vec3 dir = vec3(0, 1, 0);
  vec3 pos, nor, col;

  if (plane) {
    pos = co + cd * u;
    nor = vec3(0, 1, 0);
    col = getRulerColor_0_2(geometry(pos).x);
  } else {
    pos = co + cd * t.x;
    nor = calcNormal_2_5(pos);
    float spec = cookTorranceSpecular_8_7(dir, -cd, nor, 0.5, 0.5);
    float diff = max(0.0, dot(nor, dir));
    col = vec3(spec * 0.8 + diff * vec3(0.5) + 0.4);
  }

  col = mix(col, bg, fogFactorExp2_5_9(plane ? u : t.x, 0.025));

  // circulosmeos: code changed to sync with music
  float bass = texture2D( iChannel0, vec2(400.,0.) ).x * 3.;
  //col = pow(col, vec3(0.75));
  col = pow(col, vec3(0.75 + bass));

  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  fragColor.rgb = draw(fragCoord.xy, vec3(0, 6., 0), normalize(vec3(0.5, -0.25, 0.6)));
  fragColor.a = 1.0;
}
