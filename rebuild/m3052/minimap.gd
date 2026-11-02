extends Control
var simulation: RefCounted
var camera_world := Vector2.ZERO
var view_world := Vector2(1600,900)
signal course_requested(point: Vector2)
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var inner = Rect2(Vector2(8,25), size-Vector2(16,35))
		if inner.has_point(event.position):
			course_requested.emit((event.position-inner.position)/inner.size*simulation.WORLD)
		accept_event()
func _draw() -> void:
	if simulation == null: return
	var r = Rect2(Vector2(8,25), size-Vector2(16,35))
	draw_rect(Rect2(Vector2.ZERO,size),Color("071a25"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("9a7845"),false,1.5)
	draw_string(ThemeDB.fallback_font,Vector2(10,17),"KARIBISCHE SEE · 1/1",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d7c092"))
	draw_rect(r,Color("123b4b"))
	for island in simulation.islands:
		var p: Vector2=r.position+island.pos/simulation.WORLD*r.size
		draw_circle(p,4.0,Color("7e9976"))
	for npc in simulation.npcs:
		if int(npc.hp)>0:
			var p: Vector2=r.position+npc.pos/simulation.WORLD*r.size
			draw_circle(p,2.2,Color("ed7867") if npc.kind=="ship" else Color("d29cdb"))
	var box = Rect2(r.position+(camera_world-view_world*0.5)/simulation.WORLD*r.size,view_world/simulation.WORLD*r.size)
	draw_rect(box,Color(0.65,0.88,0.85,0.6),false,1.0)
	var player: Vector2=r.position+simulation.player.pos/simulation.WORLD*r.size
	draw_circle(player,3.5,Color("6cf1e0"))
