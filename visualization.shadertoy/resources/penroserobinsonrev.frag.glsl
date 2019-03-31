// https://www.shadertoy.com/view/4t2XWG

#define iTime iGlobalTime

// Penrose/Robinson Tiling Revisited
// (procedural texture and distance field)
// 2015 (C) Tom

// Original shader:
//   http://polycu.be/edit/?h=mh4l7V
//   http://webglplayground.net/?gallery=aperiodic-Penrose-Robinson-tilings

// Subsitution rules:
//   http://tilings.math.uni-bielefeld.de/substitution_rules/robinson_triangle

#define PATTERN 0
  // 0 = textured Penrose tiles
  // 1 = colored Robinson tiles with wiggly pattern

const int base_levels = 9; // base substitution levels

//----------------------------------------------------
// getTile returns:
//   * type = tile type, Robinson code 0..3
//   * q = coordinate in local tile space
//   * rotation matrix to local tile space
//----------------------------------------------------
mat2 getTile(out int type, inout vec2 q, int levels)
{
  const float sc = 1.6180339887498947; // = 2.0/(sqrt(5.0)-1.0) (inflation scale)
  const float pi = 3.1415926535897931;
   
  // Transformations constants:
  
  const float d1 = 1.3763819204711734; // = tan(54*pi/180)
  const float d2 = 0.32491969623290629; // = tan(18*pi/180)
  const float a1 = 0.61803398874989479; // = .5/cos(36*pi/180)
  const float a2 = 0.80901699437494745; // = (1+a1)*.5
  const float a3 = 0.5877852522924728; // = tan(36*pi/180)*a2
  const float cos1 = -0.8090169943749475; // = cos(144*PI/180)*sc
  const float sin1 = 0.5877852522924732; // = sin(144*PI/180)*sc
  const float cos2 = -0.30901699437494734; // = cos(108*PI/180)*sc
  const float sin2 = 0.9510565162951536; // = sin(108*PI/180)*sc

  mat2 m, final_m = mat2(1);
  
  type = (q.y < 0.) ? 1 : 0; // starting prototile
  if (q.y < 0.) {
     // flip rotation matrix as well
     final_m[0].y = -final_m[0].y;
     final_m[1].y = -final_m[1].y;
     q.y = -q.y;
  }
  
  for (int k=0; k<base_levels; k++)  // iterate all subsitutions
  {
     if (k >= levels) break;
     if (type < 2) 
     {
        // We substitute triangle type 0/1
        // with three triangles.
        // We detect in which of those three
        // our current q = (x,y) lies
        // by checking line equations separating them:
        
        if (1.0 - d1*q.y - q.x > 0.0) // left triangle
        {         
           // translate:
           q.x -= 1.;
           
           // mirror:
           m = mat2(-1.,0.,0.,1.);
            
           type = 1 - type; // tile type changes here!
        } 
        else if (1.0 - d2*q.y - q.x > 0.0) // middle triangle
        {
           // translate:
           q -= vec2(a2,a3);
           
           // rotate:
           m = mat2(cos1,sin1,-sin1,cos1);
           
           type = 3 - type; // tile type changes here!
        } 
        else // right triangle
        {      
           // translate (x only):
           q.x -= a1 + 1.;
        
           // rotate:
           m = mat2(cos1,-sin1,sin1,cos1);
        }      
     } 
     else 
     {
        // We substitute triangle type 2/3
        // with two triangles (analogically).
  
        if (d1*q.y - q.x > 0.0) { // upper triangle
        
           // rotate only
           m = mat2(-cos2,sin2,sin2,cos2);
                    
           type -= 2; // tile type changes here!
           
        } else { // lower triangle
        
           // translate (x only):
           q.x -= a1;
           
           // rotate:
           m = mat2(cos2,-sin2,sin2,cos2);
        }
     }  
     
     // final rotate:
     q = m * q; 
     final_m = m * final_m;
     
     // inflaction scale:
     q *= sc;
  }
  
  // return final rotate (e.g. to rotate normal later):
  return final_m;
}

//----------------------------------------------------
// getEdgeDist returns:
//   * distance to closest edge of Penrose tile
//----------------------------------------------------
float getEdgeDist(int type, vec2 q)
{
  const float inv_sc = 0.6180339887498949; // = (sqrt(5.0)-1.0)/2.0
  const float d1 = 1.3763819204711734; // = tan(54*pi/180)
  const float d2 = 0.32491969623290629; // = tan(18*pi/180)
  float dist = 0.;
  if (type < 2) {
     dist = 1.-(d1*q.y+q.x)*inv_sc;
     dist = min(dist, (-d1*q.y+q.x)*inv_sc);
  } else {
     dist = (-d2*q.y+q.x);
     dist = min(dist, (inv_sc-d2*q.y-q.x));
  }
  return dist;
}

