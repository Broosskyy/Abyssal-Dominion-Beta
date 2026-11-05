extends Control
## A dedicated, unscaled screen canvas for ship labels and deck assembly.
## Godot's Camera2D drives only the world-to-screen anchor, never the glyphs.
const SEA_MARKS=preload("res://sea_marks.gd")
var host
func _draw() -> void:
	if host==null or not is_instance_valid(host):return
	if host.gallery_page>=0:return
	var fleet: Array[Dictionary]=host.plate_fleet
	var rects: Dictionary=host.plate_rects
	var ordered=fleet.duplicate()
	ordered.sort_custom(func(a,b):
		return (2 if int(a.id)==0 else (1 if int(a.id)==host.sim.target else 0))<(2 if int(b.id)==0 else (1 if int(b.id)==host.sim.target else 0))
	)
	for actor: Dictionary in ordered:
		var id=int(actor.id)
		if not rects.has(id) or int(actor.hp)<=0:continue
		var rect: Rect2=rects[id]
		var center=rect.position+Vector2(rect.size.x*.5,17.0*host._plate_pixels())
		# Pixel snapping prevents fractional camera movement from resampling fonts.
		_draw_plate(actor,center.round())

func _caption(point: Vector2,value: String,fs: int,color: Color,outline: int=2) -> float:
	var ink: Font=host.font
	var text_width=ink.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var left=point-Vector2(text_width*.5,0)
	draw_string_outline(ink,left,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,outline,Color(.01,.035,.05,color.a))
	draw_string(ink,left,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
	return text_width

func _gauge(rect: Rect2,ratio: float,ink: Color,flash: float=0.0) -> void:
	draw_rect(rect.grow(1.0+flash*.6),Color("030b12").lerp(ink,flash*.25))
	draw_rect(rect,Color("0a1620"))
	var fill=Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0.0,1.0),rect.size.y))
	if fill.size.x<=.05:return
	draw_rect(fill,ink.lightened(flash*.18))
	draw_line(fill.position+Vector2(0,1),Vector2(fill.end.x,fill.position.y+1),ink.lightened(.22+flash*.25),1,true)
	if flash>0.0:draw_rect(rect.grow(1.5),Color(ink,.16*flash),false,1.0,true)

func _rank(center: Vector2,tier: int) -> void:
	var tint=Color("d5b77a")
	var dark=Color(0,0,0,.65)
	var k=.6
	for side in [-1.0,1.0]:
		for feather in 3:
			var root=center+Vector2(side*6,-1+feather*2.6)*k
			var tip=center+Vector2(side*(21-feather*4.5),-5+feather*2.2)*k
			draw_line(root+Vector2(0,1.2),tip+Vector2(0,1.2),dark,(3.2-feather*.5)*k,true)
			draw_line(root,tip,Color(tint,1.0-feather*.22),(2.4-feather*.45)*k,true)
	for chevron in tier:
		var y=-3.5+chevron*3.2
		var arm=PackedVector2Array([center+Vector2(-4.5,y-2.5)*k,center+Vector2(0,y+.8)*k,center+Vector2(4.5,y-2.5)*k])
		draw_polyline(arm,dark,3.0*k,true)
		draw_polyline(arm,tint.lightened(.35),1.6*k,true)
	draw_circle(center+Vector2(0,-6.5)*k,2.0*k,tint.lightened(.5))

func _draw_plate(actor: Dictionary,anchor: Vector2) -> void:
	var sim=host.sim
	var player=int(actor.id)==0
	var tower=str(actor.get("kind",""))=="tower"
	var monster=str(actor.get("kind",""))=="monster"
	var elite=bool(actor.get("elite",false))
	var hostile=not player and (bool(actor.get("aggressive",false)) or bool(host.CONTENT.MAPS[sim.map_id].npc_hostile) or (tower and not sim.tower_friendly()))
	var tint=Color("e8d0a1") if elite else Color("dce8e4")
	if player:tint=sim.staff.color() if sim.staff.shows_badge() else Color("d9f0e5")
	elif hostile:tint=Color("eab8a7")
	elif monster:tint=Color("c6b9d6")
	# Only one scale. Screen labels do not grow again inside _caption().
	var scale=float(host._plate_pixels())
	draw_set_transform(anchor,0,Vector2.ONE*scale)
	var title: String=host._plate_title(actor)
	var fs=16 if player else 14
	var text_width=_caption(Vector2.ZERO,title,fs,tint)
	if host._plate_has_rank(actor):
		var tier=clampi(floori((sim.level-1)/4.0)+1,1,5) if player else clampi(int(actor.get("pirate_rank",1)),1,5)
		_rank(Vector2(-text_width*.5-22,-6),tier)
	var label_id: String=host._plate_identity(actor)
	if not label_id.is_empty():_caption(Vector2(0,13),label_id,8,Color(.72,.86,.88,.49),1)
	var width=132.0 if player else (96.0 if int(actor.id)==sim.target else 84.0)
	var hit_age=sim.clock-float(actor.get("last_hit",-100.0))
	var flash=clampf(1.0-hit_age/.42,0.0,1.0)
	var hp_ratio=float(actor.hp)/maxf(1.0,float(actor.max_hp))
	if player:
		_gauge(Rect2(-width*.5,24,width,7),hp_ratio,Color("49df24"),flash)
	else:
		_gauge(Rect2(-width*.5,12,width,5),hp_ratio,Color("d97660") if hostile else Color("61b967"))
	var max_shield=float(actor.get("max_shield",0))
	if max_shield>0.0:
		var ratio=float(actor.get("shield",0))/max_shield
		if player:_gauge(Rect2(-width*.5,35,width,5),ratio,Color("409fdf"),flash)
		else:_gauge(Rect2(-width*.5,22,width,3),ratio,Color("4d95be"))
	if player:SEA_MARKS.deck_badge(self,Vector2(0,65),6,sim,float(host.elapsed))
	if float(actor.get("slow",0.0))>0.0:draw_circle(Vector2(width*.5+6,14),2.5,Color("9fdbf4"))
	if player and sim.staff.hidden():_caption(Vector2(0,-20),"GEIST" if sim.staff.presence=="ghost" else "ZUSCHAUER",10,sim.staff.color())
	draw_set_transform(Vector2.ZERO)
