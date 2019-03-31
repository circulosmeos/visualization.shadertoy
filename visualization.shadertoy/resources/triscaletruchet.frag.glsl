// https://www.shadertoy.com/view/XttBW7

#define iTime iGlobalTime

/*
	
	Tri Scale Truchet
	-----------------

	This is just a demonstration to show that it's possible to produce a
	multiscale Truchet pattern with non-overlapping tiles. The reason 
	that is of interest is that it's faster and can be more easily 
	adapted to a 3D situation. By the way, I'll put one of those together
	pretty soon.

	This was a pretty easy example to understand... before I kind of went 
    overboard and filled it with defines and esoteric aesthetic code.

	Thankfully, I quickly put together a minimal dual level Truchet example
	to accompany it, which is much easier to digest -- The link is below,
    for anyone interested.

    
    // Far less code, and much easier to understand.
	Minimal Dual-Level Truchet - Shane
    https://www.shadertoy.com/view/ltcfz2

	// More elaborate quadtree example.
	Quadtree Truchet - Shane
	https://www.shadertoy.com/view/4t3BW4

	// Abje always has an interesting way of coding things. :)
	black and white truchet quadtree - abje
	https://www.shadertoy.com/view/MtcBDM


*/


// Display the background grid lines.
#define SHOW_GRID

// Three levels or two. Comment it out for two.
//#define TRI_LEVEL

// Various curve shapes, for anyone curious.
// Circle: 0, Octagon: 1, Dodecahedron: 2, Hexadecagon: 3
#define SHAPE 3

// Just the arcs.
//#define ARCS_ONLY

// vec2 to vec2 hash.
vec2 hash22(vec2 p){ 

    // Faster, but doesn't disperse things quite as nicely.
    // circulosmeos: numbers changed
    //return fract(vec2(262144, 32768)*sin(dot(p, vec2(57, 27))));
    //return fract(vec2(0.262144, 0.32768)*sin(dot(p, vec2(57, 27))));

    // circulosmeos: trying to bind to sound:
    return fract( 
        vec2(0.262144, 0.32768)*sin(dot(p, vec2(57, 27)))*
        texture2D( iChannel0, vec2( 0.01, 0.25 ) ).x
        );
    
}

// Standard 2D rotation formula.
mat2 r2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Cheap and nasty 2D smooth noise function with inbuilt hash function -- based on IQ's 
// original. Very trimmed down. In fact, I probably went a little overboard. I think it 
// might also degrade with large time values, but that's not an issue here.
float n2D(vec2 p) {

	vec2 i = floor(p); p -= i; p *= p*(3. - p*2.);  
    
	return dot(mat2(fract(sin(vec4(0, 27, 57, 84) + dot(i, vec2(27, 57)))*43758.5453))*
                vec2(1. - p.y, p.y), vec2(1. - p.x, p.x) );

}

// FBM -- 4 accumulated noise layers of modulated amplitudes and frequencies.
float fbm(vec2 p){ return n2D(p)*.533 + n2D(p*2.)*.267 + n2D(p*4.)*.133 + n2D(p*8.)*.067; }


