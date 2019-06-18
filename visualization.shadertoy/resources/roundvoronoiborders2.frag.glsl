// https://www.shadertoy.com/view/lsSfz1

#define iTime iGlobalTime

/*
	Round Voronoi Borders 2
	-----------------------
	
	I'd been racking my brain for ages trying to come up with a way to produce those 
	cool-looking rounded Voronoi web lattice images in a shader. It's possible to produce 
	cheap approximations (see my last example), but I couldn't see a way to do it 
	correctly, until Abje posted a really simple solution not long ago.

	The idea was incredibly simple: Find the distance from the cell point to the nearest 
	edge using a "smooth" distance metric. That's it... I'm kicking myself. :D I think
	Dr2 may have produced a hexagonal based variant earlier, but I haven't checked the 
	specifics yet.

	Anyway, all I had to do was apply it to a more generalized Voronoi example that
	displayed the correct cell point to closest edge values. IQ wrote one of those ages
	ago, namely, "Voronoi - distances," so I used a variation on that... More precisely, 
	I used an adapted variation of Tomkh's "Faster Voronoi Edge Distance" example, which 
	was based on IQ's. I've provided links to all the shaders below.

	For anyone interested in the specifics, refer to the Voronoi function. If you're 
	familiar with IQ's point to cell-edge example, it should be pretty straight forward.
	By the way, I attempted to speed it up a little, but it wouldn't surprise me if I'd 
	slowed it down instead, so if anyone knows of ways to improve it, feel free to let me
	know.

	I've kept things low tech, so this is just a simple 2D bump mapped example with some
	added bump-based edging. The grungy, edged, comic rendering style is a bit of a cliche. 
	However, I thought it was effective in bringing out the geometry. As you can see, the 
	lines are uniform, rounded, equiwidthed (is that a word?), and don't show any 
	inconsistancies when a gradient or edging is applied. 

	I've also produced a few hybird 2D-3D examples that I'll put up at a later date.

	As for the comments: They're pretty rushed, so I'll tidy them up pretty soon.


	Uses elements from the following:

	// Such a great idea. Released this with no fan fare, so it went relatively unnoticed.
	Round Voronoi - abje
	https://www.shadertoy.com/view/ldXBDs

	// I love this example. The original from which all shaders listed here are based on.
	Voronoi distances - iq
	https://www.shadertoy.com/view/ldl3W8
	// His well written article that describes the process in more detail.
	// http://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm

	// Tomkh's examples are always cleverly constructed and insightful.
	Faster Voronoi Edge Distance - tomkh
	https://www.shadertoy.com/view/llG3zy

	// Rounded hexagonal based Voronoi. I haven't checked the specifics yet, to see how
	// Dr2's algorithm holds up, but it's fast, and the pattern is nicely distributed.
	Desert Town - dr2
	https://www.shadertoy.com/view/XslBDl


*/

// Rigid scroller, which no animation, for those who require rigid metal. :)
//#define SCROLL

// Scene object ID, and individual cell IDs. Used for coloring.
float objID; // The rounded web lattice, or the individual Voronoi cells.
vec2 cellID; // Individual Voronoi cell IDs.

// vec2 to vec1 hash.
float hash21(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(2.7, 5.7))); // circulosmeos: numbers changed
    return fract(n*0.437585453); // circulosmeos: numbers changed
    
    // Animated.
    //return sin(n*6.283 + iTime)*.5 + .5;
    
}

// vec2 to vec2 hash.
vec2 hash22(vec2 p) { 

    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(27, 57)));
    
    #ifdef SCROLL
    return fract(vec2(262.144, 32.768)*n)*.7; // circulosmeos: numbers changed
    #else
    // Animated.
    p = fract(vec2(262.144, 32.768)*n); // circulosmeos: numbers changed
    // Note the ".45," insted of ".5" that you'd expect to see. When edging, it can open 
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work 
    // even better, but then the random movement would become too restricted. Zero would 
    // give you square cells.
    return sin( p*6.2831853 + iTime )*.35 + .35; 
    #endif
}

