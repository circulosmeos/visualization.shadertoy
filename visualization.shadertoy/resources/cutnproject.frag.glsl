// https://www.shadertoy.com/view/XdtBzH

#define iTime iGlobalTime

/*--------------------------------------------------------------------------
 Aperiodic tiling
 by knighty (april 2018)
 License: Free
 Info: Uses cut and project method. The pixel is tested for which tile it 
       belongs to. Unlike The usual method that draws the tiles "one by one"
       thus have cost proportionnal to the number of drawn tiles, the cost
       per pixel in this shader is bound by a -rather big- constant. 
       ... WIP :o)
 For an interactive version, see: https://www.shadertoy.com/view/Xs3fDr

 Some references (both by Greg Egan.):
 - https://plus.google.com/u/0/113086553300459368002/posts/VJBnyhxH44y
   (With a cool aniated gif that visually explains almost every thing.)
 - https://plus.google.com/u/0/113086553300459368002/posts/aMm17RELcsJ
   (With links to articles and applets)
--------------------------------------------------------------------------*/


//the two vectors defining the cut and project plane
float udir[5];
float vdir[5];

//the 3 directions perpendicular to the cut and project plane
float u2dir[5];
float v2dir[5];
float adir[5];
//Cut and project plane origin
float CPO[5];

//results of tiling search
struct Data{
	float dist;
	ivec2 sides;
	vec2 posInTile;
};

void init(){
	float CP_tans_u2dir = 0.; 
    float CP_tans_v2dir = 0.;
    float CP_tans_adir  = 2.2*sin(iTime*0.25);
    for(int i=0; i<5; i++)
		CPO[i] = CP_tans_u2dir * u2dir[i] + CP_tans_v2dir * v2dir[i] + CP_tans_adir * adir[i];
}

//Gives the coordinates of the point (x,y) on the "cutting" plane into the 5D space
void P2E5(in vec2 z, out float p[5]){
	//float p[5];
	for(int i=0; i<5; i++)
		p[i] = CPO[i] + z.x * udir[i] + z.y * vdir[i];
	//return p;
}

//given a point p, return the nearest vertex in the lattice and the offset.
void getRoundAndOffest(in float p[5], out float ip[5], out float ofs[5]){
	for(int i=0; i<5; i++){
		//ip[i] = round(p[i]);
		ip[i] = ( fract(p[i])>=0.5 )? ceil(p[i]) : floor(p[i]);
		ofs[i] = p[i] - ip[i];
	}
}

//given a vector Ofs, return the vector of 1 when component >0 and -1 otherwise 
void getOfsDir(in float ofs[5], out float dir[5]){
	//float dir[5];
	for(int i=0; i<5; i++){
		//if(ofs[i]>0.) dir[i]=1.; else dir[i]=-1.;
		//dir[i] = 2. * float(ofs[i] > 0.) - 1.;
        dir[i] = ofs[i] > 0. ? 1. : -1.;
	}
	//return dir;
}

//project the vector ofs onto the plane (udir,vdir)
vec2 projectOfs(float ofs[5]){
   //dot products
	vec2 pofs = vec2(0);
	for(int i=0; i<5; i++){
		pofs.x += ofs[i] * udir[i];
		pofs.y += ofs[i] * vdir[i];
	}
	return pofs;
}

//Distance from a to the parallelogramm defined
//by u and v. a is expressed in the (u,v) basis
float Dist22V2(vec2 a, float f){
	vec2 p = abs(a - .5) - .5;//abs(a-vec2(.5))-vec2(.5);
	return max(p.x, p.y) * f;//
}

//Finds if p is inside a the tile defined by (i,j,ip)
//dir is not per se necessary it could be se to 1s
Data section(int i, int j, float p[5], float ip[5], mat2 m, float f, vec2 s){
    //check intersection with dual
    vec2 lhs = vec2(ip[i] - CPO[i], ip[j] - CPO[j]) + 0.5*s;
	vec2 z = lhs * m;
	
    float ofs[5]; float q[5];
	P2E5(z, q);
	//the intersection can be on a neighbouring tile!
	for(int k=0; k<5; k++){
		q[k] = floor(q[k]+.5);
		if(k==i)      ofs[k]=p[k] - (ip[k] + .5 * (s.x - 1.));
        else if(k==j) ofs[k]=p[k] - (ip[k] + .5 * (s.y - 1.));
		else          ofs[k]=p[k] - q[k];
	}
	
	vec2 pofs = projectOfs(ofs);
	
	//get the face corresponding to the intersected dual
    vec2 pit = (m * pofs);
    
	float dist   = Dist22V2(pit, f);
	Data d1 = Data(dist, ivec2(i,j), pit);
	return d1;
}

// circulosmeos: code added
mat2 inverse(mat2 a) {
	mat2 inv;
	inv[0][0] = a[1][1];
	inv[0][1] = -a[0][1];
	inv[1][0] = -a[1][0];
	inv[1][1] = a[0][0];
	inv = 1./(a[0][0]*a[1][1] - a[1][0]*a[0][1]) * inv;
	return inv;
}

