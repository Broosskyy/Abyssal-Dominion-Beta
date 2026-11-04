shader_type canvas_item;
uniform sampler2D wave_noise : repeat_enable, filter_linear;
uniform sampler2D sea_tile : repeat_enable, filter_linear;
uniform vec2 camera_world=vec2(2100.,1450.);
uniform vec2 viewport_size=vec2(1280.,720.);
uniform float map_zoom=.96;
uniform vec3 region_tint=vec3(.75,1.14,1.12);
void fragment(){
 vec2 world=(UV-.5)*viewport_size/map_zoom+camera_world;
 // Two rotated samples of the same seamless grain tile hide its 400 px repeat.
 mat2 turn=mat2(vec2(.8,.6),vec2(-.6,.8));
 vec3 grain=texture(sea_tile,world/400.).rgb;
 // The second layer drifts slowly, so its specks cross the first layer and the sea twinkles.
 vec3 grain2=texture(sea_tile,turn*world/655.+vec2(.37+TIME*.0045,.11+TIME*.0028)).rgb;
 vec3 sea=mix(grain,grain2,.38);
 float broad=texture(wave_noise,world*.00042+vec2(TIME*.0014,-TIME*.0009)).r;
 float swell=texture(wave_noise,world*.0013-vec2(TIME*.0026,TIME*.0017)).g;
 sea*=.9+broad*.16+(swell-.5)*.06;
 // Wide, soft light patches read as rolling swell instead of a field of white specks.
 sea+=vec3(.035,.06,.075)*smoothstep(.5,.9,broad*.65+swell*.35);
 float twinkle=max(grain.b,grain2.b)-.7;
 sea+=vec3(.06,.10,.14)*clamp(twinkle*2.4,0.,1.)*(.5+.5*sin(TIME*1.3+dot(world,vec2(.031,.047))));
 COLOR=vec4(sea*mix(vec3(1.),region_tint,.5),1.);
}
