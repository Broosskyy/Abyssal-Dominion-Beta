extends Control
## Native-pixel ship readouts. The world-to-screen projection is sampled once
## during the host's _process(), AFTER the camera scroll has been applied.
## This avoids render-callback one-frame lag at high zoom / while sailing.
const SEA_MARKS=preload("res://sea_marks.gd")
var host
func _font_size(base: int) -> int:
	return maxi(1,roundi(float(base)*float(host._plate_pixels())))

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
		var anchor=rect.position+Vector2(rect.size.x*.5,17.0*host._plate_pixels())
		# All glyphs, frames and deck fittings are painted at 1:1 physical pixels.
		_draw_plate(actor,anchor.round())

func _caption(point: Vector2,value: String,base_size: int,color: Color,outline: int=2) -> float:
	var ink: Font=host.font
	var fs=_font_size(base_size)
	var width=ink.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	var left=Vector2(roundf(point.x-width*.5),roundf(point.y))
	draw_string_outline(ink,left,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,maxi(1,roundi(outline*host._plate_pixels())),Color(.01,.035,.05,color.a))
	draw_string(ink,left,value,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)
	return width

func _gauge(original: Rect2,ratio: float,ink: Color,flash: float=0.0) -> void:
	var rect=Rect2(original.position.round(),Vector2(maxf(1.0,roundf(original.size.x)),maxf(1.0,roundf(original.size.y))))
	draw_rect(rect.grow(1.0+flash*.6),Color("030b12").lerp(ink,flash*.25))
	draw_rect(rect,Color("0a1620"))
	var fill=Rect2(rect.position,Vector2(rect.size.x*clampf(ratio,0.0,1.0),rect.size.y))
	if fill.size.x<=.05:return
	draw_rect(fill,ink.lightened(flash*.18))
	draw_line(fill.position+Vector2(0,1),Vector2(fill.end.x,fill.position.y+1),ink.lightened(.22+flash*.25),1,true)
	if flash>0.0:draw_rect(rect.grow(1.5),Color(ink,.16*flash),false,1.0,true)

func _rank(center: Vector2,tier: int,scale: float) -> void:
	var tint=Color("d5b77a")
	var dark=Color(0,0,0,.65)
	var k=.6*scale
	for side in [-1.0,1.0]:
		for feather in 3:
			var root=center+Vector2(side*6,-1+feather*2.6)*k
			var tip=center+Vector2(side*(21-feather*4.5),-5+feather*2.2)*k
			draw_line(root+Vector2(0,1.2)*k,tip+Vector2(0,1.2)*k,dark,(3.2-feather*.5)*k,true)
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
	if player:
		# Native-pixel overlay is the actual gameplay nameplate: match the
		# selected design in the Werft (not just the legacy map-draw hook).
		tint=sim.staff.color() if sim.staff.shows_badge() else (Color("d9f0e5") if int(actor.get("skin",0))==0 else host._ship_design_accent(int(actor.get("skin",0))).lightened(.17))
	elif hostile:tint=Color("eab8a7")
	elif monster:tint=Color("c6b9d6")
	# NPC names recede behind the captain's identity; the selected target
	# stays easier to follow when multiple ships cross the same sea lane.
	if not player:tint.a=0.87 if int(actor.id)==sim.target else 0.67
	# No draw_set_transform(...scale=1.45): subpixel GPU magnification
	# made texts and thin HP/shield rules flicker while the camera moved.
	var pixel_scale=float(host._plate_pixels())
	draw_set_transform(anchor,0,Vector2.ONE)
	var title: String=host._plate_title(actor)
	var width=_caption(Vector2.ZERO,title,host._plate_title_size(actor),tint)
	if not player and not tower and not monster:
		# Small category marker, separate from the name so long names are
		# not truncated further by an inline [NPC] prefix.
		_caption(Vector2(-width*.5-19.0*pixel_scale,0),"NPC",8,Color(.64,.78,.84,.59),1)
	if host._plate_has_rank(actor):
		var tier=clampi(floori((sim.level-1)/4.0)+1,1,5) if player else clampi(int(actor.get("pirate_rank",1)),1,5)
		_rank(Vector2(-width*.5-23*pixel_scale,-6*pixel_scale),tier,pixel_scale)
	var identity: String=host._plate_identity(actor)
	if not identity.is_empty():_caption(Vector2(0,13*pixel_scale),identity,8,Color(.72,.86,.88,.49),1)
	var bar_width=(132.0 if player else (96.0 if int(actor.id)==sim.target else 84.0))*pixel_scale
	var hit_age=sim.clock-float(actor.get("last_hit",-100.0))
	var flash=clampf(1.0-hit_age/.42,0.0,1.0)
	var hp_ratio=float(actor.hp)/maxf(1.0,float(actor.max_hp))
	if player:
		_gauge(Rect2(-bar_width*.5,24*pixel_scale,bar_width,7*pixel_scale),hp_ratio,Color("49df24"),flash)
	else:
		_gauge(Rect2(-bar_width*.5,12*pixel_scale,bar_width,5*pixel_scale),hp_ratio,Color("d97660") if hostile else Color("61b967"))
	var max_shield=float(actor.get("max_shield",0))
	if max_shield>0.0:
		var ratio=float(actor.get("shield",0))/max_shield
		if player:_gauge(Rect2(-bar_width*.5,35*pixel_scale,bar_width,5*pixel_scale),ratio,Color("409fdf"),flash)
		else:_gauge(Rect2(-bar_width*.5,22*pixel_scale,bar_width,3*pixel_scale),ratio,Color("4d95be"))
	if player:
		# Keep ten deck slots physically aligned under shield, regardless
		# of ship yaw or which Corsair material was chosen.
		SEA_MARKS.deck_badge(self,Vector2(0,65*pixel_scale),6.0*pixel_scale,sim,float(host.elapsed))
	if float(actor.get("slow",0.0))>0.0:draw_circle(Vector2(bar_width*.5+6*pixel_scale,14*pixel_scale),2.5*pixel_scale,Color("9fdbf4"))
	if player and sim.staff.hidden():_caption(Vector2(0,-20*pixel_scale),"GEIST" if sim.staff.presence=="ghost" else "ZUSCHAUER",10,sim.staff.color())
	draw_set_transform(Vector2.ZERO)
