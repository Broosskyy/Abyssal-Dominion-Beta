class_name IsometricCameraRig
extends Camera3D

var target: Node3D
# M190 legacy calibration token: var base_offset := Vector3(11.2, 19.5, -16.8)
# M213 master-reference framing: higher/wider oblique chart view.
var base_offset := Vector3(16.8, 29.0, -25.2)
var follow_sharpness := 6.0
var zoom_factor := 1.0
var pan_offset := Vector3.ZERO


func _ready() -> void:
	# M190 legacy calibration token retained for static history: fov = 38.0
	fov = 40.0
	near = 0.1
	far = 500.0
	if target != null:
		global_position = target.global_position + base_offset
		look_at(_look_target(), Vector3.UP)


func _process(delta: float) -> void:
	if target == null:
		return
	if target.get_meta("journal_open", false) or target.get_meta("inventory_open", false) or target.get_meta("command_open", false) or target.get_meta("settings_open", false) or target.get_meta("admin_panel_open", false) or target.get_meta("meta_panel_open", false) or target.get_meta("external_panel_open", false):
		return
	if Input.is_action_just_pressed("zoom_in"):
		zoom_factor = clamp(zoom_factor - 0.1, 0.82, 1.62)
	if Input.is_action_just_pressed("zoom_out"):
		zoom_factor = clamp(zoom_factor + 0.1, 0.82, 1.62)
	var desired := target.global_position + pan_offset + base_offset * zoom_factor
	var blend := 1.0 - exp(-follow_sharpness * delta)
	var settings := ClientSettings.current(get_tree())
	if settings != null and (settings.values.reduced_motion or not settings.values.camera_smoothing): blend = 1.0
	global_position = global_position.lerp(desired, blend)
	var desired_basis := Basis.looking_at(_look_target() - global_position, Vector3.UP)
	global_basis = global_basis.slerp(desired_basis, blend)


func apply_pinch_delta(distance_delta: float) -> void:
	var settings := ClientSettings.current(get_tree())
	var sensitivity := float(settings.values.camera_sensitivity) if settings != null else 1.0
	zoom_factor = clamp(zoom_factor - distance_delta * 0.0026 * sensitivity, 0.82, 1.62)

func pan_camera(direction: Vector2, delta: float) -> void:
	var settings := ClientSettings.current(get_tree())
	var sensitivity := float(settings.values.camera_sensitivity) if settings != null else 1.0
	var right := Vector3(global_basis.x.x, 0, global_basis.x.z).normalized()
	var down := Vector3(global_basis.z.x, 0, global_basis.z.z).normalized()
	pan_offset = (pan_offset + (right * direction.x + down * direction.y) * delta * 13.0 * sensitivity).limit_length(32.0)

func recenter() -> void:
	# M220: recenter returns to the ship without changing zoom or sailing intent.
	# Existing follow smoothing performs the visual glide unless reduced motion is active.
	pan_offset = Vector3.ZERO
	if target != null:
		target.set_meta("m220_camera_recentering_until", Time.get_ticks_msec() + 700)

func is_recentering() -> bool:
	return target != null and Time.get_ticks_msec() < int(target.get_meta("m220_camera_recentering_until",0))


func _look_target() -> Vector3:
	if target == null:
		return Vector3.ZERO
	return target.global_position + pan_offset + Vector3.UP * 1.2