//
Data DE(vec2 z){

	float p[5];	P2E5(z, p);
	
	float ip[5], ofs[5], dir[5];
	getRoundAndOffest(p,ip,ofs);
    // dir is the preferred direction. Most of the tiling shows up thanks to it.
    // comment "#define NO_GLITCH" below to see the difference
    // Now faster thanks to dir and coherent branching :).
    // One may notice that when zooming out (a lot) it slows down.
    getOfsDir(ofs, dir);
#define NO_GLITCH

	for(int i=0; i<4; i++)
		for(int j=i+1; j<5; j++)
		{
			//m and f can/should be precomputed!
            // the inverse of m is used to test if:
            // - the projection of p onto cutting plane is inside the current tile
            // - the cut plane intersects the dual of the current tile
            mat2 m = mat2(vec2(udir[i],vdir[i]), vec2(udir[j],vdir[j]));
            // f is a correction factor to get the distance to the boundary of the tile
    		float f = dot(m[0],m[1]); f = sqrt(dot(m[0],m[0]) - f*f / dot(m[1],m[1]));
            //We use the inverse of m in reality :D
    		m = inverse(m);
            
            //Scan the diffrent possible 4 directions
            Data d1 = section(i, j, p, ip, m, f, vec2(dir[i],dir[j]));
			if(d1.dist < 0.) return d1;
		}
    
#ifdef NO_GLITCH    
    for(int i=0; i<4; i++)
		for(int j=i+1; j<5; j++)
		{
			//m and f can/should be precomputed!
            // the inverse of m is used to test if:
            // - the projection of p onto cutting plane is inside the current tile
            // - the cut plane intersects the dual of the current tile
            mat2 m = mat2(vec2(udir[i],vdir[i]), vec2(udir[j],vdir[j]));
            // f is a correction factor to get the distance to the boundary of the tile
    		float f = dot(m[0],m[1]); f = sqrt(dot(m[0],m[0]) - f*f / dot(m[1],m[1]));
            //We use the inverse of m in reality :D
    		m = inverse(m);
            
            vec2 s = vec2(1.,-1.);
            //Scan the diffrent possible 4 directions
            Data d1 = section(i, j, p, ip, m, f, vec2(-dir[i],dir[j]));
			if(d1.dist < 0.) return d1;

			d1 = section(i, j, p, ip, m, f, vec2(dir[i],-dir[j]));
			if(d1.dist < 0.) return d1;
			
			d1 = section(i, j, p, ip, m, f, vec2(-dir[i],-dir[j]));
			if(d1.dist < 0.) return d1;
		}
#endif
    
	return Data(0., ivec2(0), vec2(0));
}

//-------------------------------------------------------------------------------------------
// End of aperiodic tiling
//-------------------------------------------------------------------------------------------

float getFaceSurf(int i, int j){
    float k = abs(float(j-i)-2.5);
    return (k+0.5) * 0.2;
	/*vec2 u,v;
	u[0]=udir[i]; u[1]=vdir[i];
	v[0]=udir[j]; v[1]=vdir[j];
	return abs(u[0]*v[1]-u[1]*v[0]);*/
}

float coverageFunction(float t){
	//this function returns the area of the part of the unit disc that is at the rigth of the verical line x=t.
	//the exact coverage function is:
	//t=clamp(t,-1.,1.); return (acos(t)-t*sqrt(1.-t*t))/PI;
	//this is a good approximation
	return 1.-smoothstep(-1.,1.,t);
	//a better approximation:
	//t=clamp(t,-1.,1.); return (t*t*t*t-5.)*t*1./8.+0.5;//but there is no visual difference
}

#define DRadius .75
#define Width 1.5
#define BackgroundColor vec3(1)
#define CurveColor vec3(0)
#define Gamma 2.2
float coverageLine(float d, float lineWidth, float pixsize){
	d=d*1./pixsize;
	float v1=(d-0.5*lineWidth)/DRadius;
	float v2=(d+0.5*lineWidth)/DRadius;
	return coverageFunction(v1)-coverageFunction(v2);
}

vec3 color(vec2 pos) {
	float pixsize=dFdx(pos.x);
	Data data = DE(pos);
	float v=coverageLine(abs(data.dist), Width, pixsize);
    
	vec3 faceCol = vec3(getFaceSurf(data.sides.x, data.sides.y)*3.5);
    //vec3 faceCol = vec3(data.posInTile,0.);
    faceCol *= texture2D(iChannel1,0.5*data.posInTile).rgb;
    
	return mix(BackgroundColor*faceCol,CurveColor,v);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

	udir[0] = 0.632456;
	udir[1] = 0.19544;
	udir[2] = -0.511667;
	udir[3] = -0.511667;
	udir[4] = 0.19544;

	vdir[0] = 0.;
	vdir[1] = 0.601501;
	vdir[2] = 0.371748;
	vdir[3] = -0.371748;
	vdir[4] = -0.601501;

	u2dir[0] = 0.632456;
	u2dir[1] = -0.511667;
	u2dir[2] = 0.19544;
	u2dir[3] = 0.19544;
	u2dir[4] = -0.511667;

	v2dir[0] = 0.;
	v2dir[1] = 0.371748;
	v2dir[2] = -0.601501;
	v2dir[3] = 0.601501;
	v2dir[4] = -0.371748;

	adir[0] = 0.447214;
	adir[1] = 0.447214;
	adir[2] = 0.447214;
	adir[3] = 0.447214;
	adir[4] = 0.447214;

	vec2 p = 5. * (2.0 * fragCoord.xy - iResolution.xy) / iResolution.y;
	init();
    fragColor = vec4(color(p), 1.0);
}