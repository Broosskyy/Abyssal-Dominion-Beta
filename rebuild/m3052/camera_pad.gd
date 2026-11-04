extends Control
## Camera thumb stick. It never steers the ship; a single owning touch cannot be stolen by another finger.
var value:=Vector2.ZERO
var touch_id:=-1
var mouse_owned:=false
var last_touch_ms:=-10000
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_STOP
	tooltip_text="Kamera bewegen · dein Schiff folgt seinem gesetzten Kurs"
func release() -> void:
	value=Vector2.ZERO;touch_id=-1;mouse_owned=false;queue_redraw()
func _update_value(point: Vector2) -> void:
	value=((point-size*.5)/(minf(size.x,size.y)*.32)).limit_length(1.0)
	if value.length()<.12:value=Vector2.ZERO
	queue_redraw()
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch_ms=Time.get_ticks_msec()
		if event.pressed and touch_id<0:
			touch_id=event.index;_update_value(event.position)
		elif not event.pressed and event.index==touch_id:release()
		accept_event()
	elif event is InputEventScreenDrag:
		if event.index==touch_id:_update_value(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec()-last_touch_ms>350:
			mouse_owned=event.pressed
			if mouse_owned:_update_value(event.position)
			else:release()
		accept_event()
	elif event is InputEventMouseMotion and mouse_owned:
		_update_value(event.position);accept_event()
func _notification(what: int) -> void:
	if what==NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():release()
func _draw() -> void:
	var center=size*.5
	var radius=minf(size.x,size.y)*.5-3
	draw_circle(center+Vector2(0,3),radius+1,Color(0,0,0,.35))
	draw_circle(center,radius,Color(.02,.06,.08,.72))
	draw_circle(center,radius,Color("a9864f"),false,2.4,true)
	draw_circle(center,radius-5,Color("5c5038"),false,1,true)
	for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var tip=center+direction*(radius-10)
		var side=Vector2(-direction.y,direction.x)*3.5
		draw_colored_polygon(PackedVector2Array([tip,tip-direction*5+side,tip-direction*5-side]),Color("c4a467"))
	var knob=center+value*radius*.43
	var knob_radius=radius*.42
	draw_circle(knob+Vector2(0,2),knob_radius,Color(0,0,0,.4))
	draw_circle(knob,knob_radius,Color("183442"))
	draw_circle(knob,knob_radius,Color("80e3dc") if value!=Vector2.ZERO else Color("bd9b60"),false,2,true)
	var font=ThemeDB.fallback_font
	var label="KAMERA"
	var width=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
	draw_string_outline(font,center+Vector2(-width*.5,3),label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,3,Color("071018"))
	draw_string(font,center+Vector2(-width*.5,3),label,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("dec590"))
