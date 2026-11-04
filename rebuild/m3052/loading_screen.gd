extends Control
## Chart-loading curtain for boot and region changes; purely visual, input passes to the HUD.
const TIPS:=[
	"Tipp: Vollkugeln gegen Schiffe, Kettenkugeln bremsen, Harpunen treffen Seeungeheuer.",
	"Tipp: Im Hafen reparierst du günstig und verbesserst Kanonen, Harpunen, Rumpf und Segel.",
	"Tipp: Portale verbinden die Seegebiete. Nach einem Treffer wartet das Portal 6 Sekunden.",
	"Tipp: Beutekisten bringen Gold. Fahre einfach darüber, um sie zu bergen.",
	"Tipp: Mit dem Fernrohr unten wechselst du zwischen sichtbaren Zielen.",
	"Tipp: Gilden und gemeinsame Seekarten kommen mit dem Online-Server."]
var art: Texture2D
var wheel: Texture2D
var headline:="Seekarte wird geladen"
var region:=""
var tip:=""
var progress:=0.0
var fade:=1.0
var spin:=0.0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var font=ThemeDB.fallback_font
	var alpha=clampf(fade,0,1)
	draw_rect(Rect2(Vector2.ZERO,size),Color(.012,.02,.03,alpha))
	if art!=null:
		var cover=maxf(size.x/art.get_width(),size.y/art.get_height())
		var dims=art.get_size()*cover
		draw_texture_rect(art,Rect2((size-dims)*.5,dims),false,Color(1,1,1,alpha))
	var dark=Color(.01,.02,.035,.78*alpha);var clear=Color(.01,.02,.035,.12*alpha)
	draw_polygon(PackedVector2Array([Vector2(0,size.y*.45),Vector2(size.x,size.y*.45),size,Vector2(0,size.y)]),PackedColorArray([clear,clear,dark,dark]))
	draw_polygon(PackedVector2Array([Vector2.ZERO,Vector2(size.x,0),Vector2(size.x,size.y*.3),Vector2(0,size.y*.3)]),PackedColorArray([Color(dark,.55*alpha),Color(dark,.55*alpha),Color(clear,0),Color(clear,0)]))
	var k=clampf(size.y/720.0,.6,1.6)
	var gold=Color(Color("f1d18a"),alpha);var ink=Color(Color("071018"),alpha)
	_center(font,"ABYSSAL DOMINION",Vector2(size.x*.5,size.y*.17),roundi(44*k),gold,ink,6)
	_center(font,"SEESCHLACHTEN · GILDEN · ABENTEUER",Vector2(size.x*.5,size.y*.17+30*k),roundi(14*k),Color(Color("9fe6e0"),alpha*.9),ink,4)
	var bar_w=minf(size.x*.56,620*k);var bar_h=16*k
	var bar=Rect2(Vector2((size.x-bar_w)*.5,size.y*.8),Vector2(bar_w,bar_h))
	var label=headline+("  ·  "+region if not region.is_empty() else "")
	_center(font,label,Vector2(size.x*.5,bar.position.y-14*k),roundi(17*k),Color(Color("ffe7b8"),alpha),ink,4)
	if wheel!=null:
		var wheel_size=Vector2.ONE*38*k
		draw_set_transform(Vector2(bar.position.x-30*k,bar.position.y+bar_h*.5),spin,Vector2.ONE)
		draw_texture_rect(wheel,Rect2(-wheel_size*.5,wheel_size),false,Color(1,1,1,alpha))
		draw_set_transform(Vector2.ZERO)
	draw_rect(bar.grow(3*k),Color(Color("2a1d0e"),alpha))
	draw_rect(bar.grow(3*k),Color(Color("c9a35e"),alpha),false,1.5)
	draw_rect(bar,Color(Color("06121a"),alpha))
	var fill=Rect2(bar.position,Vector2(bar.size.x*clampf(progress,0,1),bar.size.y))
	var top=Color(Color("ffd98a"),alpha);var low=Color(Color("b4782c"),alpha)
	if fill.size.x>1:draw_polygon(PackedVector2Array([fill.position,Vector2(fill.end.x,fill.position.y),fill.end,Vector2(fill.position.x,fill.end.y)]),PackedColorArray([top,top,low,low]))
	_center(font,"%d %%" % roundi(clampf(progress,0,1)*100),Vector2(bar.end.x+34*k,bar.position.y+bar_h*.8),roundi(15*k),gold,ink,4)
	if not tip.is_empty():_center(font,tip,Vector2(size.x*.5,size.y-26*k),roundi(14*k),Color(Color("e8eef0"),alpha*.92),ink,4)
func _center(font: Font,text: String,baseline: Vector2,fontsize: int,color: Color,outline: Color,width: int) -> void:
	var w=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x
	draw_string_outline(font,Vector2(baseline.x-w*.5,baseline.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,width,outline)
	draw_string(font,Vector2(baseline.x-w*.5,baseline.y),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,color)
