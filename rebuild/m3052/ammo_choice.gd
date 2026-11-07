extends Button
## A complete ammunition row is the touch target, as on a classic sea-chart client.
var art: Texture2D
var title:=""
var detail:=""
var stock:=""
var loaded:=false
var accent: Color=Color("80e3dc")
var highlight_clock:=0.0
var press_feedback:=0.0
func _process(delta: float) -> void:
	highlight_clock=fposmod(highlight_clock+delta,TAU*64.0)
	if press_feedback>0:press_feedback=maxf(0.0,press_feedback-delta*4)
	if loaded or press_feedback>0:queue_redraw()
func _on_press_visual() -> void:
	press_feedback=1.0
	queue_redraw()
func _ready() -> void:
	focus_mode=Control.FOCUS_NONE
	clip_contents=true
	clip_text=true
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:add_theme_color_override(state,Color.TRANSPARENT)
	button_down.connect(_on_press_visual)
func _ink(font: Font,value: String,point: Vector2,fs: int,color: Color) -> void:
	if point.x>=90:
		var room=size.x-point.x-8
		if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>room:
			while value.length()>1 and font.get_string_size(value+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>room:value=value.left(value.length()-1)
			value+="…"
	draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,2,Color("0a0e12"))
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
func _draw() -> void:
	var font=ThemeDB.fallback_font
	var hot=loaded or is_hovered()
	var shade_top=Color("293e45") if hot else Color("162a34")
	var shade_bottom=Color("0a1a23") if hot else Color("08131b")
	var corners=PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)])
	draw_polygon(corners,PackedColorArray([shade_top,shade_top,shade_bottom,shade_bottom]))
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("e4c784") if loaded else Color("586b72"),false,1.0)
	draw_rect(Rect2(Vector2(4,4),size-Vector2(8,8)),Color("243640",.65),false,.7)
	if loaded:
		var shimmer=.5+.5*sin(highlight_clock*1.9)
		draw_rect(Rect2(2,2,3,size.y-4),Color("f5d78d",.65+.35*shimmer))
		draw_line(Vector2(8,4),Vector2(size.x-8,4),Color("ffe9b7",.15+.22*shimmer),1.0,true)
	if press_feedback>0:draw_rect(Rect2(Vector2(5,5),size-Vector2(10,10)),Color(accent,.62*press_feedback),false,1.5,true)
	# M3100: the color rail and miniature energy indicator identify each
	# ammunition type even on the small Android popover.
	var glint: float=.55+.45*sin(highlight_clock*2.2)
	draw_rect(Rect2(3,7,2.5,size.y-14),Color(accent,.80 if loaded else .36))
	draw_line(Vector2(8,size.y-4),Vector2(minf(size.x-8.0,82.0),size.y-4),Color(accent,.50 if loaded else .24),1.0,true)
	if loaded:
		var center: Vector2=Vector2(size.x-18,18)
		draw_circle(center,10.0,Color(accent,.10+.07*glint))
		draw_arc(center,6.8,-PI*.5,-PI*.5+TAU*.77,18,Color(accent,.7+.2*glint),1.5,true)
		draw_circle(center,2.1,Color(accent,.85))
	var icon=Rect2(10,9,66,66)
	draw_rect(icon.grow(2),Color("0a1118"))
	draw_rect(icon.grow(1),Color(accent,.78) if loaded else Color("b69a61"),false,1.0)
	draw_rect(icon,Color("0c2630"))
	if art!=null:draw_texture_rect(art,icon.grow(-3),false)
	var width=font.get_string_size(stock,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	_ink(font,stock,Vector2(icon.get_center().x-width*.5,size.y-7),12,Color("f2deb0"))
	_ink(font,title,Vector2(91,29),18,Color("fff0c8") if loaded else Color("d9dedc"))
	_ink(font,detail,Vector2(91,55),13,Color("bfced0"))
	if loaded:_ink(font,"GELADEN",Vector2(91,79),12,accent.lightened(.30))
