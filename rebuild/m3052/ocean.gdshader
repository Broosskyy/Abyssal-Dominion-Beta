shader_type canvas_item;
uniform sampler2D wave_noise : repeat_enable, filter_linear;
uniform vec2 camera_world = vec2(2100.0,1450.0);
uniform vec2 viewport_size = vec2(1280.0,720.0);
uniform float map_zoom = 0.8;
void fragment(){
 vec2 world = (UV-vec2(0.5))*viewport_size/map_zoom + camera_world;
 vec2 p=world/210.0;
 float n=texture(wave_noise,p+vec2(TIME*0.009,TIME*0.004)).r;
 float m=texture(wave_noise,p*1.63-vec2(TIME*0.006,TIME*0.008)).g;
 float ripple=sin(p.x*69.0+p.y*43.0+TIME*1.5)*sin(p.y*51.0-p.x*27.0-TIME*0.8);
 float swell=sin(p.x*2.1+p.y*1.6+TIME*0.16)*0.5+0.5;
 float glints=smoothstep(0.73,0.97,n*0.55+m*0.4+ripple*0.10);
 vec3 deep=vec3(0.012,0.075,0.140);
 vec3 blue=vec3(0.023,0.185,0.278);
 vec3 water=mix(deep,blue,clamp(0.18+n*0.54+m*0.25+swell*0.12,0.0,1.0));
 water+=vec3(0.13,0.30,0.36)*glints*0.19;
 float vignette=1.0-0.24*dot(UV-0.5,UV-0.5);
 COLOR=vec4(water*vignette,1.0);
}
