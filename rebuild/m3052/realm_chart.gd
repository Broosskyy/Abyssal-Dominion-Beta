extends Control
## Touch-friendly 20-sea planning atlas. It visualizes actual future map
## borders, NOT teleports, fast-travel paths or live world authority.
const CATALOG = preload("res://realm_catalog.gd")
signal picked(realm_id: int)

const INK := Color("322920")
const SEA_PALETTE := [
	Color("4b9eaa"), Color("577f94"), Color("648eaa"), Color("426479"), Color("466d86")
]
const COMPASS := ["north","east","south","west"]
const POINTS := {
	"north":Vector2(0.0,-1.0),
	"east":Vector2(1.0,0.0),
	"south":Vector2(0.0,1.0),
	"west":Vector2(-1.0,0.0)
}
var sim: RefCounted
var selected: int=1
var edge_mode: String=CATALOG.DEFAULT_EDGE_MODE
var press_at := Vector2(-1.0,-1.0)
var font: Font=ThemeDB.fallback_font

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true

func _columns() -> int:
	return 2 if size.x<560.0 else 4

func node_point(realm_id: int) -> Vector2:
	if realm_id<1 or realm_id>CATALOG.REALMS.size():return Vector2(-1000,-1000)
	var cols: int=_columns()
	var index: int=realm_id-1
	var column: int=index%cols
	var row: int=int(index/cols)
	return Vector2((float(column)+0.5)*size.x/float(cols),86.0+float(row)*(106.0 if cols==2 else 116.0))

func node_at(point: Vector2) -> int:
	var best: int=-1
	var max_dist: float=45.0
	for realm_id in range(1,CATALOG.REALMS.size()+1):
		var d: float=point.distance_to(node_point(realm_id))
		if d<max_dist:
			best=realm_id
			max_dist=d
	return best

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at=event.position
		elif press_at.x>=0.0 and event.position.distance_to(press_at)<16.0:
			var chosen: int=node_at(event.position)
			press_at=Vector2(-1,-1)
			if chosen>0:
				selected=chosen
				picked.emit(chosen)
		else:press_at=Vector2(-1,-1)
	elif event is InputEventMouseMotion and press_at.x>=0.0 and event.position.distance_to(press_at)>=16.0:
		press_at=Vector2(-1,-1)

func _label(center: Vector2,value: String,size_px: int,color: Color) -> void:
	var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x
	var point: Vector2=center-Vector2(width*.5,0)
	draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,3,Color("eee4c9"))
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func _edge_mark(center: Vector2,edge: String,active: bool) -> void:
	var v: Vector2=Vector2(POINTS[edge])
	var point: Vector2=center+v*29.0
	if active:
		draw_circle(point,5.0,Color("f6d486"))
		var a: Vector2=point+v*4.0
		var back: Vector2=point-v*4.0
		var side: Vector2=Vector2(-v.y,v.x)
		draw_colored_polygon(PackedVector2Array([a,back+side*3.0,back-side*3.0]),INK)
	else:
		draw_circle(point,3.0,Color("3f4a47",.35))

func _draw() -> void:
	if size.x<100.0 or size.y<150.0:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("ded0af"))
	var cols: int=_columns()
	_label(Vector2(size.x*.5,28),"ABYSSAL DOMINION · NEUE SEEKARTEN",15,INK)
	_label(Vector2(size.x*.5,46),"KLASSISCHE KARTENRAND-ÜBERGÄNGE",11,INK)
	for realm_id in range(1,CATALOG.REALMS.size()+1):
		var data: Dictionary=CATALOG.realm(realm_id)
		var center: Vector2=node_point(realm_id)
		var zone: int=CATALOG.zone_id(realm_id)
		var locked: bool=sim!=null and int(sim.level)<int(data.level)
		var here: bool=sim!=null and CATALOG.realm_for_map(int(sim.map_id))==realm_id
		var chosen: bool=selected==realm_id
		var width: float=minf(132.0,size.x/float(cols)-12.0)
		var rect: Rect2=Rect2(center-Vector2(width*.5,42.0),Vector2(width,87.0))
		draw_rect(rect,Color("faf2d9") if not chosen else Color("fbe5b4"))
		draw_rect(Rect2(rect.position,Vector2(rect.size.x,3.0)),SEA_PALETTE[zone])
		draw_rect(Rect2(rect.position+Vector2(0,rect.size.y-2.0),Vector2(rect.size.x,2.0)),Color("af996e",.65))
		if here:
			draw_rect(rect.grow(2.0),Color("12798a",.4),false,2.0)
		elif chosen:
			draw_rect(rect.grow(1.0),Color("b47922",.75),false,2.0)
		var sea: Color=Color("7f8f91") if locked else SEA_PALETTE[zone]
		draw_circle(center-Vector2(0,9),21.0,sea)
		draw_circle(center+Vector2(1,-8),16.0,Color("d6c3a1",.42))
		_label(center-Vector2(0,2),"%02d" % realm_id,16,INK)
		var links: Dictionary=CATALOG.edge_links(realm_id,edge_mode)
		for edge: String in COMPASS:
			_edge_mark(center-Vector2(0,9),edge,links.has(edge))
		var name: String=str(data.name).to_upper()
		var max_chars: int=21 if cols==2 else 18
		if name.length()>max_chars:name=name.left(max_chars-1)+"…"
		_label(center+Vector2(0,30),name,10,INK)
		_label(center+Vector2(0,42),"%d RANDWECHSEL · LV %d%s" % [links.size(),int(data.level)," · HIER" if here else ""],9,Color("796449"))
	var footer: String="GEPLANTE WELT · 20 REVIERE · "
	footer+="HYBRID: 2–4 RANDSEITEN" if edge_mode=="hybrid" else "VERGLEICH: 1–2 RANDSEITEN"
	_label(Vector2(size.x*.5,size.y-15.0),footer,10,INK)
