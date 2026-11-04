extends Control
## World chart on parchment: the three portal-linked regions, the corsair fortress and the
## scroll-only bonus seas. Tapping a node selects it; the menu shows the details below.
const CONTENT = preload("res://content.gd")
const SEA_MARKS = preload("res://sea_marks.gd")
signal picked(index: int)
const FORTRESS_NODE := 6
## Map index -> normalized position on the chart; 6 is the fortress inside 3-1.
const NODES := {0:Vector2(.24,.40),1:Vector2(.48,.18),2:Vector2(.72,.40),3:Vector2(.16,.72),4:Vector2(.42,.84),5:Vector2(.64,.68),6:Vector2(.86,.52)}
const INK := Color("3a2410")
var sim: RefCounted
var parchment: Texture2D
var font: Font = ThemeDB.fallback_font
var selected := 0
var press_at := Vector2(-1,-1)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true

func _process(_delta: float) -> void:
	if is_visible_in_tree():queue_redraw()

func node_point(index: int) -> Vector2:
	var inner=Rect2(size*Vector2(.06,.08),size*Vector2(.88,.84))
	return inner.position+NODES[index]*inner.size

func node_radius() -> float:
	return clampf(size.y*.085,20,38)

func node_at(point: Vector2) -> int:
	var best=-1
	var reach=node_radius()*1.5
	for index in NODES:
		var d=point.distance_to(node_point(index))
		if d<reach:reach=d;best=index
	return best

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at=event.position
		elif press_at.x>=0 and event.position.distance_to(press_at)<14:
			var index=node_at(event.position)
			press_at=Vector2(-1,-1)
			if index>=0:
				selected=index
				picked.emit(index)
		else:press_at=Vector2(-1,-1)
	elif event is InputEventMouseMotion and press_at.x>=0 and event.position.distance_to(press_at)>=14:
		press_at=Vector2(-1,-1)

func _draw() -> void:
	if sim==null or size.x<80:return
	var now=Time.get_ticks_msec()/1000.0
	if parchment!=null:draw_texture_rect(parchment,Rect2(Vector2.ZERO,size),false)
	else:draw_rect(Rect2(Vector2.ZERO,size),Color("d8c39a"))
	draw_rect(Rect2(Vector2.ZERO,size),Color(.05,.12,.16,.10))
	var r=node_radius()
	# Portal ring between the regions, then the dotted scroll routes to the bonus seas.
	var ring=[[0,1],[1,2],[2,0]]
	for pair in ring:
		var a=node_point(pair[0]);var b=node_point(pair[1])
		var bend=(a+b)*.5+(b-a).orthogonal().normalized()*r*.6
		_dashed_curve(a,bend,b,Color(INK,.75),2.2,11.0)
		_portal_glyph(_bezier(a,bend,b,.5),r*.42,now)
	for bonus in [3,4,5]:
		var from=node_point(bonus-CONTENT.REGION_COUNT)
		_dashed_curve(from,(from+node_point(bonus))*.5+Vector2(r*.5,0),node_point(bonus),Color("6b4a1c",.55),1.4,5.0)
	_dashed_curve(node_point(2),(node_point(2)+node_point(FORTRESS_NODE))*.5-Vector2(0,r*.4),node_point(FORTRESS_NODE),Color("7a1d10",.7),1.8,7.0)
	_compass(Vector2(size.x*.9,size.y*.18),r*1.1)
	for index in NODES:_node(index,r,now)
	var fs=maxi(10,roundi(r*.42))
	_ink_text(Vector2(size.x*.47,size.y*.965),"BONUSKARTEN · NUR MIT SCHRIFTROLLE",fs,Color("5a3a12"))

func _bezier(a: Vector2,c: Vector2,b: Vector2,t: float) -> Vector2:
	return a.lerp(c,t).lerp(c.lerp(b,t),t)

func _dashed_curve(a: Vector2,c: Vector2,b: Vector2,color: Color,width: float,dash: float) -> void:
	var steps=36
	var before=a
	var run=0.0
	for i in range(1,steps+1):
		var point=_bezier(a,c,b,float(i)/steps)
		var length=before.distance_to(point)
		if fmod(run,dash*2.0)<dash:draw_line(before,point,color,width,true)
		run+=length
		before=point

func _portal_glyph(center: Vector2,r: float,now: float) -> void:
	draw_circle(center,r*1.15,Color("f2e6c8",.85))
	for i in 3:
		var start=now*1.4+float(i)*TAU/3.0
		draw_arc(center,r*(.45+.22*i),start,start+PI*1.2,14,Color("2a7f92"),1.6,true)
	draw_arc(center,r*1.15,0,TAU,20,Color(INK,.8),1.2,true)

func _compass(center: Vector2,r: float) -> void:
	for i in 8:
		var a=float(i)*PI*.25-PI*.5
		var long=r if i%2==0 else r*.55
		var tip=center+Vector2.from_angle(a)*long
		var left=center+Vector2.from_angle(a-PI*.5)*r*.12
		var right=center+Vector2.from_angle(a+PI*.5)*r*.12
		draw_colored_polygon(PackedVector2Array([tip,left,center]),Color(INK,.85))
		draw_colored_polygon(PackedVector2Array([tip,center,right]),Color("b08a4c",.85))
	draw_arc(center,r*.42,0,TAU,24,Color(INK,.8),1.2,true)
	_ink_text(center-Vector2(0,r+6),"N",maxi(10,roundi(r*.4)),INK)

