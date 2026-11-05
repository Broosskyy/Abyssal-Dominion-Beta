extends Button
## Native, scalable HUD chrome. Stock and states come from the actual simulation.
var art: Texture2D
var caption=""
var quantity=""
var nav_mode=false
var latched=false
var cooldown=0.0
var state_label=""
var hero:=false
var pager:=false
var badge_alert:=false
const GOLD=Color("c7a15a")
func _ready() -> void:
	focus_mode=Control.FOCUS_NONE
	clip_text=true
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:add_theme_color_override(state,Color.TRANSPARENT)
	add_theme_font_size_override("font_size",10)
func _outlined(font: Font,text: String,baseline: Vector2,fontsize: int,color: Color) -> void:
	var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
	var pos=Vector2(baseline.x-width*.5,baseline.y)
	draw_string_outline(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,2,Color("071018"))
	draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,color)
func _bezel(center: Vector2,radius: float,gold: Color) -> void:
	draw_circle(center+Vector2(0,3),radius+1.5,Color(0,0,0,.45))
	draw_circle(center,radius,Color("3b2b17"))
	for band in 7:
		var t=float(band)/6.0
		draw_circle(center,(radius-3.5)*(1.0-t*.3),Color("0a161d").lerp(Color("1b3644"),t))
	draw_circle(center,radius,gold,false,1.3,true)
	draw_circle(center,radius-3.5,Color("6e5531"),false,1.0,true)
	draw_arc(center,radius-1.2,PI*1.08,PI*1.78,24,Color(1,.9,.62,.28),1.2,true)
func _band(center: Vector2,radius: float) -> void:
	var points=PackedVector2Array()
	for i in 17:
		var angle=lerpf(PI*.2,PI*.8,float(i)/16.0)
		points.append(center+Vector2(cos(angle),sin(angle))*radius)
	draw_colored_polygon(points,Color(.01,.03,.045,.72))
## Ammunition art ships on opaque square backgrounds; clamping the disc into the art rect keeps UVs inside the texture.
func _disc_texture(texture: Texture2D,rect: Rect2,center: Vector2,radius: float,tint: Color) -> void:
	var points=PackedVector2Array()
	var uvs=PackedVector2Array()
	radius=minf(radius,minf(rect.size.x,rect.size.y)*.5)
	center=rect.get_center()
	for i in 40:
		var angle=TAU*float(i)/40.0
		var point=center+Vector2(cos(angle),sin(angle))*radius
		points.append(point)
		uvs.append((point-rect.position)/rect.size)
	draw_polygon(points,PackedColorArray([tint]),uvs,texture)
