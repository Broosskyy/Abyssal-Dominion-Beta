class_name M287ShipMotionVisualRig
extends Node3D
## Presentation-only ship motion identity. It never writes ShipMotor, navigation or world transforms.

const MOTION_STATES := ["ANCHORED", "IDLE", "ACCELERATING", "CRUISE", "TURNING", "BRAKING", "DRIFTING", "CORRECTING"]
const PROFILE_IDS := ["LIGHT", "BALANCED", "HEAVY", "ADMIRAL", "ABYSSAL"]
const SLOT_IDS := {
	"bow_displacement": "m287_vfx_bow_displacement_placeholder",
	"stern_wake": "m287_vfx_stern_wake_placeholder",
	"turn_curl": "m287_vfx_turn_curl_placeholder",
	"waterline": "m287_vfx_hull_waterline_placeholder",
	"anchor_ripple": "m287_vfx_anchor_ripple_placeholder",
	"sail_response": "m287_vfx_sail_flow_overlay_placeholder",
}

var _bow_nodes: Array[MeshInstance3D] = []
var _stern_nodes: Array[MeshInstance3D] = []
var _turn_nodes: Array[MeshInstance3D] = []
var _waterline: MeshInstance3D
var _anchor_ripple: MeshInstance3D
var _sail_cue: MeshInstance3D
var _motion_state := "IDLE"
var _profile_id := "BALANCED"
var _speed_ratio := 0.0
var _turn_ratio := 0.0
var _presentation_seed := 0
var _elapsed := 0.0
var _server_mode := false
var _qa_preview_mode := false
var _reduced_budget := false
var _motor: ShipMotor


func _ready() -> void:
	name = "M287ShipMotionVisualRig"
	add_to_group("m287_ship_motion_visual_rigs")
	set_meta("presentation_only", true)
	set_meta("replaceable_slot_ids", SLOT_IDS.duplicate(true))
	set_meta("final_art_status", "PLACEHOLDER")
	set_meta("ship_model_strategy", "SINGLE_COMPLETE_3D_MODEL")
	set_meta("overlay_does_not_require_modular_mesh", true)
	_motor = get_parent() as ShipMotor
	_reduced_budget = OS.has_feature("mobile") or OS.has_feature("web") or bool(get_tree().root.get_meta("touch_ui", false))
	_build_rig()
	call_deferred("_disable_legacy_wake_when_ready")


func _process(delta: float) -> void:
	_elapsed += delta
	if _qa_preview_mode and not _local_qa_allowed():
		_qa_preview_mode = false
		_motion_state = "IDLE"
		_speed_ratio = 0.0
		_turn_ratio = 0.0
	if not _server_mode and not _qa_preview_mode and _local_preview_allowed(): _sync_local_preview()
	_animate_presentation()


