shader_type canvas_item;
uniform sampler2D wave_noise : repeat_enable, filter_linear;
uniform sampler2D sea_tile : repeat_enable, filter_linear;
uniform vec2 camera_world=vec2(2100.,1450.);
uniform vec2 viewport_size=vec2(1280.,720.);
uniform float map_zoom=.96;
uniform vec3 region_tint=vec3(.75,1.14,1.12);
float water_hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float water_noise(vec2 p){
 vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(water_hash(cell),water_hash(cell+vec2(1.,0.)),f.x),mix(water_hash(cell+vec2(0.,1.)),water_hash(cell+vec2(1.,1.)),f.x),f.y);
}
void fragment(){
 vec2 world=(UV-.5)*viewport_size/map_zoom+camera_world;
 // Quiet, world-anchored water: broad depth variation and restrained surface light.
 // Two differently scaled samples break up tiling without sharpened grain or sine stripes.
 vec2 flow=vec2(TIME*.006,-TIME*.004);
 float depth=water_noise(world/760.+flow*.17)*.6+water_noise(world/1430.-flow*.09+vec2(13.7,8.2))*.4;
 mat2 turn=mat2(vec2(.8,.6),vec2(-.6,.8));
 vec3 surface=texture(sea_tile,world/640.+flow*.24).rgb;
 vec3 crossing=texture(sea_tile,turn*world/1130.-flow*.16).rgb;
 float detail=dot(mix(surface,crossing,.4),vec3(.2126,.7152,.0722));
 vec3 sea=mix(vec3(.012,.088,.142),vec3(.025,.175,.228),depth);
 sea+=(detail-.22)*vec3(.10,.22,.26);
 // Existing directional wave art is only a faint, small-scale shimmer, never a broad band.
 float ripple=texture(wave_noise,world/190.+flow).g;
 sea+=vec3(.006,.012,.013)*(ripple-.5);
 // The Caribbean stays teal; north and shadow waters retain their authored regional identity.
 sea*=mix(vec3(1.),region_tint/vec3(.75,1.14,1.12),.45);
 COLOR=vec4(clamp(sea,0.,1.),1.);
}
