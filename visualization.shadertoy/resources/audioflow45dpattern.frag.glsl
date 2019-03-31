// https://www.shadertoy.com/view/lsBXzm

#define iTime iGlobalTime

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

	vec2 position = ( fragCoord.xy / iResolution.xy ) , iChannel0;

	float color = 0.0;
	color += sin( position.x * cos( iTime / 51.0 ) * 80.0 ) + cos( position.y * cos( iTime / 15.0 ) * 10.0 );
	color += sin( position.y * sin( iTime / 10.0 ) * 40.0 ) + cos( position.x * sin( iTime / 25.0 ) * 40.0 );
	color += sin( position.x * sin( iTime / 5.0 ) * 10.0 ) + cos( position.y * sin( iTime / 35.0 ) * 80.0 );
	
	float b = clamp(0.8-distance(position,iChannel0+iChannel0/4.0)+0.2*sin(3.*iTime),0.05,1.);
	fragColor = vec4( vec3( b*color, sin(iTime)*b*color*sin(5.*iTime+color*sin(iTime+color*sin(iTime+color))), b*sin( color + iTime / 3.0 ) * 0.75 ), 1.0 );
}