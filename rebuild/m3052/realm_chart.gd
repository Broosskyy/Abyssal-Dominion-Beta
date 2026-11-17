extends Control
## Interactive planning atlas for the proposed M386 twenty-realm world.
## No travel, player coordinates, saves, guild ownership or networking is changed.
const CATALOG = preload("res://realm_catalog.gd")
signal picked(realm_id: int)
const INK := Color("33291f")
const PALETTE := [
	Color("72b6a0"),
	Color("d7b571"),
	Color("9abbd9"),
	Color("ba988b"),
	Color("8296b0")
]
var sim: RefCounted
var selected: int=1
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
	return Vector2((float(column)+0.5)*size.x/float(cols),72.0+float(row)*(83.0 if cols==2 else 108.0))

func node_at(point: Vector2) -> int:
	var best: int=-1
	var max_dist: float=35.0
	for realm_id in range(1,CATALOG.REALMS.size()+1):
		var d: float=point.distance_to(node_point(realm_id))
		if d<max_dist:
			best=realm_id
			max_dist=d
	return best

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at=event.position
		elif press_at.x>=0.0 and event.position.distance_to(press_at)<14.0:
			var chosen: int=node_at(event.position)
			press_at=Vector2(-1,-1)
			if chosen>0:
				selected=chosen
				picked.emit(chosen)
		else:press_at=Vector2(-1,-1)
	elif event is InputEventMouseMotion and press_at.x>=0.0 and event.position.distance_to(press_at)>=14.0:
		press_at=Vector2(-1,-1)

func _label(center: Vector2,value: String,size_px: int,color: Color) -> void:
	var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x
	var point: Vector2=center-Vector2(width*.5,0)
	draw_string_outline(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,3,Color("ede3c8"))
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func _draw() -> void:
	if size.x<100.0 or size.y<150.0:return
	draw_rect(Rect2(Vector2.ZERO,size),Color("d5c7a6"))
	var cols: int=_columns()
	# Every geographical zone contains exactly four independent seas.
	for zone in 5:
		var a: Vector2=node_point(zone*4+1)
		var b: Vector2=node_point(zone*4+4)
		var top: float=minf(a.y,b.y)-45.0
		var bottom: float=maxf(a.y,b.y)+50.0
		draw_rect(Rect2(8,top,size.x-16,bottom-top),Color(PALETTE[zone],.21))
		var title: String=str(CATALOG.ZONES[zone]).to_upper()
		_label(Vector2(size.x*.5,top+16),title,11,INK)
	# The prototype graph indicates navigable passages; it does not teleport.
	for realm_id in range(1,21):
		for target in CATALOG.neighbors(realm_id):
			if target<=realm_id:continue
			var mode: String=CATALOG.passage_type(realm_id,target)
			var ink: Color=Color("8b6635",.60) if mode=="region_gate" else Color("507b85",.49)
			if mode=="current":ink=Color("d09b49",.65)
			draw_line(node_point(realm_id),node_point(target),ink,3.0 if mode=="region_gate" else 1.8,true)
	var here: int=CATALOG.realm_for_map(int(sim.map_id)) if sim!=null else -1
	for realm_id in range(1,21):
		var data: Dictionary=CATALOG.realm(realm_id)
		var center: Vector2=node_point(realm_id)
		var zone: int=CATALOG.zone_id(realm_id)
		var locked: bool=sim!=null and int(sim.level)<int(data.level)
		draw_circle(center+Vector2(2,3),25.0,Color("26251d",.27))
		draw_circle(center,24.0,Color("857f70") if locked else PALETTE[zone])
		draw_arc(center,24.0,0,TAU,40,INK,1.7,true)
		if realm_id==selected:draw_arc(center,30.0,0,TAU,40,Color("b77812"),3.0,true)
		if realm_id==here:draw_arc(center,35.0,0,TAU,40,Color("087a80"),3.0,true)
		_label(center+Vector2(0,6),"%02d" % realm_id,16,INK)
		_label(center+Vector2(0,40),str(data.name).to_upper(),10,INK)
		if locked: _label(center+Vector2(19,-17),"L",10,Color("8e2e25"))
	_label(Vector2(size.x*.5,size.y-13),"WELTENTWURF · ANTIPPEN FÜR DETAILS",11,INK)
