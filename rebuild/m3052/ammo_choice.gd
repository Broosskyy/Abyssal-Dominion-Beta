extends Button
## A complete ammunition row is the touch target, as on a classic sea-chart client.
var art: Texture2D
var title:=""
var detail:=""
var stock:=""
var loaded:=false
func _ready() -> void:
	focus_mode=Control.FOCUS_NONE
	clip_contents=true
	clip_text=true
	for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:add_theme_color_override(state,Color.TRANSPARENT)
func _ink(font: Font,value: String,point: Vector2,fs: int,color: Color) -> void:
	if point.x>=70:
		var room=size.x-point.x-8
		if font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>room:
			while value.length()>1 and font.get_string_size(value+"…",HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>room:value=value.left(value.length()-1)
			value+="…"
	draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,2,Color("0a0e12"))
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
func _draw() -> void:
	var font=ThemeDB.fallback_font
	var hot=loaded or is_hovered()
	draw_rect(Rect2(Vector2.ZERO,size),Color("29302f") if hot else Color("192027"))
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("c5a66c") if loaded else Color("444a4b"),false,1.0)
	var icon=Rect2(8,8,50,50)
	draw_rect(icon.grow(1),Color("8a7048"),false,1.0)
	draw_rect(icon,Color("0c1218"))
	if art!=null:draw_texture_rect(art,icon.grow(-3),false)
	var width=font.get_string_size(stock,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
	_ink(font,stock,Vector2(icon.get_center().x-width*.5,size.y-6),11,Color("e8dfcb"))
	_ink(font,title,Vector2(70,22),15,Color("f2e8d3") if loaded else Color("d9dedc"))
	_ink(font,detail,Vector2(70,43),11,Color("adbabb"))
	if loaded:_ink(font,"AKTIV",Vector2(70,61),10,Color("e4c47e"))
