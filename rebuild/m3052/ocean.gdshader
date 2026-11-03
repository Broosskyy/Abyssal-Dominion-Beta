shader_type canvas_item;
uniform sampler2D wave_noise : repeat_enable, filter_linear;
uniform vec2 camera_world=vec2(2100.,1450.);
uniform vec2 viewport_size=vec2(1280.,720.);
uniform float map_zoom=.96;
uniform vec3 region_tint=vec3(.75,1.14,1.12);
void fragment(){
 vec2 world=(UV-.5)*viewport_size/map_zoom+camera_world;
 vec2 d1=normalize(vec2(.9,.35));vec2 d2=normalize(vec2(-.35,.95));
 float a=dot(world,d1)*.026-TIME*.68;
 float b=dot(world,d2)*.051+TIME*.49;
 float c=dot(world,normalize(vec2(.4,.9)))*.087-TIME*.92;
 float n=texture(wave_noise,world*.0027+vec2(TIME*.003,-TIME*.002)).r;
 float detail=texture(wave_noise,world*.007-vec2(TIME*.004,TIME*.001)).g;
 vec2 slope=d1*cos(a)*.17+d2*cos(b)*.08+normalize(vec2(.4,.9))*cos(c)*.035;
 vec3 normal=normalize(vec3(-slope,1.));
 float light=dot(normal,normalize(vec3(-.4,-.6,1.)));
 float crest=pow(max(0.,sin(b)*.5+sin(c)*.25+detail*.25),5.);
 vec3 deep=vec3(.018,.105,.165);vec3 shallow=vec3(.035,.235,.31);
 vec3 sea=mix(deep,shallow,clamp(.28+n*.36+sin(a)*.09,0.,1.));
 sea*=.72+light*.36;
 sea+=vec3(.18,.30,.32)*crest*.18;
 COLOR=vec4(sea*region_tint,1.);
}
