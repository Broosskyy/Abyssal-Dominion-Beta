extends Control
## Illustrated parchment atlas: ten connected seas per leaf, forty persistent sea ids.
const CONTENT = preload("res://content.gd")
const SEA_MARKS = preload("res://sea_marks.gd")
signal picked(index: int)
const FORTRESS_NODE := 1000
const NODES := [Vector2(.14,.25),Vector2(.28,.13),Vector2(.48,.17),Vector2(.70,.13),Vector2(.87,.27),Vector2(.16,.49),Vector2(.34,.40),Vector2(.53,.47),Vector2(.72,.42),Vector2(.87,.55)]
var chapter := 0
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
	if chapter==-1:
		var order: int=CONTENT.SEA_MAP_IDS.find(index)
		if order<0:return Vector2(-1000,-1000)
		return Vector2(size.x*(.24 if order%2==0 else .76),76.0+float(order/2)*55.0)
	var inner=Rect2(size*Vector2(.06,.08),size*Vector2(.88,.84))
	var position: Vector2
	if index==FORTRESS_NODE:position=Vector2(.80,.82)
	elif index in [3,4,5]:position=Vector2(.14+float(index-3)*.21,.80)
	else:
		var order: int=CONTENT.SEA_MAP_IDS.find(index)-chapter*10
		if order<0 or order>=10:return Vector2(-1000,-1000)
		# First five positions are lane 1; the lower coast is lane 2.
		position=NODES[order/2+(5 if order%2 else 0)]
	return inner.position+position*inner.size

func visible_nodes() -> Array:
	if chapter==-1:return CONTENT.SEA_MAP_IDS.duplicate()
	var nodes: Array=CONTENT.SEA_MAP_IDS.slice(chapter*10,(chapter+1)*10)
	nodes.append_array([3,4,5,FORTRESS_NODE])
	return nodes

func node_radius() -> float:
	if chapter==-1:return clampf(size.x*.045,19.0,28.0)
	return clampf(minf(size.x*.047,size.y*.071),18,34)

func node_at(point: Vector2) -> int:
	var best=-1
	var reach=node_radius()*1.5
	for index: int in visible_nodes():
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
	if chapter==-1:
		_draw_overview(now)
		return
	var r=node_radius()
	var nodes: Array=visible_nodes()
	for index: int in CONTENT.SEA_MAP_IDS.slice(chapter*10,(chapter+1)*10):
		for neighbor: int in CONTENT.sea_neighbors(index):
			if neighbor<=index or neighbor not in nodes:continue
			var a=node_point(index);var b=node_point(neighbor)
			var bend=(a+b)*.5+(b-a).orthogonal().normalized()*r*.5
			_dashed_curve(a,bend,b,Color(INK,.6),1.7,9.0)
			_portal_glyph(_bezier(a,bend,b,.5),r*.27,now)
	for bonus in [3,4,5]:
		var from=node_point(CONTENT.sea_index(chapter*5+bonus-2,2))
		_dashed_curve(from,(from+node_point(bonus))*.5+Vector2(r*.5,0),node_point(bonus),Color("6b4a1c",.55),1.4,5.0)
	_compass(Vector2(size.x*.95,size.y*.09),r*.7)
	for index: int in nodes:_node(index,r,now)
	var fs=maxi(10,roundi(r*.42))
	_ink_text(Vector2(size.x*.5,size.y*.065),"SEEKARTEN %d–%d · PORTALROUTEN" % [chapter*5+1,chapter*5+5],fs+2,INK)
	_ink_text(Vector2(size.x*.36,size.y*.965),"BONUSKARTEN · NUR MIT SCHRIFTROLLE",fs,Color("5a3a12"))

# Every one of the forty seas is present on one scrollable atlas.
# The former four five-tier leaves remain available as close-up detail views.
func _draw_overview(now: float) -> void:
	var r: float=node_radius()
	_ink_text(Vector2(size.x*.5,29),"WELTKARTE · ALLE 40 SEEKARTEN",maxi(17,roundi(size.x*.028)),INK)
	_ink_text(Vector2(size.x*.24,51),"SPUR 1",13,Color("503419"))
	_ink_text(Vector2(size.x*.76,51),"SPUR 2",13,Color("503419"))
	for tier in 20:
		var left: int=CONTENT.sea_index(tier+1,1)
		var right: int=CONTENT.sea_index(tier+1,2)
		var a: Vector2=node_point(left)
		var b: Vector2=node_point(right)
		draw_line(a+Vector2(r,0),b-Vector2(r,0),Color(INK,.34),2.0,true)
		if tier<19:
			for index in [left,right]:
				var from: Vector2=node_point(index)
				var to: Vector2=node_point(CONTENT.sea_index(tier+2,int(CONTENT.MAPS[index].lane)))
				draw_line(from+Vector2(0,r),to-Vector2(0,r),Color(INK,.29),1.6,true)
	for index: int in CONTENT.SEA_MAP_IDS:
		_overview_node(index,r,now)
	_ink_text(Vector2(size.x*.5,size.y-17),"ANTIPPEN: KARTE AUSWÄHLEN · RUNTERSCROLLEN BIS 20/2",12,INK)

func _overview_node(index: int,r: float,now: float) -> void:
	var p: Vector2=node_point(index)
	var info: Dictionary=CONTENT.MAPS[index]
	var chosen: bool=index==selected
	var current: bool=index==sim.map_id
	var locked: bool=sim.level<int(info.level)
	var guild: bool=CONTENT.has_guild_island(index)
	var fill: Color=Color("d9b879") if not locked else Color("978a75")
	if current:fill=Color("91ceca")
	if chosen:
		draw_circle(p,r+8.0,Color("ffc45d",.22+.08*sin(now*3.0)))
		draw_arc(p,r+7.0,0,TAU,32,Color("7c470c"),2.0,true)
	draw_circle(p+Vector2(1.4,2.5),r+2.0,Color(INK,.18))
	draw_circle(p,r+2.0,Color("6a4a21"))
	draw_circle(p,r,fill)
	_ink_text(p+Vector2(0,4),str(info.code),maxi(12,roundi(r*.68)),INK)
	if guild:
		var holding: Dictionary=sim.guild_holdings.get(str(index),{})
		var owned: bool=not sim.guild.is_empty() and float(holding.get("remaining",0))>0.0
		var tag: String=str(sim.guild.get("tag","")) if owned else CONTENT.FORTRESS_TAG
		_ink_text(p+Vector2(0,-r-8),"GILDE [%s]" % tag,10,Color("236341") if owned else Color("842c1f"))
	if locked:SEA_MARKS.padlock(self,p+Vector2(r*.8,-r*.65),r*.45,Color("773b27"))
	elif current:
		draw_arc(p,r+4.0,0,TAU,24,Color("087888",.8),2.2,true)

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
	var title="10 GILDENTÜRME" if fortress else (str(CONTENT.MAPS[index].name) if bonus else "LV. %d" % region_level(index))
	var fs=maxi(10,roundi(r*.34))
	var below=radius+fs+4
	_ink_text(center+Vector2(0,below),str(title).to_upper(),fs,INK)
	if not _here(index) and (bonus or fortress):
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
