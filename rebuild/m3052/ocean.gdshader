shader_type canvas_item;
uniform sampler2D wave_noise : repeat_enable, filter_linear;
uniform sampler2D sea_tile : repeat_enable, filter_linear;
uniform vec2 camera_world=vec2(2100.,1450.);
uniform vec2 viewport_size=vec2(1280.,720.);
uniform float map_zoom=.96;
uniform vec3 region_tint=vec3(.75,1.14,1.12);
void fragment(){
 vec2 world=(UV-.5)*viewport_size/map_zoom+camera_world;
 // Finer than the old 400-unit tile, so the painted grain stays near the screen pixel.
 vec2 tile_uv=world/210.;
 vec2 texel=vec2(1.6/512.);
 vec3 grain=texture(sea_tile,tile_uv).rgb;
 vec3 soft=(texture(sea_tile,tile_uv+vec2(texel.x,0.)).rgb+texture(sea_tile,tile_uv-vec2(texel.x,0.)).rgb+texture(sea_tile,tile_uv+vec2(0.,texel.y)).rgb+texture(sea_tile,tile_uv-vec2(0.,texel.y)).rgb)*.25;
 grain=clamp(grain*1.65-soft*.65,0.,1.);
 mat2 turn=mat2(vec2(.8,.6),vec2(-.6,.8));
 vec3 cross=texture(sea_tile,turn*world/480.+vec2(TIME*.007,.12+TIME*.004)).rgb;
 vec3 sea=mix(grain,cross,.2);
 sea=clamp((sea-.46)*1.45+.44,0.,1.);
 vec2 flow=vec2(TIME*.014,-TIME*.009);
 float swell=texture(wave_noise,world*.00135+flow).g;
 float ahead=texture(wave_noise,world*.00135+flow+vec2(.004,0.)).g;
 // A thin crest where the swell is rising, instead of a milky wash over the whole sea.
 float crest=smoothstep(.58,.78,swell)*smoothstep(0.,.07,ahead-swell);
 sea=mix(sea,sea*vec3(.55,.72,.9)+vec3(.02,.05,.08),smoothstep(.35,.7,1.-swell)*.45);
 sea+=vec3(.16,.24,.26)*crest;
 float streak=smoothstep(.97,.995,sin(dot(world,vec2(.05,.018))+swell*5.+TIME*.9));
 sea+=vec3(.2,.28,.3)*streak*crest;
 sea*=mix(vec3(.62,.82,1.),region_tint,.62);
 COLOR=vec4(clamp(sea,0.,1.),1.);
}