func _ink_text(center: Vector2,text: String,fs: int,color: Color,outline: Color=Color("f2e6c8",.75)) -> void:
	var w=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
	draw_string_outline(font,center-Vector2(w*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,4,outline)
	draw_string(font,center-Vector2(w*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,color)

func region_level(index: int) -> int:
	if index==FORTRESS_NODE:return int(CONTENT.MAPS[CONTENT.FORTRESS_MAP].level)
	return int(CONTENT.MAPS[index].level)

func _here(index: int) -> bool:
	if index==FORTRESS_NODE:return sim.map_id==CONTENT.FORTRESS_MAP and not sim.fortress_island().is_empty() and sim.player.pos.distance_to(sim.fortress_island().bounds.get_center())<700
	return sim.map_id==index

func _node(index: int,r: float,now: float) -> void:
	var center=node_point(index)
	var fortress=index==FORTRESS_NODE
	var bonus=not fortress and bool(CONTENT.MAPS[index].get("bonus",false))
	var locked=sim.level<region_level(index)
	var hostile=fortress or bool(CONTENT.MAPS[index].npc_hostile)
	var size_k=(.62 if bonus else (.7 if fortress else 1.0))
	var radius=r*size_k
	var tint: Color=Color("b9a06a") if fortress else CONTENT.MAPS[index].tint
	var land=Color(.55,.62,.42).lerp(Color(tint.r*.5,tint.g*.45,tint.b*.4),.35)
	if index==selected:
		draw_circle(center,radius*1.55,Color("ffd27a",.25+.1*sin(now*3.0)))
		draw_arc(center,radius*1.55,0,TAU,32,Color("8a5a10"),2.0,true)
	var blob=PackedVector2Array()
	for i in 14:
		var a=float(i)/14.0*TAU
		var wobble=1.0+.16*sin(a*3.0+index*1.7)+.08*sin(a*5.0+index)
		blob.append(center+Vector2(cos(a),sin(a)*.78)*radius*wobble)
	var shade=PackedVector2Array()
	for p in blob:shade.append(p+Vector2(2,3))
	draw_colored_polygon(shade,Color(0,0,0,.18))
	draw_colored_polygon(blob,Color(land,.9) if not locked else Color(.42,.38,.30,.85))
	var edge=blob.duplicate();edge.append(blob[0])
	draw_polyline(edge,Color("a02818") if hostile else Color("2f6b3a"),2.2,true)
	if fortress:
		for i in 3:
			var x=center.x+(float(i)-1.0)*radius*.42
			draw_rect(Rect2(x-radius*.14,center.y-radius*.55,radius*.28,radius*.7),Color(INK,.9))
			draw_rect(Rect2(x-radius*.18,center.y-radius*.65,radius*.36,radius*.14),Color(INK,.9))
		var tag="[%s]" % sim.tower_tag()
		_ink_text(center+Vector2(0,radius*.45),tag,maxi(9,roundi(r*.32)),Color("2f6b3a") if sim.tower_friendly() else Color("8a1a0c"))
	else:
		var code=str(CONTENT.MAPS[index].code)
		_ink_text(center+Vector2(0,radius*.22),code,maxi(10,roundi(radius*.62)),INK)
	var title="Korsarenfestung" if fortress else str(CONTENT.MAPS[index].name)
	var fs=maxi(10,roundi(r*.34))
	var below=radius+fs+4
	_ink_text(center+Vector2(0,below),str(title).to_upper(),fs,INK)
	if not _here(index):
		_ink_text(center+Vector2(0,below+fs+2),"AB LV. %d" % region_level(index),maxi(9,fs-2),Color("8a1a0c") if locked else Color("5a3a12"))
	if locked:
		draw_circle(center+Vector2(radius*.75,-radius*.55),radius*.32,Color("f2e6c8",.9))
		SEA_MARKS.padlock(self,center+Vector2(radius*.75,-radius*.52),radius*.42,Color("6b1a0c"))
	elif not fortress and index<sim.visited.size() and bool(sim.visited[index]) and not _here(index):
		SEA_MARKS.check(self,center+Vector2(radius*.8,-radius*.55),radius*.42,Color("2f6b3a"))
	if _here(index):
		var pulse=fmod(now*.9,1.0)
		draw_arc(center,radius*(1.1+pulse*.7),0,TAU,32,Color("1a6f86",1.0-pulse),2.4,true)
		var ship=center+Vector2(-radius*.95,-radius*.6)
		draw_colored_polygon(PackedVector2Array([ship+Vector2(-9,0),ship+Vector2(9,0),ship+Vector2(6,5),ship+Vector2(-6,5)]),Color(INK))
		draw_line(ship,ship-Vector2(0,13),Color(INK),1.6)
		draw_colored_polygon(PackedVector2Array([ship-Vector2(0,13),ship-Vector2(-8,4),ship-Vector2(0,3)]),Color("f2e6c8"))
		var label="DU BIST HIER"
		var lfs=maxi(10,roundi(r*.32))
		var w=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,lfs).x+14
		var plate=Rect2(center-Vector2(w*.5,radius+lfs+6),Vector2(w,lfs+6))
		draw_rect(plate,Color("1a6f86"))
		draw_rect(plate,Color("f2e6c8"),false,1.2)
		draw_string(font,plate.position+Vector2(7,lfs+1),label,HORIZONTAL_ALIGNMENT_LEFT,-1,lfs,Color("fff8e8"))
		var staff=sim.staff
		if staff.shows_badge():
			SEA_MARKS.staff_badge(self,center+Vector2(radius*.9,radius*.15),staff.badge(),staff.color(),font,maxi(9,roundi(r*.3)))
