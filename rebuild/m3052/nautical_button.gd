extends Button
## Native, scalable HUD chrome. Stock and states come from the actual simulation.
var art: Texture2D
var caption=""
var quantity=""
var nav_mode=false
var latched=false
var cooldown=0.0
var state_label=""
const GOLD=Color("c7a15a")
func _ready() -> void:
	focus_mode=Control.FOCUS_NONE
	clip_text=true
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:add_theme_color_override(state,Color.TRANSPARENT)
	add_theme_font_size_override("font_size",10)
func _draw() -> void:
	var hot=not disabled and (latched or button_pressed or is_hovered())
	var gold=Color("f5d78d") if hot else GOLD
	if disabled:gold=Color("746747")
	var font=ThemeDB.fallback_font
	if nav_mode:
		draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color("30291c") if hot else Color("101c23"))
		draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),gold,false,1.0)
		for y in 7:draw_line(Vector2(3,3+y),Vector2(size.x-3,3+y),Color(1,.82,.45,.055*(1-float(y)/7)),1)
		draw_line(Vector2(3,size.y-3),Vector2(size.x-3,size.y-3),Color(0,0,0,.65),1)
		draw_circle(Vector2(size.x*.5,19),17,Color("201f18"));draw_circle(Vector2(size.x*.5,19),16,Color("7e673d"),false,1,true)
		if art!=null:draw_texture_rect(art,Rect2(Vector2(size.x*.5-14,5),Vector2(28,28)),false,Color.WHITE if not disabled else Color(.5,.5,.5))
		var title_size=12 if size.x>=66 else 10
		var w=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x
		draw_string(font,Vector2((size.x-w)*.5,size.y-6),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size,Color("f2dfb1"))
		return
	var diameter=minf(size.x,size.y-(12 if not quantity.is_empty() else 0))
	var center=Vector2(size.x*.5,diameter*.5)
	var radius=diameter*.5-3
	draw_circle(center+Vector2(0,3),radius+2,Color(0,0,0,.45))
	for band in 9:
		var t=float(band)/8
		draw_circle(center,radius-t*radius*.22,Color("4c3820").lerp(Color("0b1c26"),t))
	draw_circle(center,radius,gold,false,2.0,true)
	draw_circle(center,radius-4,Color("80623a"),false,1.0,true)
	# Small brass fasteners and a glass sheen keep each control readable at phone scale.
	for angle in [PI*.25,PI*.75,PI*1.25,PI*1.75]:
		var rivet=center+Vector2(cos(angle),sin(angle))*(radius-2)
		draw_circle(rivet,1.5,Color("edcf89"))
	draw_arc(center,radius-6,PI*1.05,PI*1.75,20,Color(1,.9,.6,.16),3,true)
	draw_arc(center,radius-1,PI*1.05,PI*1.8,28,Color("fae1a0"),1.3,true)
	if art!=null:
		var dimensions=art.get_size()*diameter*.68/maxf(art.get_width(),art.get_height())
		draw_texture_rect(art,Rect2(center-dimensions*.5-Vector2(0,3 if not caption.is_empty() else 0),dimensions),false,Color(1,1,1,.35) if disabled else Color.WHITE)
	if hot:draw_circle(center,radius-6,Color("dfb15c"),false,1.2,true)
	if latched:
		draw_arc(center,radius-6,0,TAU,40,Color("80e3dc"),2,true)
		draw_circle(center+Vector2(radius*.65,-radius*.65),4,Color("80e3dc"))
	if not state_label.is_empty():
		var fs=9 if diameter<105 else 10
		var w=font.get_string_size(state_label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		var pos=Vector2(center.x-w*.5,diameter*.27)
		draw_string_outline(font,pos,state_label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,Color("071018"))
		draw_string(font,pos,state_label,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("80e3dc") if state_label=="BEREIT" else Color("edc68c"))
	if cooldown>0:draw_arc(center,radius-7,-PI*.5,-PI*.5+TAU*(1-clampf(cooldown,0,1)),36,Color("e3bf76"),2,true)
	if not caption.is_empty():
		var fs=14 if diameter>70 else 10
		var w=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		draw_string_outline(font,Vector2(center.x-w*.5,diameter-9),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,3,Color("071018"))
		draw_string(font,Vector2(center.x-w*.5,diameter-9),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("f3e0b6"))
	if not quantity.is_empty():
		var w=font.get_string_size(quantity,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		draw_string_outline(font,Vector2(center.x-w*.5,size.y-2),quantity,HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("071018"))
		draw_string(font,Vector2(center.x-w*.5,size.y-2),quantity,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f3e0b6"))
