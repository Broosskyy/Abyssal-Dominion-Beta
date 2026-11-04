extends ScrollContainer
## Menu scrolling for phones: a finger drag scrolls the list even when it starts on a button,
## the list keeps gliding after release, and the touched button is never fired by a drag.
const SKIN = preload("res://ui_skin.gd")
const SLOP := 12.0
const FRICTION := 4.5
const WHEEL_STEP := 70.0
var pressing := false
var dragging := false
var press_point := Vector2.ZERO
var press_scroll := 0.0
var samples: Array = []
var velocity := 0.0
var glide := 0.0
var pending := -1
var pending_frames := 0
var cancelling := false
var swallow_until := 0

func _ready() -> void:
	horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	# The built-in touch drag would fight this one; it never leaves its dead zone.
	scroll_deadzone=1<<20
	SKIN.scrollbar(get_v_scroll_bar())
	get_v_scroll_bar().changed.connect(_reapply_pending)

func max_scroll() -> int:
	var bar=get_v_scroll_bar()
	return maxi(0,roundi(bar.max_value-bar.page))

## Restores a position once the rebuilt content has been measured.
func restore(value: int) -> void:
	velocity=0.0
	pending=maxi(0,value)
	pending_frames=5
	scroll_vertical=pending

func gliding() -> bool:
	return absf(velocity)>30.0

func _process(delta: float) -> void:
	if pending>=0:
		scroll_vertical=pending
		pending_frames-=1
		if scroll_vertical==pending or pending_frames<=0:pending=-1
	if pressing or not gliding():
		if not pressing:velocity=0.0
		return
	glide+=velocity*delta
	var limit=max_scroll()
	scroll_vertical=clampi(roundi(glide),0,limit)
	velocity*=exp(-FRICTION*delta)
	if scroll_vertical<=0 or scroll_vertical>=limit:velocity=0.0

func _input(event: InputEvent) -> void:
	if cancelling or not is_visible_in_tree():return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		if event.pressed and get_global_rect().has_point(event.position):
			velocity=0.0
			var step=WHEEL_STEP*(event.factor if event.factor>0 else 1.0)
			scroll_vertical=clampi(scroll_vertical+roundi(step*(-1.0 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0)),0,max_scroll())
			get_viewport().set_input_as_handled()
		return
	var pointer=event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT)
	# Touch and its emulated mouse press arrive as two events in either order; both are swallowed
	# while the list glides, so a tap only stops it and never presses what slid underneath.
	if pointer and event.pressed and get_global_rect().has_point(event.position) and (gliding() or Time.get_ticks_msec()<swallow_until):
		swallow_until=maxi(swallow_until,Time.get_ticks_msec()+90)
		velocity=0.0
		get_viewport().set_input_as_handled()
	var emulated=event is InputEventMouse and event.device==InputEvent.DEVICE_ID_EMULATION
	if pointer and not emulated:
		if event.pressed:_press(event.position)
		else:_release()
	elif event is InputEventScreenDrag or (event is InputEventMouseMotion and not emulated):
		if _drag(event.position):get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		get_viewport().set_input_as_handled()

func _reapply_pending() -> void:
	if pending<0:return
	scroll_vertical=mini(pending,max_scroll())

func _press(point: Vector2) -> void:
	if pressing or not get_global_rect().has_point(point):return
	pending=-1
	var bar=get_v_scroll_bar()
	if bar.visible and bar.get_global_rect().grow(4).has_point(point):return
	pressing=true;dragging=false
	press_point=point;press_scroll=scroll_vertical
	velocity=0.0
	samples=[[Time.get_ticks_msec(),point.y]]

func _drag(point: Vector2) -> bool:
	if not pressing:return false
	if not dragging:
		if absf(point.y-press_point.y)<SLOP:return false
		dragging=true
		press_point.y+=SLOP*signf(point.y-press_point.y)
		_cancel_child_press.call_deferred()
	scroll_vertical=clampi(roundi(press_scroll-(point.y-press_point.y)),0,max_scroll())
	samples.append([Time.get_ticks_msec(),point.y])
	if samples.size()>6:samples.pop_front()
	return true

func _release() -> void:
	if not pressing:return
	pressing=false
	if dragging and samples.size()>=2:
		var first: Array=samples[0];var last: Array=samples[-1]
		var span=maxf(float(last[0]-first[0])/1000.0,.016)
		var recent=Time.get_ticks_msec()-int(last[0])<120
		velocity=clampf(-(float(last[1])-float(first[1]))/span,-4200.0,4200.0) if recent else 0.0
		glide=scroll_vertical
	dragging=false

## Moves the held pointer off every control, so the button under the finger releases without firing.
func _cancel_child_press() -> void:
	var away=InputEventMouseMotion.new()
	away.position=Vector2(-100000,-100000);away.global_position=away.position
	away.button_mask=MOUSE_BUTTON_MASK_LEFT
	cancelling=true
	get_viewport().push_input(away,true)
	cancelling=false
