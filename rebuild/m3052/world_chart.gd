extends Control
## Forty persistent sea ids, shown as twenty paired rows. Bonus ids remain 3..5.
const CONTENT=preload("res://content.gd")
const FORTRESS_NODE := 1000
signal picked(index: int)
var sim: RefCounted
var parchment: Texture2D
var font: Font=ThemeDB.fallback_font
var selected := 0
var press_at := Vector2(-1,-1)
const NODES := {} # Retained API; actual node ids are the persistent sea catalog.
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	clip_contents=true
func node_radius() -> float:return 22.0
func node_point(index: int) -> Vector2:
	if index==FORTRESS_NODE:return Vector2(size.x*.5,1300)
	if index in [3,4,5]:return Vector2(size.x*(float(index-3)+.5)/3.0,1238)
	var order: int=CONTENT.SEA_MAP_IDS.find(index)
	return Vector2(size.x*(.26 if order%2==0 else .74),54+floori(float(order)/2.0)*58)
func node_at(point: Vector2) -> int:
	for index: int in CONTENT.SEA_MAP_IDS+[3,4,5,FORTRESS_NODE]:
		var center: Vector2=node_point(index)
		if Rect2(center-Vector2(size.x*.22,24),Vector2(size.x*.44,48)).has_point(point):return index
	return -1
func region_level(index: int) -> int:
	return int(CONTENT.MAPS[CONTENT.FORTRESS_MAP if index==FORTRESS_NODE else index].level)
func _here(index: int) -> bool:return sim!=null and sim.map_id==index
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:press_at=event.position
		else:
			if press_at.x>=0 and event.position.distance_to(press_at)<14:
				var index: int=node_at(event.position)
				if index>=0:selected=index;picked.emit(index)
			press_at=Vector2(-1,-1)
	elif event is InputEventMouseMotion and press_at.x>=0 and event.position.distance_to(press_at)>=14:press_at=Vector2(-1,-1)
func _draw() -> void:
	if sim==null or size.x<80:return
	if parchment!=null:draw_texture_rect(parchment,Rect2(Vector2.ZERO,size),false,Color(.5,.58,.63))
	else:draw_rect(Rect2(Vector2.ZERO,size),Color("102736"))
	for index: int in CONTENT.SEA_MAP_IDS:
		var center: Vector2=node_point(index)
		for neighbor: int in CONTENT.sea_neighbors(index):
			if neighbor>index:draw_line(center,node_point(neighbor),Color("9cbec9",.2),2,true)
	for index: int in CONTENT.SEA_MAP_IDS+[3,4,5,FORTRESS_NODE]:
		var center: Vector2=node_point(index)
		var rect:=Rect2(center-Vector2(size.x*.22,23),Vector2(size.x*.44,46))
		var locked: bool=sim.level<region_level(index)
		var here: bool=_here(index)
		draw_rect(rect,Color("163c48") if here else Color("0b202d"))
		draw_rect(rect,Color("e5bf72") if index==selected else Color("427281",.8),false,2 if index==selected else 1)
		var title: String="GILDENINSEL · 3/1" if index==FORTRESS_NODE else str(CONTENT.MAPS[index].code)
		var caption: String="HIER" if here else ("LV. %d" % region_level(index))
		var text: String=title+" · "+caption
		var fs: int=clampi(roundi(size.x/34),12,18)
		var width: float=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
		draw_string(font,center+Vector2(-width*.5,6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("98a5af") if locked else Color("ffe1a3"))
