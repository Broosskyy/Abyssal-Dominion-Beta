extends Control
## Animated cauldron stage: the painted harbor scene with a living swirl, and a throw sequence
## where flasks fly in, the brew flashes in the best rarity colour and the rewards rise out.
const RARITY_COLORS := [Color("d6e2e4"),Color("4fc3ff"),Color("c69bff"),Color("ffc04d")]
## Measured on kessel_scene.jpg (960 x 540).
const MOUTH := Vector2(320,205)
const MOUTH_RADII := Vector2(150,42)
const BOTTLES := [Vector2(698,330),Vector2(762,300),Vector2(836,330)]
const FOCUS := Vector2(400,250)
const FLY := 0.55
const FLASH := 0.5
const RISE := 0.75
var art: Texture2D
var flask: Texture2D
var font: Font = ThemeDB.fallback_font
## {"start": msec, "results": [{"icon": Texture2D, "rarity": int}]} owned by the map, so a rebuilt
## menu continues the same throw instead of restarting it.
var throw: Dictionary = {}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true

func _process(_delta: float) -> void:
	if is_visible_in_tree():queue_redraw()

func _source() -> Rect2:
	var image=art.get_size() if art!=null else Vector2(960,540)
	var aspect=size.x/maxf(size.y,1.0)
	var src=Vector2(image.x,image.x/aspect) if aspect>image.x/image.y else Vector2(image.y*aspect,image.y)
	var origin=Vector2(clampf(FOCUS.x-src.x*.5,0,image.x-src.x),clampf(FOCUS.y-src.y*.48,0,image.y-src.y))
	return Rect2(origin,src)

func _map(point: Vector2,source: Rect2) -> Vector2:
	return (point-source.position)*size/source.size

func elapsed() -> float:
	return (Time.get_ticks_msec()-int(throw.get("start",-100000)))/1000.0

func busy() -> bool:
	return not throw.is_empty() and elapsed()<FLY+FLASH+RISE+.4

func best_rarity() -> int:
	var best=0
	for entry: Dictionary in throw.get("results",[]):best=maxi(best,int(entry.get("rarity",0)))
	return best

func _draw() -> void:
	if size.x<40 or size.y<40:return
	var source=_source()
	if art!=null:draw_texture_rect_region(art,Rect2(Vector2.ZERO,size),source)
	var k=size.x/source.size.x
	var mouth=_map(MOUTH,source)
	var radii=MOUTH_RADII*k
	var now=Time.get_ticks_msec()/1000.0
	var t=elapsed() if not throw.is_empty() else 99.0
	var tint=RARITY_COLORS[clampi(best_rarity(),0,3)] if t<FLY+FLASH+RISE+1.5 else Color("3fe8cf")
	_swirl(mouth,radii,now,t,tint)
	_bubbles(mouth,radii,now,t)
	if t<FLY+.2:_flasks(source,mouth,t)
	if t>=FLY and t<FLY+FLASH+.3:_flash(mouth,radii,(t-FLY)/(FLASH+.3),tint)
	if t>=FLY+FLASH*.4:_rewards(mouth,t-FLY-FLASH*.4)
	draw_rect(Rect2(Vector2.ZERO,size),Color("c9a35e"),false,1.5)
	draw_rect(Rect2(Vector2.ONE*3,size-Vector2.ONE*6),Color(0,0,0,.5),false,1)

func _ellipse_points(center: Vector2,radii: Vector2,start: float,span: float,steps: int) -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in steps+1:
		var a=start+span*float(i)/steps
		points.append(center+Vector2(cos(a)*radii.x,sin(a)*radii.y))
	return points

func _swirl(mouth: Vector2,radii: Vector2,now: float,t: float,tint: Color) -> void:
	var boost=clampf(1.0-absf(t-FLY-.2)/1.2,0,1)
	var fill=_ellipse_points(mouth,radii*.94,0,TAU,40)
	draw_colored_polygon(fill,Color(tint,.10+.18*boost))
	for ring in 5:
		var scale=1.0-ring*.17
		var start=now*(1.1+ring*.35)*(1.0+boost*2.0)+ring*1.3
		draw_polyline(_ellipse_points(mouth,radii*scale*.92,start,PI*1.25,26),Color(tint.lightened(.3),.22+.1*boost),1.6+boost,true)
	draw_circle(mouth,radii.y*.35,Color(1,1,1,.10+.25*boost))

