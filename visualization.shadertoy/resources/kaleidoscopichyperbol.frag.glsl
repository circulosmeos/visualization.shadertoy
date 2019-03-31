// https://www.shadertoy.com/view/MsffRN

#define iTime iGlobalTime

// Created by David Crooks
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define TWO_PI 6.283185
#define PI 3.14159265359

struct Circle {
    float radius;
    vec2 center;
};

const int numCircles = 3;
Circle circles[3];


/*
	Orthoganl Circles represent strait line in hyperbolic space.
	
	see http://mathworld.wolfram.com/PoincareHyperbolicDisk.html.

*/
Circle orthogonalCircle(float theta1,float theta2) {
    
    float theta = 0.5*(theta1 + theta2);
    float dTheta = 0.5*(theta1 - theta2);
    
    float r = abs(tan(dTheta));
   //  float r = 0.5;
    float R = 1.0/cos(dTheta);
    
    vec2 center = vec2(R*cos(theta),R*sin(theta));
    
    return Circle(r,center);
}




void createCircles() {

    float t = 0.5 - 0.5*cos(iTime);

  	float theta = TWO_PI/3.0;
   
    
    float dTheta = 2.43 + 0.152*t;
    
	//for(int i;i<numCircles  )
    circles[0] = orthogonalCircle(0.0,dTheta);
    circles[1] = orthogonalCircle(theta,theta + dTheta);
    circles[2] = orthogonalCircle(2.0*theta,2.0*theta +  dTheta);
}

float arcosh(float x) {
    return log(x + sqrt(x*x - 1.0));
}

float hyperbolicDist(vec2 p, vec2 q){
    return arcosh(1. + 2.*dot(p-q,p-q) / ((1. - dot(p,p))*(1. - dot(q,q))) );
}

bool circleContains(vec2 p, Circle c) { 
   return distance(c.center,p) < c.radius;  
}


/*
	Circle inversion exchanges the inside with the outside of a circle.
	Reflections in hyperbolic space.
*/
vec2 circleInverse(vec2 p, Circle c){
    p -= c.center;
	return p  * c.radius * c.radius / dot(p,p) + c.center;
    
}

bool isEven(int i){
    
    return mod(float(i),2.0) == 0.0;
  //  return i%2 == 0;
    
}

/*
	Iterated Inversion System 
    see this paper http://archive.bridgesmathart.org/2016/bridges2016-367.pdf
    and this shader https://www.shadertoy.com/view/XsVXzW by soma_arc.

	This algorythim for draws tileings on the poncaire disk model of hyperbolic space.
	
	Our array of circles represent the reflections that generate the tiling.
	We repeatedly invert the point in each of the circles and keep track of the total number of inversions.

*/

vec3 iteratedInversion(vec2 p) {
    

    int count = 0;
    bool flag = true;
    
    for(int i=0; i<100; i++) {
        
        flag = true;
        
        
        for(int j = 0; j<numCircles; j++) {
            Circle c = circles[j];

            if(circleContains(p, c)) {
                
                p = circleInverse(p,c);
                flag = false;
                count++;  
                
        	} 
            
        }
        
        if(flag) {
           break;
        }
        
    }
    
    
     return vec3(p,isEven(count));  
   
    
    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
	createCircles();
    
    vec2 uv = 2.0*(fragCoord - 0.5*iResolution.xy) / iResolution.y;
    
  
    vec3 p = iteratedInversion(uv);
    // float r = length(p);  //distance(p
    float r = hyperbolicDist(p.xy,vec2(0.0));
    float theta = atan(p.x,p.y);
    // circulosmeos: code changed to sync with music
    float amp = texture2D( iChannel0, vec2(400.,0.) ).x * 10.;
    float h = 0.66*sin(30.0*r + iTime + amp) + 0.335*sin(3.0*theta) ;
    float g =  0.33*sin(5.0*r + iTime + amp) + 0.666*sin(3.0*theta) ;
    float c =  0.5+0.5*h;
    fragColor = vec4(0.5*h,0.5*h*p.z,g,1.0);
   
}