//------------------------------------------------------
// getDist returns:
//   * beveled distance to closest edge of Penrose tile
//------------------------------------------------------
float getDist(int type, vec2 q)
{
  float dist = getEdgeDist(type,q);
  return min(dist,.05)*2.+min(dist,.15)*1.;
}

//----------------------------------------------------
// getNorm returns:
//   * beveled normal rotated by "m"
//----------------------------------------------------
vec3 getNorm(int type, vec2 q, mat2 m)
{
  const vec2 eps = vec2(.001,0.);
  vec3 norm = vec3(
     getDist(type,q+eps.xy) - getDist(type,q-eps.xy),
     getDist(type,q+eps.yx) - getDist(type,q-eps.yx),
     eps.x*2.
   );
  norm.xy *= m;
  return normalize( norm );
}

//----------------------------------------------------
// getColor returns:
//   * color from Robinson codes
//----------------------------------------------------
vec3 getColor(int type, vec2 q)
{
  const float r = .05;
  vec3 base;
  if (type >= 2) {
     float f = (type == 2) ? q.y : -q.y;
     f = smoothstep(-r,r,f);
     base = mix(
        vec3(40./255.,80./255.,166./255.),
        vec3(86./255.,110./255.,167./255.),f);
  } else {
     float f = (type == 0) ? q.y : -q.y;
     f = smoothstep(-r,r,f);
     base = mix(
        vec3(255./255.,204./255.,92./255.),
        vec3(255./255.,102./255.,0.),f);
  }
  return base-.1;
}

//----------------------------------------------------
// getTexture returns:
//   * textured tile color
//----------------------------------------------------
vec3 getTexture(int type, vec2 q)
{
  const float r = .05;
  vec3 base;
  if (type >= 2) {
     if (type == 2) q.y = -q.y;
     base = texture2D(iChannel1, q).xyz*vec3(.12,1.,.1) + vec3(.1);
  } else {
     if (type == 0) q.y = -q.y;
     base = texture2D(iChannel0, q).xyz + vec3(.25);
  }
  return base;
}

//----------------------------------------------------
// penrose returns:
//   * color for penrose tile with shading
//----------------------------------------------------
vec3 penrose(mat2 rot, vec2 q0, float sample_size, int levels)
{
  int type;
  vec2 q = q0;
  
  rot = getTile(type, q, levels) * rot;
  
  vec3 norm = getNorm(type, q, rot);
  
  float dist = getDist(type, q);
  
#if PATTERN == 1
  vec3 base = getColor(type, q);
    
  // Fancy wiggly pattern:
  float d;
  if (type < 2) {
     d = abs(sqrt(1.0 - dot(q,q))-.6);
  } else {
     q.x -= 0.61803398874989479;
     d = abs(sqrt(dot(q,q))*1.3-.27);
  }
  float r = pow(2.,float(levels))*.1*sample_size; // sample size
  if (d > 0.) {
    d = (1. - smoothstep(.1-r,.1,d));
    base = mix(base, vec3(1.), d*.5);
  }
    
  float spec = .2;
    
#else
    
  vec3 base = getTexture(type, q);
  float spec = .5;

#endif
 
  // Lighting:
  vec3 light_dir = normalize(vec3(.2,-.6,.5));
  base *= min(1.,dist*5.)*max(0.,dot(norm,light_dir)*.3+.7);
  base += vec3(1)*pow(max(0.,dot(norm,light_dir)),4.)*spec;
  
  return base;
}

//----------------------------------------------------
// Main shader code
//----------------------------------------------------
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  float time = (iMouse.z > 0.) ? iMouse.x*.005 : iTime*.25;
  time += 2.;

  int type;
  float co, si;
  
  vec2 q;
  
  type = 0;
  
  // simple roto-zooming:
  co = cos(time*.6);
  si = sin(time);
  float scale = sqrt(co*co + si*si);
  
  vec2 p = (fragCoord.xy - iResolution.xy*.5)*.5/iResolution.y;
  
  mat2 rot = mat2(co,-si,si,co)*(1./scale);
  q = rot * p * (.5*scale) + vec2(.8,0.);
    
  float sample_size = scale/iResolution.y;
  
  vec3 base, base1, base2;
  float blend = (iMouse.z > 0.) ? smoothstep(-.2,.2,iMouse.y/iResolution.y-.5) : 0.;
  base1 = (blend < 1.) ? penrose(rot, q, sample_size, base_levels) : vec3(0);
  base2 = (blend > 0.) ? penrose(rot, q, sample_size, base_levels-1) : base1;
  base = mix(base1, base2, blend);
    
  base = pow(base,vec3(.6));

  fragColor = vec4(base, 1.0);
}
