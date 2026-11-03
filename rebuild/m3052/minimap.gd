extends Control
const CONTENT=preload("res://content.gd")
var simulation: RefCounted
var camera_world:=Vector2.ZERO
var view_world:=Vector2(1600,900)
signal course_requested(point: Vector2)
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_STOP
func chart_rect() -> Rect2:return Rect2(Vector2(10,25),size-Vector2(20,44))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var inner=chart_rect()
		if inner.has_point(event.position):course_requested.emit((event.position-inner.position)/inner.size*simulation.WORLD)
		accept_event()
func _draw() -> void:
	if simulation==null:return
	var gold=Color("ad8950")
	draw_rect(Rect2(Vector2.ZERO,size),Color("081721"))
	for inset in [1.0,4.0]:draw_rect(Rect2(Vector2.ONE*inset,size-Vector2.ONE*inset*2),gold,false,1)
	for point in [Vector2(4,4),Vector2(size.x-4,4),Vector2(4,size.y-4),size-Vector2(4,4)]:
		draw_circle(point,4,Color("4b3820"));draw_circle(point,3,gold,false,1,true)
	var font=ThemeDB.fallback_font
	var region: Dictionary=CONTENT.MAPS[simulation.map_id]
	draw_string(font,Vector2(10,17),"%s · X %d  Y %d" % [region.code,roundi(simulation.player.pos.x/48),roundi(simulation.player.pos.y/48)],HORIZONTAL_ALIGNMENT_LEFT,size.x-16,9,Color("e7ce98"))
	var r=chart_rect();draw_rect(r,Color("102e3d"))
	for x in range(1,5):draw_line(r.position+Vector2(r.size.x*x/5,0),r.position+Vector2(r.size.x*x/5,r.size.y),Color(0.4,.6,.65,.12),1)
	for y in range(1,4):draw_line(r.position+Vector2(0,r.size.y*y/4),r.position+Vector2(r.size.x,r.size.y*y/4),Color(0.4,.6,.65,.12),1)
	for island in simulation.islands:
		var shape=PackedVector2Array()
		for vertex: Vector2 in island.outline:shape.append(r.position+vertex/simulation.WORLD*r.size)
		draw_colored_polygon(shape,Color("7e9976"))
	for npc in simulation.npcs:
		if int(npc.hp)<=0:continue
		var p: Vector2=r.position+npc.pos/simulation.WORLD*r.size
		var hostile=bool(npc.aggressive) or bool(region.npc_hostile)
		var color=Color("ed7867") if hostile else (Color("baa165") if npc.kind=="ship" else Color("c4a0d7"))
		draw_circle(p,2.0,color)
		if int(npc.id)==int(simulation.target):draw_circle(p,3.5,Color("f4d992"),false,1,true)
	for portal in simulation.portals:
		var p: Vector2=r.position+portal.pos/simulation.WORLD*r.size
		draw_rect(Rect2(p-Vector2(2,3),Vector2(4,6)),Color("a79edb"))
	var port: Vector2=r.position+simulation.harbor/simulation.WORLD*r.size
	draw_circle(port,2.5,Color("f4c56c"))
	var box=Rect2(r.position+(camera_world-view_world*.5)/simulation.WORLD*r.size,view_world/simulation.WORLD*r.size)
	draw_rect(box.intersection(r),Color(.65,.88,.85,.6),false,1)
	var player: Vector2=r.position+simulation.player.pos/simulation.WORLD*r.size
	var heading: Vector2=simulation.player.heading
	var triangle=PackedVector2Array([player+heading*4,player-heading*3+Vector2(-heading.y,heading.x)*3,player-heading*3-Vector2(-heading.y,heading.x)*3])
	draw_colored_polygon(triangle,Color("9cfff0"))
	draw_string(font,Vector2(10,size.y-7),str(region.name),HORIZONTAL_ALIGNMENT_LEFT,size.x-20,9,Color("d7c092"))
