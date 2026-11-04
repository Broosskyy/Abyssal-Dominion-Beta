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
 vec2 fine=texture(wave_noise,world*.023+vec2(-TIME*.005,TIME*.003)).rg;
 vec2 slope=d1*cos(a)*.10+d2*cos(b)*.055+normalize(vec2(.4,.9))*cos(c)*.035+(fine-.5)*.16;
 vec3 normal=normalize(vec3(-slope,1.));
 float light=dot(normal,normalize(vec3(-.4,-.6,1.)));
 float crest=pow(max(0.,sin(b)*.35+sin(c)*.2+detail*.45),5.);
 vec3 deep=vec3(.014,.115,.19);vec3 shallow=vec3(.028,.25,.35);
 vec3 sea=mix(deep,shallow,clamp(.26+n*.42+sin(a)*.055,0.,1.));
 sea*=.72+light*.36+(detail-.5)*.18+(fine.r-.5)*.12;
 float glint=pow(smoothstep(.60,.92,fine.r)*smoothstep(.43,.85,detail),5.);
 sea+=vec3(.25,.40,.45)*(crest*.28+glint*.22);
 COLOR=vec4(sea*region_tint,1.);
}
