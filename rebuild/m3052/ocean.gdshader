shader_type canvas_item;
uniform sampler2D wave_noise : repeat_enable, filter_linear;
uniform sampler2D sea_tile : repeat_enable, filter_linear;
uniform vec2 camera_world=vec2(2100.,1450.);
uniform vec2 viewport_size=vec2(1280.,720.);
uniform float map_zoom=.96;
uniform vec3 region_tint=vec3(.75,1.14,1.12);
uniform bool surface_motion=true;
uniform bool web_classic=false; // Classic browser sea: two bounded texture samples
uniform bool web_fast=false; // Browser fast mode only: lower-cost ocean surface
float water_hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float water_noise(vec2 p){
 vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(water_hash(cell),water_hash(cell+vec2(1.,0.)),f.x),mix(water_hash(cell+vec2(0.,1.)),water_hash(cell+vec2(1.,1.)),f.x),f.y);
}
void fragment(){
 vec2 world=(UV-.5)*viewport_size/map_zoom+camera_world;
 float sea_time=surface_motion?TIME:0.;
 if(web_classic){
  // Calm teal sea: a world-anchored tile and a drifting swell sample,
  // no per-pixel trig, no procedural hash, no particle/reflection passes.
  vec3 tile=texture(sea_tile,world/610.+vec2(sea_time*.0015,-sea_time*.001)).rgb;
  vec2 swell=texture(wave_noise,world/340.+vec2(sea_time*.011,-sea_time*.007)).rg;
  float crest=smoothstep(.52,.72,swell.r);
  float trough=smoothstep(.28,.54,swell.g);
  float detail=dot(tile,vec3(.213,.715,.072));
  vec3 sea=vec3(.026,.192,.313)+vec3(.072,.097,.111)*(detail-.32);
  sea+=vec3(.014,.032,.040)*crest-vec3(.006,.012,.016)*(1.-trough);
  sea*=mix(vec3(1.),region_tint/vec3(.75,1.14,1.12),.38);
  COLOR=vec4(clamp(sea,0.,1.),1.);
 }else if(web_fast){
  // At 1080x2340 this saves millions of sine/hash evaluations and four
  // texture samples per frame. It retains the animated, world-anchored sea
  // tile, a broad shaded gradient and region tint without noisy CPU work.
  vec2 drift=vec2(sea_time*.004,-sea_time*.003);
  vec3 tile=texture(sea_tile,world/700.+drift).rgb;
  float tone=dot(tile,vec3(.2126,.7152,.0722));
  float broad=texture(wave_noise,world/1000.-drift*.25).r;
  vec3 sea=mix(vec3(.019,.148,.270),vec3(.035,.263,.404),broad*.6+.2);
  sea+=(tone-.28)*vec3(.085,.145,.164);
  sea*=mix(vec3(1.),region_tint/vec3(.75,1.14,1.12),.45);
  COLOR=vec4(clamp(sea,0.,1.),1.);
 }else{
 // Quiet, world-anchored water: broad depth variation and restrained surface light.
 // Two differently scaled samples break up tiling without sharpened grain or sine stripes.
 vec2 flow=vec2(sea_time*.006,-sea_time*.004);
 float depth=water_noise(world/760.+flow*.17)*.6+water_noise(world/1430.-flow*.09+vec2(13.7,8.2))*.4;
 mat2 turn=mat2(vec2(.8,.6),vec2(-.6,.8));
 vec3 surface=texture(sea_tile,world/640.+flow*.24).rgb;
 vec3 crossing=texture(sea_tile,turn*world/1130.-flow*.16).rgb;
 float detail=dot(mix(surface,crossing,.4),vec3(.2126,.7152,.0722));
 // Deep blue water with structured but restrained surface variation.
 // All sampling uses WORLD position to avoid texture sliding under the hulls.
 vec3 sea=mix(vec3(.019,.148,.270),vec3(.035,.263,.404),depth);
 sea+=(detail-.28)*vec3(.092,.166,.182);
 // Two animated, intersecting small waves give water a surface rather than
 // looking like a flat wallpaper. The broad underlying sea remains calm.
 float wave_a=texture(wave_noise,world/240.+vec2(sea_time*.013,-sea_time*.006)).g;
 float wave_b=texture(wave_noise,turn*world/405.-vec2(sea_time*.006,sea_time*.004)).r;
 float crest=smoothstep(.54,.76,wave_a*.61+wave_b*.39);
 float mid=smoothstep(.42,.75,wave_b);
 sea+=vec3(.042,.071,.079)*crest+vec3(.006,.013,.019)*(mid-.35);
 // Dark troughs reinforce the visible high-water crests without
 // scattering bright noise over the whole screen on mobile.
 sea-=vec3(.008,.014,.018)*(1.-depth);
 // The Caribbean stays teal; north and shadow waters retain their authored regional identity.
 sea*=mix(vec3(1.),region_tint/vec3(.75,1.14,1.12),.45);
 COLOR=vec4(clamp(sea,0.,1.),1.);
 }
}
