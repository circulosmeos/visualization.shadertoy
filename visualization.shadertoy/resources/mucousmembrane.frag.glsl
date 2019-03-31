// https://www.shadertoy.com/view/MtVyWz

#define iTime iGlobalTime

//---------------------------------------------------------
// Mucous_Membrane.glsl  by Antony Holzer
// version:   v1.0  9/2018  initial release
// original:  http://glslsandbox.com/e#48575.4 by Catzpaw
// info:      Something that looks like a mucous membrane...
// tags:      2d, membrane, mucous, organic, pattern
//---------------------------------------------------------

#define D 0.6

#define time iTime
#define R iResolution

float wave(vec2 p)
{
  float v = sin(p.x + sin(p.y*2.) + sin(p.y * 0.43));
  return v * v;
}

const mat2 rot = mat2(0.5, 0.86, -0.86, 0.5);

float map(vec2 p)
{
  float v = wave(p);
  p.x += time * 0.224;  p *= rot;  v += wave(p);
  p.x += time * 0.333;  p *= rot;  v += wave(p);
  return abs(1.5 - v);
}

vec3 Mucous_Membrane (vec2 pos)
{
  vec2 uv = (pos * 2.0 - R.xy) / R.y;
  // circulosmeos: code changed to sync with music
  //vec2 mp = iMouse.xy / R.xy;
  vec2 mp = texture2D( iChannel0, vec2(400.,0.) ).xy*100. / R.xy;
  uv.y += mp.y;
  float zoom = 18.0 - 14.0 * mp.x;
  vec2 p = normalize(vec3(uv.xy, 2.3)).xy * zoom;
  p.y += time * 0.2;
  float v = map(p);
  vec3 c = mix(vec3(0.3, 0.0, 0.1), vec3(1.0, 0.3 + map(p * 3.5) * 0.6, 0.5), v);
  vec3 n = normalize(vec3(v - map(vec2(p.x + D, p.y)), v - map(vec2(p.x, p.y + D)), -D));
  vec3 l = normalize(vec3(0.1, 0.2, -0.5));
  v = dot(l, n) + pow(dot(l, n), 88.0);
  c.g *= v*v;
  return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec3 color = Mucous_Membrane (gl_FragCoord.xy);
  color = color * 0.9 +vec3(0.1);   // desaturate a bit
  fragColor = vec4(color, 1);
}