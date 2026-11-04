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
 float broad=texture(wave_noise,world*.0006+vec2(TIME*.0016,-TIME*.0011)).r;
 float swell=texture(wave_noise,world*.0018-vec2(TIME*.003,TIME*.002)).g;
 sea*=.9+broad*.14+(swell-.5)*.05;
 float twinkle=max(grain.b,grain2.b)-.62;
 sea+=vec3(.10,.16,.22)*clamp(twinkle*3.,0.,1.)*(.5+.5*sin(TIME*1.7+dot(world,vec2(.031,.047))));
 COLOR=vec4(sea*mix(vec3(1.),region_tint,.5),1.);
}