// Distance formula with various shape metrics.
// See the "SHAPE" define above.
float dist(vec2 p){
    
    #if SHAPE == 0
    // Standard circular shaped curves.
    return length(p);
    #else
        p = abs(p);
        #if SHAPE == 1
        	// Octagon.
        	return max(max(p.x, p.y), (p.x + p.y)*.7071);
        #elif SHAPE == 2
        	// Dodecahedron.
        	vec2 p2 = p*.8660254 + p.yx*.5;
        	return max(max(p2.x, p2.y), max(p.x, p.y));
        #else
        	// Hexadecagon (regular, 16 sideds) -- There'd be a better formula for this.
        	vec2 p2 = r2(3.14159/8.)*p;
        	float c = max(max(p2.x, p2.y), (p2.x + p2.y)*.7071);
        	return max(c, max(max(p.x, p.y), (p.x + p.y)*.7071));
        #endif
    #endif
    
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    
    // Resolution restriction to avoid a blurry, bloated looking image in fullscreen,
    // This doesn't account for varying PPI, so if you went fullscreen on a high resolution
    // cell phone, you'd want a higher restriction number. Generally speaking, it's 
    // impossible to make a pixel-precise image look even roughly the same on all systems.
    // By the way, this was coded on a 17 inch laptop with a 1920 x 1080 resolution on the
    // 800 x 450 canvas.
    float iRy = min(iResolution.y, 800.); 
    
    // Screen coordinates.
    vec2 uv = (fragCoord - iResolution.xy*.5)/iRy;
    
    // Scaling and translation.
    vec2 oP = uv*4. + vec2(.5, iTime/2.);
    
    // Distance file values.
    vec4 d = vec4(1e5);
    
    // Initial cell dimension.
    float dim = 1.;
    
    // Random entries -- One for each layer. The X values represent the chance that
    // a tile for that particular layer will be rendered. For instance, the large
    // tile will have a 35% chance, the middle tiles, 70%, and the remaining smaller
    // tiles will have a 100% chance. I.e., they'll fill in the rest of the squares.
    
    // circulosmeos: code changed to fit GLESv2: rndTh
    //vec2 rndTh[3] = vec2[3]( vec2(.35, .5), vec2(.7, .5), vec2(1, .5));
    // as only x is used, create rndTh as a vec3
    vec2 rndTh0 = vec2(.35, .5);
    vec2 rndTh1 = vec2(.7, .5);
    vec2 rndTh2 = vec2(1, .5);
    
    // Set the second level random X value to "1." to ensure that the loop breaks on 
    // the second iteration... which is a long way to say, "Two levels only." :)
    #ifndef TRI_LEVEL
    // circulosmeos: code changed: rndTh
    //rndTh[0].x = .5; rndTh[1].x = 1.;
    rndTh0.x = .5; rndTh1.x = 1.;
    #endif
    
    
    // Grid line width, and a global diagonal-side variable.
    const float lwg = .015;
    float side = 1e5;
    
    // Random variable.
    vec2 rnd = vec2(0);
    
    
    for(int k=0; k<3; k++){
    	
        // Base cell ID.
		vec2 ip = floor(oP*dim);
        
        // Unique random ID for the cell.
        rnd = hash22(ip);
       
		// If the random cell ID at this particular scale is below a certain threshold, 
        // render the tile.  
        // circulosmeos: code changed: rndTh
        //if(rnd.x<rndTh[k].x){
        vec2 rndTh;
        (k==1)?(rndTh = rndTh1):( (k==2)?(rndTh = rndTh2):(rndTh = rndTh0) );
        if(rnd.x<rndTh.x){
            
            // Tile construction: By the way, the tile designs you use are limited by your imagination. 
        	// I chose the ones that seemed most logical at the time -- Arcs and grid vertice circles.
      
            // Local cell coordinate.
            vec2 p = oP - (ip + .5)/dim; // Equivalent to: mod(oP, 1./dim) - .5/dim;
            
            // Reusing "rnd" to calculate a new random number. Not absolutely necessary,
            // but I wanted to mix things up a bit more.
            rnd = fract(rnd*27.63 + float(k*57 + 1));
           
            // Grid lines.
 	        d.y = abs(max(abs(p.x), abs(p.y)) - .5/dim) - lwg/2.;

            
            // Use the unique random cell number to flip half the tiles vertically, which,
            // in this case, has the same effect as rotating by 90 degrees.
            p.y *= rnd.y<.5? 1. : -1.;
           
            
            // Arc width: Arranged to be one third of the cell side length. This is half that
            // length, but it gets doubled below.
            float aw = .5/3./dim;

            // Tile rendering: The arcs, circles, etc. I made the tiles up as I went along,
            // but it's just a positioning of arcs and circles, so I'm hoping it's pretty 
            // straight forward. 
            float c1 = abs(dist(p - vec2(.5)/dim) - .5/dim) - aw;
            
            // Arcs only, or a mixture of arcs and circles.
            #ifdef ARCS_ONLY
            float c2 = abs(dist(p - vec2(-.5)/dim) - .5/dim) - aw;
            #else
            float c2;
            if(fract(rnd.y*57.53 +.47)<.35) {
                c2 = dist(p - vec2(-.5, 0)/dim) - aw;
                c2 = min(c2, dist(p - vec2(0, -.5)/dim) - aw);
            }
            else c2 = abs(dist(p - vec2(-.5)/dim) - .5/dim) - aw;
            #endif
            
            // Combining the arc and\or circle elements.
            d.x = min(c1, c2);
            
            // Determining which side of the diagonal the blue neon tri-level lines are on.
            // That way, you can blink them individually.
            side = c1>c2? 0. : 1.57*(rnd.y*.5 + 1.);
            
            
            // Negate the arc distance field values on the second tile.
            d.x *= k==1? -1. : 1.;
            
             
            // Four mid border circles. There's some 90 degree rotation and repeat
            // trickery hidden in amongst this. If you're not familiar with it, it's
            // not that hard, and gets easier with practice.
            vec2 p2 = abs(vec2(p.y - p.x, p.x + p.y)*.7071) - .5*.7071/dim;
            p2 = vec2(p2.y - p2.x, p2.x + p2.y)*.7071;
            float c3 = dist(p2) - aw/2.; 
             
            
            
            // Placing circles at the four corner grid vertices. If you're only rendering
            // one level (rndTh[0].x=1.), you won't need them... unless you like them, I guess. :)
            p = abs(p) - .5/dim;
            // circulosmeos: code changed: rndTh
            //if(k<2 && rndTh[0].x<.99) d.x = min(d.x, (dist(p) - aw));
            if(k<2 && rndTh0.x<.99) d.x = min(d.x, (dist(p) - aw));
            
            // Depending upon which tile scale we're rendering at, draw some circles,
            // or cut some holes. If you look at the individual tiles in the example,
            // you can see why.
            // circulosmeos: code changed: rndTh
            //if(rndTh[1].x<.99){
            if(rndTh1.x<.99){
                
                // Cut out some mid border holes on the first iteration. 
                if(k==0) d.x = max(d.x, -c3); 
                
                // On the middle iteration, cut out vertice corner holes.
                // On the other iterations, add smaller vertice holes.
                // I made this up as I went along, so there's probably a
                // more elegant way to go about it.
                if(k==1) d.x = max(d.x, -(dist(p) - aw));
            	else d.x = max(d.x, -(dist(p) - aw/2.));
                
            	
            }
            
            
            // Increasing the overall width of the pattern slightly.
            d.x -= .01;

            // Since we don't need to worry about neighbors
            break;

        }
        
        // Subdividing. I.e., decrease the cell size by doubling the frequency.
        dim *= 2.;
        
    }
    
   
    
    // RENDERING.
    //
    // More complicated than you need to make it. Most of the following lines were 
    // coded on the fly for decorative purposes.
    
    // Background.
    vec3 bg = vec3(.1);//*vec3(1, .9, .95);
    //float pat =  clamp(sin((oP.x - oP.y)*6.283*iResolution.y/22.5) + .75, 0., 1.);
    //bg *= (pat*.35 + .65);
    float ns = fbm(oP*32.); // Noise.
    bg *= ns*.5 + .5; // Apply some noise to the background.
    
    // Scene color. Initiated to the background.
    vec3 col = bg;

    // Falloff variable.
    float fo;
  
    // Render the grid lines.
    fo = 4./iRy;
    #ifdef SHOW_GRID
    col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d.y - .01))*.5); // Shadow.
    col = mix(col, vec3(1), (1. - smoothstep(0., fo, d.y))*.15); // Overlay.
    #endif


    // Pattern falloff, overlay color, shade and electronic looking overlay.
    fo = 10./iRy/sqrt(dim);
    // Distance field color: I couldn't seem to make vibrant color work, so fell
    // back go greyscale with a dash of color. It's a cliche, but it often works. :)
    vec3 pCol = vec3(.3, .25, .275);
    float sh = max(.75 - d.x*10., 0.); // Distance field-based shading.
    sh *= clamp(-sin(d.x*6.283*18.) + .75, -.25, 1.) + .25; // Overlay pattern.


    // Drop shadow, edges and overlay.
    col = mix(col, vec3(0), (1. - smoothstep(0., fo*5., d.x))*.75);
    col = mix(col, vec3(0), 1. - smoothstep(0., fo, d.x));
    col = mix(col, pCol*sh, 1. - smoothstep(0., fo, d.x + .015));

    // Darkening the rounded quads around the lit centers.
    col = mix(col, bg*sh, 1. - smoothstep(0., fo, max(d.x + .1, -(d.x + .14))));
   
    #ifdef TRI_LEVEL
        // Apply some blue blinking neon to the tri level pattern.
    	vec3 neon = mix(col, col*vec3(1.5, .1, .3).yxz*2., 1. - smoothstep(.7, .9, sin(rnd.y*6.283 + iTime*4. + side)));
    	col = mix(col, col*neon, 1. - smoothstep(0., fo, d.x + .16));
    #else
        // Apply some animated noisy reddish neon to the dual level pattern. 
    	vec3 neon = mix(bg, col*vec3(1.5, .1, .3)*2., smoothstep(-.5, .5, n2D(oP*3. + vec2(iTime*2.))*2. - 1.));
    	col = mix(col, neon, 1. - smoothstep(0., fo, d.x + .16));// + .125
    #endif
            
   
      
    // Add some subtle noise.        
    col *= ns*.25 + .75;
    
    
    // A bit of gradential color mixing.
    col = mix(col.xzy, col, sign(uv.y)*uv.y*uv.y*2. + .5);
    col = mix(col.xzy, col, (-uv.y*.66 - uv.x*.33) + .5);
    
    // Mild spotlight.
    col *= max(1.25 - length(uv)*.25, 0.);
      

    // Rough gamma correction.
    fragColor = vec4(sqrt(max(col, 0.)), 1);
}