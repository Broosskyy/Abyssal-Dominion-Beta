extends "res://scripts/classic/m3045_original_world_pass.gd"
## M304.6: classic click-to-sail. Tap directly sets the route and full cruise.
## Heading follows the course instantly; no ship-turn or acceleration gate.
## The route planner still skirts coastal collision circles.

const CAMERA_DISTANCE := 59.0
const TAP_MOUSE_DEBOUNCE_MS := 180
const WAYPOINT_EPSILON := 0.80

var _last_native_touch_ms := -100000
var _last_course_point := Vector3.ZERO


func _ready() -> void:
	# Choose actual integrated SeaBattles sprite sheets when they have been
	# staged for private playtests. Never default to our placeholder meshes.
	# Offline source-only checkouts without those assets remain playable with
	# the original fallback rather than rendering blank sprites.
	if not get_tree().root.has_meta("m3035_graphic_mode"):
		var reference_pack := "res://assets/classic/private_seabattles/pack.json"
		var user_pack := "user://seabattles/pack.json"
		var has_reference := FileAccess.file_exists(reference_pack) or FileAccess.file_exists(user_pack)
		get_tree().root.set_meta("m3035_graphic_mode", "private_sprite" if has_reference else "original_fleet")
	super._ready()
	# ~18% closer than the former 72-unit default without hiding enemies.
	zoom = CAMERA_DISTANCE
	if camera != null:
		camera.size = CAMERA_DISTANCE
	_hud_header.text = "ABYSSAL DOMINION · M304.6"
	_build_label.text = "M304.6 · SOFORTKURS · REFERENZASSETS"
	hint = "Auf freie Seekarte tippen = sofort losfahren"
	_refresh()


func _course(point: Vector3) -> void:
	# Reuse existing obstacle avoidance, waypoint array, range checks and
	# on-screen status. Only change the motion response to an accepted tap.
	super._course(point)
	if ship == null or route.is_empty():
		return
	_last_course_point = point
	_set_immediate_heading(route[0])
	_sea_speed = SEA_MAX_SPEED
	if _wake_visual != null:
		_wake_visual.visible = true
		_wake_visual.scale.z = 1.0
	hint = "Kurs gesetzt · direkte Fahrt"
	_refresh()


func _set_immediate_heading(destination: Vector3) -> void:
	if ship == null:
		return
	var difference := destination - ship.position
	difference.y = 0.0
	if difference.length_squared() <= 0.001:
		return
	ship.rotation.y = atan2(-difference.x, -difference.z)
	var sheet := ship.get_node_or_null("ShipSprite")
	if sheet != null:
		if sheet.has_method("set_heading"):
			sheet.set_heading(ship.rotation.y)
		if sheet.has_method("set_moving"):
			sheet.set_moving(true)


func _sail(delta: float) -> void:
	if ship == null:
		return
	if route.is_empty():
		_sea_speed = 0.0
		if _wake_visual != null:
			_wake_visual.visible = false
		var idle_sprite := ship.get_node_or_null("ShipSprite")
		if idle_sprite != null and idle_sprite.has_method("set_moving"):
			idle_sprite.set_moving(false)
		return
	# Steering is a visual snap to travel direction rather than a precondition
	# for movement. The ship instantly travels along the clicked route segment.
	_sea_speed = SEA_MAX_SPEED
	var remaining := maxf(delta, 0.0) * _sea_speed
	var iterations := 0
	while remaining > 0.00001 and not route.is_empty() and iterations < 8:
		iterations += 1
		var gap := route[0] - ship.position
		gap.y = 0.0
		var distance := gap.length()
		if distance <= WAYPOINT_EPSILON:
			route.remove_at(0)
			if not route.is_empty():
				_set_immediate_heading(route[0])
			continue
		_set_immediate_heading(route[0])
		var direction := gap / distance
		var step := minf(remaining, distance)
		var next := ship.position + direction * step
		# Swept collision test also at low mobile frame rates.
		var obstructed := false
		for fraction in [0.25, 0.50, 0.75, 1.0]:
			if _blocked(ship.position.lerp(next, fraction)):
				obstructed = true
				break
		if obstructed:
			route.clear()
			_sea_speed = 0.0
			if _wake_visual != null:
				_wake_visual.visible = false
			hint = "Küste voraus · neuen Kurs antippen"
			_refresh()
			return
		ship.position = next
		remaining -= step
		if distance - step <= WAYPOINT_EPSILON:
			route.remove_at(0)
			if not route.is_empty():
				_set_immediate_heading(route[0])
	if route.is_empty():
		_sea_speed = 0.0
	var sprite := ship.get_node_or_null("ShipSprite")
	if sprite != null and sprite.has_method("set_moving"):
		sprite.set_moving(not route.is_empty())
	if _wake_visual != null:
		_wake_visual.visible = not route.is_empty()
		_wake_visual.scale.z = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_last_native_touch_ms = Time.get_ticks_msec()
			_world_click(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Mobile devices can emit both a native touch and emulated mouse
			# event. Never set a second identical course for the same touch.
			if Time.get_ticks_msec() - _last_native_touch_ms < TAP_MOUSE_DEBOUNCE_MS:
				return
	super._unhandled_input(event)


func _captain_pack_available() -> bool:
	# The original Captain of Sea APK has only been indexed, not decoded into
	# ready-to-use sprites in this repository. Show the option only after a
	# complete, privately provided PNG+pack.json test pack is actually present.
	return FileAccess.file_exists("res://assets/classic/private_captainofsea/pack.json") or FileAccess.file_exists("user://captainofsea/pack.json")


func _switch_graphics() -> void:
	# Keep legacy SeaBattles <-> Sea of Bones cycle untouched for old game tests.
	# If the user has a local Captain pack, insert it as the third reference.
	if _captain_pack_available():
		if _asset_mode == "seaofbones_sprite":
			_asset_mode = "captain_sprite"
			_apply_graphics_mode()
			return
		if _asset_mode == "captain_sprite":
			_asset_mode = "private_sprite"
			_apply_graphics_mode()
			return
	super._switch_graphics()


func _refresh() -> void:
	super._refresh()
	if _pack_button != null and _asset_mode == "captain_sprite":
		_pack_button.text = "GRAFIK: CAPTAIN OF SEA"