func _draw() -> void:
	var hot=not disabled and (latched or button_pressed or is_hovered())
	var gold=Color("f5d78d") if hot else GOLD
	if disabled:gold=Color("746747")
	var font=ThemeDB.fallback_font
	if hero:
		var diameter=minf(size.x,size.y)
		var center=Vector2(size.x*.5,diameter*.5)
		var radius=diameter*.5-2
		if latched:draw_circle(center,radius+2,Color(1,.42,.16,.28))
		_bezel(center,radius,gold)
		draw_circle(center,radius-6,Color("7a5c34"),false,1.0,true)
		if art!=null:
			var dimensions=art.get_size()*diameter*.92/maxf(art.get_width(),art.get_height())
			draw_texture_rect(art,Rect2(center-dimensions*.5+Vector2(0,radius*.06),dimensions),false,Color(1,1,1,.45) if disabled else Color.WHITE)
		if latched:draw_arc(center,radius-5,0,TAU,48,Color("ff9b5a"),2.6,true)
		if not state_label.is_empty():
			var fs=10 if diameter<120 else 12
			_outlined(font,state_label,Vector2(center.x,center.y-radius*.56),fs,Color("80e3dc") if state_label=="BEREIT" else Color("edc68c"))
		if not caption.is_empty():
			var fs=16 if diameter>100 else 13
			_outlined(font,caption,Vector2(center.x,diameter-9),fs,Color("f3e0b6"))
		if cooldown>0:draw_arc(center,radius-7,-PI*.5,-PI*.5+TAU*(1-clampf(cooldown,0,1)),40,Color("e3bf76"),2.6,true)
		return
	if pager:
		var h=minf(size.y*.6,34.0)
		var pill=Rect2(Vector2(2,(size.y-h)*.5),Vector2(size.x-4,h))
		var skin=StyleBoxFlat.new()
		skin.bg_color=Color("0d1d25") if not hot else Color("1d3440")
		skin.border_color=gold;skin.set_border_width_all(2);skin.set_corner_radius_all(int(h*.5))
		skin.shadow_color=Color(0,0,0,.45);skin.shadow_size=3
		draw_style_box(skin,pill)
		var fs=13 if size.x>=56 else 11
		_outlined(font,"◀ %s ▶" % caption,Vector2(size.x*.5,pill.get_center().y+fs*.36),fs,Color("f3e0b6"))
		if not state_label.is_empty():_outlined(font,state_label,Vector2(size.x*.5,pill.position.y-3),9,Color("bfa575"))
		return
	if nav_mode:
		var top=Color("3a3020") if hot else Color("1c282c")
		var bottom=Color("191409") if hot else Color("0a1317")
		var corners=PackedVector2Array([Vector2(1,1),Vector2(size.x-1,1),size-Vector2(1,1),Vector2(1,size.y-1)])
		draw_polygon(corners,PackedColorArray([top,top,bottom,bottom]))
		draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),gold,false,1.0)
		draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),Color(0,0,0,.35),false,1.0)
		draw_line(Vector2(4,3),Vector2(size.x-4,3),Color(1,.86,.55,.22),1)
		if latched:draw_line(Vector2(5,size.y-3),Vector2(size.x-5,size.y-3),Color("f5d78d"),2)
		var icon=minf(minf(size.y-19,size.x-10),40.0)
		if art!=null:draw_texture_rect(art,Rect2(Vector2((size.x-icon)*.5,3),Vector2(icon,icon)),false,Color.WHITE if not disabled else Color(.5,.5,.5))
		var title_size=12 if size.x>=66 else 10
		_outlined(font,caption,Vector2(size.x*.5,size.y-6),title_size,Color("f2dfb1") if not latched else Color("ffe7a6"))
		if not quantity.is_empty():
			var bw=maxf(16.0,font.get_string_size(quantity,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x+8)
			var badge=Rect2(Vector2(size.x-bw-3,3),Vector2(bw,15))
			var chip=StyleBoxFlat.new();chip.bg_color=Color("b8402e") if badge_alert else Color("1f6f6a");chip.set_corner_radius_all(7)
			chip.border_color=Color("f5d78d");chip.set_border_width_all(1)
			draw_style_box(chip,badge)
			_outlined(font,quantity,Vector2(badge.get_center().x,badge.end.y-3.5),10,Color.WHITE)
		return
	var diameter=minf(size.x,size.y)
	var center=Vector2(size.x*.5,size.y*.5)
	var radius=diameter*.5-2
	_bezel(center,radius,gold)
	var labelled=not quantity.is_empty() or not caption.is_empty()
	if art!=null:
		var dimensions=art.get_size()*diameter*.7/maxf(art.get_width(),art.get_height())
		_disc_texture(art,Rect2(center-dimensions*.5-Vector2(0,4 if labelled else 0),dimensions),center,radius-4.5,Color(1,1,1,.35) if disabled else Color.WHITE)
	if hot:draw_circle(center,radius-5,Color("dfb15c"),false,1.2,true)
	if latched:
		draw_arc(center,radius-5,0,TAU,40,Color("80e3dc"),2.2,true)
		draw_circle(center+Vector2(radius*.68,-radius*.68),4,Color("80e3dc"))
	if not state_label.is_empty():
		_outlined(font,state_label,Vector2(center.x,center.y-radius*.45),9 if diameter<105 else 10,Color("80e3dc") if state_label=="BEREIT" else Color("edc68c"))
	if cooldown>0:draw_arc(center,radius-6,-PI*.5,-PI*.5+TAU*(1-clampf(cooldown,0,1)),36,Color("e3bf76"),2,true)
	if labelled:
		_band(center,radius-3.5)
		var text=quantity if not quantity.is_empty() else caption
		var fs=(14 if diameter>=56 else 12) if not quantity.is_empty() else (10 if diameter>=56 else 9)
		_outlined(font,text,Vector2(center.x,center.y+radius*.74),fs,Color("f3e0b6"))