func apply_server_motion_state(state: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(state.get("source", "")) != "SERVER": return false
	var next_state := str(state.get("motion_state", "")).to_upper()
	var next_profile := str(state.get("motion_profile_id", "BALANCED")).to_upper()
	if next_state not in MOTION_STATES or next_profile not in PROFILE_IDS: return false
	_motion_state = next_state
	_profile_id = next_profile
	_speed_ratio = clampf(float(state.get("speed_ratio", 0.0)), 0.0, 1.25)
	_turn_ratio = clampf(float(state.get("turn_ratio", 0.0)), -1.0, 1.0)
	_presentation_seed = maxi(0, int(state.get("presentation_seed", 0)))
	_server_mode = true
	_qa_preview_mode = false
	return true


func play_server_motion_event(kind: String, event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(event.get("source", "")) != "SERVER": return false
	if kind.to_upper() not in ["ANCHOR_SETTLE", "ACCELERATION_START", "TURN_ENTER", "BRAKE_START", "DRIFT_ENTER", "CORRECTION_PRESENTATION"]: return false
	if not _server_mode:
		_speed_ratio = 0.0
		_turn_ratio = 0.0
	_server_mode = true
	_presentation_seed = maxi(0, int(event.get("presentation_seed", _presentation_seed)))
	_qa_preview_mode = false
	match kind.to_upper():
		"ANCHOR_SETTLE": _motion_state = "ANCHORED"
		"ACCELERATION_START": _motion_state = "ACCELERATING"
		"TURN_ENTER": _motion_state = "TURNING"
		"BRAKE_START": _motion_state = "BRAKING"
		"DRIFT_ENTER": _motion_state = "DRIFTING"
		"CORRECTION_PRESENTATION": _motion_state = "CORRECTING"
		_: return false
	return true


func release_server_mode_after_resync(server_verified: bool) -> bool:
	if not server_verified: return false
	_server_mode = false
	_qa_preview_mode = false
	_motion_state = "IDLE"
	_speed_ratio = 0.0
	_turn_ratio = 0.0
	return true


func apply_local_qa_preview(state: String, profile: String, speed_ratio: float, turn_ratio: float) -> bool:
	if not _local_qa_allowed() or _server_mode: return false
	var next_state := state.to_upper()
	var next_profile := profile.to_upper()
	if next_state not in MOTION_STATES or next_profile not in PROFILE_IDS: return false
	_motion_state = next_state
	_profile_id = next_profile
	_speed_ratio = clampf(speed_ratio, 0.0, 1.0)
	_turn_ratio = clampf(turn_ratio, -1.0, 1.0)
	_qa_preview_mode = true
	return true


func _local_qa_allowed() -> bool:
	return _local_preview_allowed() and bool(get_tree().root.get_meta("m299_animation_qa", false))


func _build_rig() -> void:
	var sockets := get_parent().get_node_or_null("Sockets") as Node3D
	if sockets == null:
		sockets = Node3D.new()
		sockets.name = "Sockets"
		get_parent().add_child(sockets)
	_build_bow_displacement(_ensure_socket(sockets, "MOTION_BowFoam", Vector3(0.0, -0.47, 2.55)))
	_build_stern_wake(_ensure_socket(sockets, "MOTION_SternWake", Vector3(0.0, -0.49, -2.5)))
	_build_turn_curls(_ensure_socket(sockets, "MOTION_TurnWake", Vector3(0.0, -0.5, -1.25)))
	_build_waterline(_ensure_socket(sockets, "MOTION_Waterline", Vector3(0.0, -0.46, 0.0)))
	_build_anchor_ripple(_ensure_socket(sockets, "MOTION_AnchorRipple", Vector3(0.0, -0.51, 0.0)))
	_build_sail_flow_overlay(_ensure_socket(sockets, "MOTION_Sails", Vector3(0.0, 2.0, 0.0)))


func _build_bow_displacement(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var foam := MeshInstance3D.new()
		foam.name = "BowDisplacementPlaceholder_%s" % ("Port" if side < 0.0 else "Starboard")
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(0.72, 1.55)
		foam.mesh = mesh
		foam.position = Vector3(side * 0.62, 0.0, -0.22)
		foam.rotation_degrees.y = side * 28.0
		foam.material_override = _foam_material(Color(0.72, 0.92, 0.96, 0.0))
		foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(foam)
		_bow_nodes.append(foam)


func _build_stern_wake(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var wake := MeshInstance3D.new()
		wake.name = "SternWakePlaceholder_%s" % ("Port" if side < 0.0 else "Starboard")
		var mesh := PlaneMesh.new()
		mesh.size = Vector2(0.58, 1.0)
		wake.mesh = mesh
		wake.position = Vector3(side * 0.72, 0.0, -0.5)
		wake.rotation_degrees.y = side * 7.0
		wake.material_override = _foam_material(Color(0.79, 0.95, 0.98, 0.0))
		wake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(wake)
		_stern_nodes.append(wake)


func _build_turn_curls(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var curl := MeshInstance3D.new()
		curl.name = "TurnCurlPlaceholder_%s" % ("Port" if side < 0.0 else "Starboard")
		var mesh := TorusMesh.new()
		mesh.inner_radius = 1.05
		mesh.outer_radius = 1.26
		mesh.rings = 18
		mesh.ring_segments = 5
		curl.mesh = mesh
		curl.position = Vector3(side * 1.25, 0.0, 0.0)
		curl.scale = Vector3(0.72, 0.12, 1.4)
		curl.material_override = _foam_material(Color(0.7, 0.91, 0.95, 0.0))
		curl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(curl)
		_turn_nodes.append(curl)


func _build_waterline(parent: Node3D) -> void:
	_waterline = MeshInstance3D.new()
	_waterline.name = "HullWaterlinePlaceholder"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 1.82
	mesh.outer_radius = 2.02
	mesh.rings = 24
	mesh.ring_segments = 5
	_waterline.mesh = mesh
	_waterline.scale = Vector3(1.0, 0.1, 2.3)
	_waterline.material_override = _foam_material(Color(0.66, 0.88, 0.92, 0.0))
	_waterline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_waterline)


func _build_anchor_ripple(parent: Node3D) -> void:
	_anchor_ripple = MeshInstance3D.new()
	_anchor_ripple.name = "AnchorRipplePlaceholder"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 2.2
	mesh.outer_radius = 2.32
	mesh.rings = 24
	mesh.ring_segments = 5
	_anchor_ripple.mesh = mesh
	_anchor_ripple.scale = Vector3(1.0, 0.08, 1.55)
	_anchor_ripple.material_override = _foam_material(Color(0.61, 0.84, 0.9, 0.0))
	_anchor_ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_anchor_ripple)


func _build_sail_flow_overlay(parent: Node3D) -> void:
	# A visual airflow cue beside the complete ship model. It does not require a
	# separately addressable sail mesh, bone, mast or modular ship component.
	_sail_cue = MeshInstance3D.new()
	_sail_cue.name = "SailFlowOverlayPlaceholder"
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.5, 0.24)
	_sail_cue.mesh = mesh
	_sail_cue.position = Vector3(0.0, 0.0, -0.08)
	_sail_cue.material_override = _foam_material(Color(0.68, 0.88, 0.92, 0.0))
	_sail_cue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_sail_cue)


func _animate_presentation() -> void:
	var settings := ClientSettings.current(get_tree())
	var motion_scale := 0.3 if settings != null and settings.values.reduced_motion else 1.0
	var profile := _profile_values(_profile_id)
	var speed := minf(_speed_ratio, 1.0)
	var pulse := 0.96 + sin(_elapsed * 4.4 * motion_scale + float(_presentation_seed % 13)) * 0.04
	var bow_alpha := speed * float(profile.bow) * 0.5 * pulse
	for node in _bow_nodes:
		node.visible = speed > 0.04
		node.scale = Vector3(0.65 + speed * 0.7, 1.0, 0.55 + speed * 0.9)
		_set_alpha(node, bow_alpha)
	var wake_length := 0.6 + speed * float(profile.wake) * 6.4
	for index in _stern_nodes.size():
		var node := _stern_nodes[index]
		node.visible = speed > 0.025
		node.scale = Vector3(0.75 + absf(_turn_ratio) * 0.3, 1.0, wake_length)
		node.position.z = -0.45 - wake_length * 0.5
		node.rotation_degrees.y = (-7.0 if index == 0 else 7.0) + _turn_ratio * (-10.0 if index == 0 else 10.0)
		_set_alpha(node, speed * float(profile.stern) * 0.46 * pulse)
	for index in _turn_nodes.size():
		var active_side := (_turn_ratio < -0.08 and index == 0) or (_turn_ratio > 0.08 and index == 1)
		_turn_nodes[index].visible = active_side and (not _reduced_budget or absf(_turn_ratio) > 0.34)
		_set_alpha(_turn_nodes[index], absf(_turn_ratio) * float(profile.turn) * 0.42 * pulse)
	if _waterline != null:
		_waterline.visible = _motion_state not in ["ANCHORED"] and (not _reduced_budget or speed > 0.15)
		_set_alpha(_waterline, (0.08 + speed * 0.18) * float(profile.displacement))
	if _anchor_ripple != null:
		_anchor_ripple.visible = _motion_state in ["ANCHORED", "IDLE"] and speed < 0.05
		var ripple := 0.9 + fposmod(_elapsed * 0.12 * motion_scale, 0.45)
		_anchor_ripple.scale = Vector3(ripple, 0.08, ripple * 1.55)
		_set_alpha(_anchor_ripple, (1.35 - ripple) * 0.24)
	if _sail_cue != null:
		var response := sin(_elapsed * 1.45 * motion_scale) * (1.0 + speed * 0.35) * float(profile.sail)
		_sail_cue.visible = speed > 0.08 and not _reduced_budget
		_sail_cue.rotation_degrees = Vector3(0.0, response * 2.0, _turn_ratio * 4.0 * motion_scale)
		_sail_cue.scale.x = 0.72 + speed * 0.48
		_set_alpha(_sail_cue, speed * 0.16)


func _sync_local_preview() -> void:
	if _motor == null: return
	_speed_ratio = clampf(absf(_motor.current_speed) / maxf(_motor.cruise_speed, 0.01), 0.0, 1.25)
	_turn_ratio = clampf(_motor.turn_input, -1.0, 1.0)
	if _speed_ratio < 0.025: _motion_state = "IDLE"
	elif absf(_turn_ratio) > 0.12: _motion_state = "TURNING"
	elif _speed_ratio < 0.72: _motion_state = "ACCELERATING"
	else: _motion_state = "CRUISE"
	_profile_id = str(get_parent().get_meta("motion_profile_id", "BALANCED")).to_upper()
	if _profile_id not in PROFILE_IDS: _profile_id = "BALANCED"


func _profile_values(profile_id: String) -> Dictionary:
	match profile_id:
		"LIGHT": return {"bow":0.82, "stern":0.88, "wake":0.82, "turn":1.08, "displacement":0.72, "sail":1.12}
		"HEAVY": return {"bow":1.18, "stern":1.2, "wake":1.15, "turn":0.82, "displacement":1.25, "sail":0.78}
		"ADMIRAL": return {"bow":1.25, "stern":1.28, "wake":1.22, "turn":0.92, "displacement":1.34, "sail":0.88}
		"ABYSSAL": return {"bow":0.94, "stern":1.08, "wake":1.06, "turn":1.0, "displacement":1.12, "sail":0.7}
		_: return {"bow":1.0, "stern":1.0, "wake":1.0, "turn":1.0, "displacement":1.0, "sail":1.0}


func _disable_legacy_wake_when_ready() -> void:
	var legacy := get_parent().get_node_or_null("WakeVFX") as Node3D
	if legacy != null: legacy.visible = false


func _ensure_socket(parent: Node3D, socket_name: String, local_position: Vector3) -> Marker3D:
	var existing := parent.get_node_or_null(socket_name) as Marker3D
	if existing != null: return existing
	var socket := Marker3D.new()
	socket.name = socket_name
	socket.position = local_position
	socket.set_meta("presentation_only", true)
	socket.set_meta("replaceable", true)
	parent.add_child(socket)
	return socket


func _foam_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = 0.45
	return material


func _set_alpha(node: MeshInstance3D, alpha: float) -> void:
	var material := node.material_override as StandardMaterial3D
	if material != null: material.albedo_color.a = clampf(alpha, 0.0, 0.62)


func _local_preview_allowed() -> bool:
	var root := get_tree().root
	return str(root.get_meta("environment_id", "LOCAL_DEVELOPMENT")) == "LOCAL_DEVELOPMENT" and not bool(root.get_meta("server_authority_verified", false))


func snapshot() -> Dictionary:
	return {"motion_state":_motion_state, "motion_profile_id":_profile_id, "speed_ratio":_speed_ratio, "turn_ratio":_turn_ratio, "server_mode":_server_mode, "qa_preview_mode":_qa_preview_mode, "placeholder":true, "slot_ids":SLOT_IDS.duplicate(true), "reduced_budget":_reduced_budget}


func can_set_destination() -> bool: return false
func can_change_speed() -> bool: return false
func can_change_heading() -> bool: return false
func can_rotate_ship_transform() -> bool: return false
func can_require_modular_ship_mesh() -> bool: return false
func can_detach_or_replace_ship_parts() -> bool: return false
func can_decide_collision_or_route() -> bool: return false
func can_promote_visual_motion_to_authority() -> bool: return false