func _bubbles(mouth: Vector2,radii: Vector2,now: float,t: float) -> void:
	var rush=2.2 if t<FLY+FLASH+RISE else 1.0
	for i in 14:
		var seed=float(i)*1.618
		var phase=fmod(now*(.32+fmod(seed,.3))*rush+seed,1.0)
		var x=mouth.x+sin(seed*7.0)*radii.x*.7+sin(now*1.6+seed)*4.0
		var y=mouth.y-phase*radii.y*3.4
		var r=(1.4+fmod(seed*3.0,2.2))*(size.x/700.0+.4)
		draw_circle(Vector2(x,y),r,Color(.62,1,.95,(1.0-phase)*.55))

func _flasks(source: Rect2,mouth: Vector2,t: float) -> void:
	var count=mini(6,throw.get("results",[]).size())
	for i in count:
		var delay=float(i)*.06
		var p=clampf((t-delay)/(FLY-.1),0,1)
		if p<=0 or p>=1:continue
		var from=_map(BOTTLES[i%BOTTLES.size()],source)
		var top=(from+mouth)*.5-Vector2(0,size.y*.32)
		var a=from.lerp(top,p);var b=top.lerp(mouth,p)
		var point=a.lerp(b,p)
		var s=size.y*.11*(1.0-p*.45)
		if flask!=null:
			draw_set_transform(point,p*TAU*1.2,Vector2.ONE)
			draw_texture_rect(flask,Rect2(-Vector2(s,s)*.5,Vector2(s,s)),false)
			draw_set_transform(Vector2.ZERO)
		else:draw_circle(point,s*.3,Color("5fe0d2"))
		draw_circle(point+Vector2(0,s*.4),s*.18,Color(.6,1,.95,.35))

func _flash(mouth: Vector2,radii: Vector2,p: float,tint: Color) -> void:
	var fade=1.0-p
	draw_circle(mouth,radii.x*(.4+p*.7),Color(tint,.30*fade))
	draw_circle(mouth,radii.x*(.18+p*.25),Color(1,1,1,.55*fade))
	draw_polyline(_ellipse_points(mouth,radii*(1.0+p*1.6),0,TAU,40),Color(tint,fade),3.0*fade+1.0,true)
	for i in 10:
		var a=float(i)/10.0*TAU+p
		var inner=mouth+Vector2(cos(a)*radii.x*.5,sin(a)*radii.y*.5-radii.y)
		var outer=mouth+Vector2(cos(a)*radii.x*(1.0+p),sin(a)*radii.y*(1.0+p)-radii.y*(1.0+p*3.0))
		draw_line(inner,outer,Color(tint.lightened(.4),.7*fade),2.0,true)

## Rewards rise from the brew into a row along the top of the stage.
func _rewards(mouth: Vector2,t: float) -> void:
	var results: Array=throw.get("results",[])
	var shown=mini(results.size(),10)
	if shown==0:return
	var icon=clampf(size.y*.2,30,58)
	var gap=icon*1.12
	var row_y=icon*.5+10
	var first=size.x*.5-gap*(shown-1)*.5
	for i in shown:
		var entry: Dictionary=results[i]
		var p=clampf((t-float(i)*.05)/RISE,0,1)
		if p<=0:continue
		var e=1.0-pow(1.0-p,3.0)
		var goal=Vector2(first+gap*i,row_y)
		var point=mouth.lerp(goal,e)-Vector2(0,sin(e*PI)*size.y*.12)
		var scale=.45+.55*e
		var color: Color=RARITY_COLORS[clampi(int(entry.get("rarity",0)),0,3)]
		draw_circle(point,icon*.58*scale,Color(0,0,0,.55))
		draw_circle(point,icon*.56*scale,Color(color,.25+.15*sin(Time.get_ticks_msec()/180.0+i)))
		draw_arc(point,icon*.56*scale,0,TAU,24,color,1.6,true)
		var tex: Texture2D=entry.get("icon")
		if tex!=null:
			var s=icon*.82*scale
			draw_texture_rect(tex,Rect2(point-Vector2(s,s)*.5,Vector2(s,s)),false)
		if bool(entry.get("milestone",false)):draw_arc(point,icon*.68*scale,0,TAU,24,Color("ffe08a"),2.2,true)
	if results.size()>shown and t>RISE:
		var more="+%d" % (results.size()-shown)
		var fs=maxi(12,roundi(icon*.36))
		var x=first+gap*shown-icon*.3
		draw_string_outline(font,Vector2(x,row_y+fs*.36),more,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,Color(0,0,0,.85))
		draw_string(font,Vector2(x,row_y+fs*.36),more,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("fff0c8"))