// IQ's polynomial-based smooth minimum function.
float smin( float a, float b, float k ){

    float h = clamp(.5 + .5*(b - a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1. - h);
}

// Commutative smooth minimum function. Provided by Tomkh and taken from 
// Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin2(float a, float b, float r)
{
   float f = max(0., 1. - abs(b - a)/r);
   return min(a, b) - r*.25*f*f;
}

// IQ's exponential-based smooth minimum function. Unlike the polynomial-based
// smooth minimum, this one is associative and commutative.
float sminExp(float a, float b, float k)
{
    float res = exp(-k*a) + exp(-k*b);
    return -log(res)/k;
}

// This is a variation on a regular 2-pass Voronoi traversal that produces a Voronoi
// pattern based on the interior cell point to the nearest cell edge (as opposed
// to the nearest offset point). It's a slight reworking of Tomkh's example, which
// in turn, is based on IQ's original example. The links are below:
//
// On a side note, I have no idea whether a faster solution is possible, but when I
// have time, I'm going to attempt to find one anyway.
//
// Voronoi distances - iq
// https://www.shadertoy.com/view/ldl3W8
//
// Here's IQ's well written article that describes the process in more detail.
// http://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm
//
// Faster Voronoi Edge Distance - tomkh
// https://www.shadertoy.com/view/llG3zy
vec2 Voronoi(in vec2 p){
    
    // One of Tomkh's snippets that includes a wrap to deal with
    // larger numbers, which is pretty cool.

#if 1
    // Slower, but handles big numbers better.
    vec2 n = floor(p);
    p -= n;
    vec2 h = step(.5, p) - 1.5;
    n += h; p -= h;
#else
    vec2 n = floor(p - 1.);
    p -= n;
#endif
    
    // Storage for all sixteen hash values. The same set of hash values are
    // reused in the second pass, and since they're reasonably expensive to
    // calculate, I figured I'd save them from resuse. However, I could be
    // violating some kind of GPU architecture rule, so I might be making 
    // things worse... If anyone knows for sure, feel free to let me know.
    //
    // I've been informed that saving to an array of vectors is worse.
    //vec2 svO[3];
    
    // Individual Voronoi cell ID. Used for coloring, materials, etc.
    cellID = vec2(0); // Redundant initialization, but I've done it anyway.

    // As IQ has commented, this is a regular Voronoi pass, so it should be
    // pretty self explanatory.
    //
    // First pass: Regular Voronoi.
	vec2 mo, o;
    
    // Minimum distance, "smooth" distance to the nearest cell edge, regular
    // distance to the nearest cell edge, and a line distance place holder.
    float md = 8., lMd = 8., lMd2 = 8., lnDist, d;
    
    for( int j=0; j<3; j++ )
    for( int i=0; i<3; i++ ){
    
        o = vec2(i, j);
        o += hash22(n + o) - p;
        // Saving the hash values for reuse in the next pass. I don't know for sure,
        // but I've been informed that it's faster to recalculate the had values in
        // the following pass.
        //svO[j*3 + i] = o; 
  
        // Regular squared cell point to nearest node point.
        d = dot(o, o); 

        if( d<md ){
            
            md = d;  // Update the minimum distance.
            // Keep note of the position of the nearest cell point - with respect
            // to "p," of course. It will be used in the second pass.
            mo = o; 
            cellID = vec2(i, j) + n; // Record the cell ID also.
        }
       
    }
    

    // Second pass: Distance to closest border edge. The closest edge will be one of the edges of
    // the cell containing the closest cell point, so you need to check all surrounding edges of 
    // that cell, hence the second pass... It'd be nice if there were a faster way.
    for( int j=0; j<3; j++ )
    for( int i=0; i<3; i++ ){
        
        // I've been informed that it's faster to recalculate the hash values, rather than 
        // access an array of saved values.
        o = vec2(i, j);
        o += hash22(n + o) - p;
        // I went through the trouble to save all sixteen expensive hash values in the first 
        // pass in the hope that it'd speed thing up, but due to the evolving nature of 
        // modern architecture that likes everything to be declared locally, I might be making 
        // things worse. Who knows? I miss the times when lookup tables were a good thing. :)
        // 
        //o = svO[j*3 + i];
        
        // Skip the same cell... I found that out the hard way. :D
        if( dot(o-mo, o-mo)>.00001 ){ 
            
            // This tiny line is the crux of the whole example, believe it or not. Basically, it's
            // a bit of simple trigonometry to determine the distance from the cell point to the
            // cell border line. See IQ's article for a visual representation.
            lnDist = dot( 0.5*(o+mo), normalize(o-mo));
            
            // Abje's addition. Border distance using a smooth minimum. Insightful, and simple.
            //
            // On a side note, IQ reminded me that the order in which the polynomial-based smooth
            // minimum is applied effects the result. However, the exponentional-based smooth
            // minimum is associative and commutative, so is more correct. In this particular case, 
            // the effects appear to be negligible, so I'm sticking with the cheaper polynomial-based 
            // smooth minimum, but it's something you should keep in mind. By the way, feel free to 
            // uncomment the exponential one and try it out to see if you notice a difference.
            //
            // // Polynomial-based smooth minimum.
            lMd = smin(lMd, lnDist, .15); 
            //
            // Exponential-based smooth minimum. By the way, this is here to provide a visual reference 
            // only, and is definitely not the most efficient way to apply it. To see the minor
            // adjustments necessary, refer to Tomkh's example here: Rounded Voronoi Edges Analysis - 
            // https://www.shadertoy.com/view/MdSfzD
            //lMd = sminExp(lMd, lnDist, 20.); 
            
            // Minimum regular straight-edged border distance. If you only used this distance,
            // the web lattice would have sharp edges.
            lMd2 = min(lMd2, lnDist);
        }

    }

    // Return the smoothed and unsmoothed distance. I think they need capping at zero... but 
    // I'm not positive.
    return max(vec2(lMd, lMd2), 0.);
}

// Bump mapping function. The Voronoi function above returns two cell point to edge distances: 
// One is the distance using a smooth metric, and the other uses a regular metric. I wanted
// both for aesthetic reasons. The smoothed distance is used for the web lattice, and the 
// other is used for the cell interiors. No smoothing allows the nice sharp edges to show.
// 
float bumpFunc(vec2 p){ 

	vec2 v = Voronoi(p*5.); // Range: [0, 1]
   
    
    /*
    float c;
    if(v.x<.1) {c = abs(v.x - .2); objID = 1.; }
    else c = (v.y - .1)/(1. - .1);
    */
    
    
    float c;
    if(v.x<.1) {c = .1 - v.x; objID = 1.; }
    else c = max((v.y - .1)/(1. - .1), 0.);
    
    return c;

}



void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    // Screen coordinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;
  

    // VECTOR SETUP - surface postion, ray origin, unit direction vector, and light postion.
    //
    // Setup: I find 2D bump mapping more intuitive to pretend I'm raytracing, then lighting a bump mapped plane 
    // situated at the origin. Others may disagree. :)  
    vec3 sp = vec3(uv, 0); // Surface posion. Hit point, if you prefer. Essentially, a screen at the origin.
    vec3 rd = normalize(vec3(uv, 1.)); // Unit direction vector. From the origin to the screen plane.
    vec3 lp = vec3(cos(iTime)*0.5, sin(iTime)*0.2, -2.); // Light position - Back from the screen.
	vec3 sn = vec3(0., 0., -1); // Plane normal. Z pointing toward the viewer.
 
	// Scrolling.
    #ifdef SCROLL
    sp.x -= iTime/8.;
    lp.x -= iTime/8.;
    #endif
    
    // BUMP MAPPING - PERTURBING THE NORMAL
    //
    // Setting up the bump mapping variables. Normally, you'd amalgamate a lot of the following,
    // and roll it into a single function, but I wanted to show the workings.
    //
    // f - Function value
    // fx - Change in "f" in in the X-direction.
    // fy - Change in "f" in in the Y-direction.
    vec2 eps = vec2(2.5/iResolution.y, 0.);
    
    float f = bumpFunc(sp.xy); // Sample value multiplied by the amplitude. 
    
    float svObjID = objID; // Save the scene object ID here.
    
    float fx = bumpFunc(sp.xy-eps.xy); // Same for the nearby sample in the X-direction.
    float fy = bumpFunc(sp.xy-eps.yx); // Same for the nearby sample in the Y-direction.
  
    float fx2 = bumpFunc(sp.xy+eps.xy); // Same for the nearby sample in the X-direction.
    float fy2 = bumpFunc(sp.xy+eps.yx); // Same for the nearby sample in the Y-direction.
    float edge = abs(fx+fy+fx2+fy2 - 4.*f);//abs(fx - f)+ abs(fy - f);
    edge = smoothstep(0., 8., edge/eps.x);//sqrt(edge/eps.x*8.)
   
 	// Controls how much the bump is accentuated.
	const float bumpFactor = 0.15;
    
    // Using the above to determine the dx and dy function gradients.
    fx = (fx-f)/eps.x; // Change in X
    fy = (fy-f)/eps.x; // Change in Y.
    // Using the gradient vector, "vec3(fx, fy, 0)," to perturb the XY plane normal ",vec3(0, 0, -1)."
    // By the way, there's a redundant step I'm skipping in this particular case, on account of the 
    // normal only having a Z-component. Normally, though, you'd need the commented stuff below.
    //vec3 grad = vec3(fx, fy, 0);
    //grad -= sn*dot(sn, grad);
    //sn = normalize( sn + grad*bumpFactor ); 
    sn = normalize( sn + vec3(fx, fy, 0)*bumpFactor );           
   
    
    // LIGHTING
    //
	// Determine the light direction vector, calculate its distance, then normalize it.
	vec3 ld = lp - sp;
	float lDist = max(length(ld), 0.001);
	ld /= lDist;

    // Light attenuation.    
    float atten = 3./(1. + lDist*lDist*.15);
    
    // Using the bump function, "f," to darken the crevices. Completely optional, but I
    // find it gives extra depth.
    atten *= f*.95 + .05; // Or... f*f*.7 + .3; //  pow(f, .75); // etc.
	

	// Diffuse value.
	float diff = max(dot(sn, ld), 0.);  
    // Enhancing the diffuse value a bit. Made up.
    diff = pow(diff, 4.)*0.66 + pow(diff, 8.)*0.34; 
    // Specular highlighting.
    float spec = pow(max(dot( reflect(-ld, sn), -rd), 0.), 12.); 

	
    // TEXTURE COLOR
    //
	// Fake tri-planar texel lookup, and by that I mean, I've moved the Z-position up by a fraction
    // of the heightmap amount to give the impression that this is a 3D lookup. The rest is a  regular
    // tri-planar lookup. Not sure if it made a difference, but it can't hurt.
    vec3 nsn = max(abs(sn), .001);
    nsn /= dot(nsn, vec3(1));
    vec3 texCol = vec3(0), txA, txB, txC;
    sp.z = -f*.25; // Moving the Z position out a bit - That's the fake bit.
    txA = texture2D(iChannel0, sp.xy*2.).xyz;
    txB = texture2D(iChannel0, sp.zx*2.).xyz;
    txC = texture2D(iChannel0, sp.yz*2.).xyz;
    // Rough sRGB to linear conversion... That's a whole other conversation. :)
    texCol = txA*txA*nsn.z + txB*txB*nsn.y + txC*txC*nsn.x; 
    
    texCol = smoothstep(0.05, .57, texCol)*3.; // Enhancing, tweaking the color, etc.
    
    // Individual scene coloring.
    //
    // The interior Voronoi cells.
    if(svObjID<.5) {
        
        // A couple of random numbers. 
    	float rnd = hash21(cellID); // Range: [0, 1].
    	float rnd2 = hash21(cellID + .53); // Range: [0, 1].

        // Color some cells shades of gold. 
        if(rnd2>.5) texCol *= mix(vec3(1, .4, .0)*2., vec3(1), .45); // Lazy. I'll hardcode these later.
        else texCol *=  mix(vec3(1, .7, .3)*2., vec3(1), .15);
        
        // Fade the cells between green and gold... I seemed like a good idea at the time. :)
        rnd = smoothstep(0.4, .6, sin(rnd*6.283 + iTime)*.5 + .5);
        texCol = mix(texCol, texCol*vec3(.8, 1.2, 1), rnd);
    }
    else { // The webbing. Lighten it a bit. I'll tidy up the logic later.
        texCol *= vec3(1, .95, .9)*2.; 
        
    }
    
    // FINAL COLOR
    // Using the values above to produce the final color.   
    vec3 col = (texCol * (diff*vec3(1, .97, .92) + 0.25) + vec3(1., 0.6, .2)*spec*2.)*atten;

    // Make the inner cell edging a little darker than the web edging.
    if(svObjID < .5) col *= 1. - edge*.75;
    else {
        col *= 1. - edge*.65;
        
    }
    
    // Using the gradients in an odd way to give the impression of shadows.
    col *= max(1. + (fy + fx*.5)*.125, 0.); 
    col *= smoothstep(0., .06, f)*.9 + .1; // Extra cell border darkening.
    

    
    
    // Subtle vignette.
    uv = fragCoord/iResolution.xy;
    col *= pow(16.*uv.x*uv.y*(1. - uv.x)*(1. - uv.y) , .25)*1.2;
    // Colored variation... Interesting - I'll give it that much. :)
    //col = mix(pow(min(vec3(1.5, 1, 1)*col, 1.), vec3(1, 2.5, 12.)).zyx, col, 
                    //pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y) , .125))*1.2;
   

    // Perform some statistically unlikely (but close enough) 2.0 gamma correction. :) 
	fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.);
    
}
