class_name M285ShipDamageVisualRig
extends Node3D
## Replaceable M285 placeholder VFX rig. It visualizes state and never computes combat outcomes.

const DAMAGE_STATES := ["INTACT", "LIGHT", "MODERATE", "HEAVY", "CRITICAL", "DEFEATED"]
const SLOT_IDS := {
	"shield": "m285_vfx_ship_shield_placeholder",
	"hull": "m285_vfx_ship_hull_damage_placeholder",
	"fire": "m285_vfx_ship_fire_placeholder",
	"smoke": "m285_vfx_ship_smoke_placeholder",
	"critical": "m285_vfx_ship_critical_placeholder",
	"sinking": "m285_vfx_ship_sinking_placeholder",
}

var _health: ShipHealth
var _last_hull_ratio := 1.0
var _last_shield_ratio := 0.0
var _damage_state := "INTACT"
var _shield_shell: MeshInstance3D
var _shield_material: StandardMaterial3D
var _damage_marks: Array[MeshInstance3D] = []
var _fire_nodes: Array[MeshInstance3D] = []
var _smoke_nodes: Array[MeshInstance3D] = []
var _critical_ring: MeshInstance3D
var _sinking_debris: Node3D
var _shield_flash_left := 0.0
var _hull_flash_left := 0.0
var _elapsed := 0.0
var _reduced_budget := false
var _qa_preview_flash := false
var _server_presentation_mode := false


func _ready() -> void:
	add_to_group("m285_ship_damage_visual_rigs")
	_build_replaceable_placeholder_rig()
	_reduced_budget = OS.has_feature("mobile") or OS.has_feature("web") or bool(get_tree().root.get_meta("touch_ui", false))
	call_deferred("_bind_health_for_local_preview")


func _process(delta: float) -> void:
	_elapsed += delta
	if _qa_preview_flash and not _local_qa_allowed():
		_qa_preview_flash = false
		_shield_flash_left = 0.0
		_hull_flash_left = 0.0
	_shield_flash_left = maxf(0.0, _shield_flash_left - delta)
	_hull_flash_left = maxf(0.0, _hull_flash_left - delta)
	if _shield_shell != null:
		_shield_shell.visible = _shield_flash_left > 0.0
		_shield_shell.scale = Vector3.ONE * (1.0 + sin(_elapsed * 18.0) * 0.035)
	if _shield_material != null:
		_shield_material.albedo_color.a = clampf(_shield_flash_left * 4.0, 0.0, 0.48)
	if not _damage_marks.is_empty():
		var flash_mark := _damage_marks[0]
		if _hull_flash_left > 0.0:
			flash_mark.visible = true
			flash_mark.scale = Vector3.ONE * (1.0 + sin(_elapsed * 24.0) * 0.08)
		elif DAMAGE_STATES.find(_damage_state) < 2:
			flash_mark.visible = false
			flash_mark.scale = Vector3.ONE
	for index in _fire_nodes.size():
		var flame := _fire_nodes[index]
		flame.scale.y = 0.78 + sin(_elapsed * (7.0 + index) + index) * 0.16
	for index in _smoke_nodes.size():
		var smoke := _smoke_nodes[index]
		smoke.position.y = 1.75 + index * 0.52 + sin(_elapsed * 1.7 + index) * 0.16
		smoke.position.x = (-0.42 if index == 0 else 0.32) + sin(_elapsed * 0.8 + index) * 0.12
	if _critical_ring != null and _critical_ring.visible:
		_critical_ring.rotation.y += delta * 0.42
		_critical_ring.scale = Vector3.ONE * (0.96 + sin(_elapsed * 4.2) * 0.055)


func apply_server_state(state: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(state.get("source", "")) != "SERVER":
		return false
	var next_state := str(state.get("damage_state", "")).to_upper()
	if next_state not in DAMAGE_STATES:
		return false
	_server_presentation_mode = true
	_qa_preview_flash = false
	_set_state(next_state, str(state.get("shield_state", "NONE")).to_upper())
	return true


func play_server_reaction(kind: String, event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(event.get("source", "")) != "SERVER":
		return false
	if kind.to_upper() not in ["SHIELD_HIT", "HULL_HIT", "ARMOR_HIT", "CRITICAL_ENTER", "SINK_START", "SINK_COMPLETE"]: return false
	_qa_preview_flash = false
	_server_presentation_mode = true
	match kind.to_upper():
		"SHIELD_HIT": _shield_flash_left = 0.24
		"HULL_HIT", "ARMOR_HIT": _hull_flash_left = 0.18
		"CRITICAL_ENTER": _set_state("CRITICAL", str(event.get("shield_state", "BROKEN")))
		"SINK_START", "SINK_COMPLETE": _show_sinking_placeholder()
		_: return false
	return true


func play_local_qa_reaction(kind: String) -> bool:
	if not _local_qa_allowed() or _server_presentation_mode: return false
	match kind.to_upper():
		"SHIELD_HIT": _shield_flash_left = 0.24
		"HULL_HIT": _hull_flash_left = 0.18
		_: return false
	_qa_preview_flash = true
	return true


func clear_local_qa_reactions() -> bool:
	if not _local_qa_allowed() or _server_presentation_mode: return false
	_qa_preview_flash = false
	_shield_flash_left = 0.0
	_hull_flash_left = 0.0
	return true


func _local_qa_allowed() -> bool:
	return _local_preview_allowed() and bool(get_tree().root.get_meta("m299_animation_qa", false))


func confirm_visual_cleanup(server_verified: bool) -> bool:
	if not server_verified:
		return false
	_server_presentation_mode = false
	_reset_visuals()
	return true


func _bind_health_for_local_preview() -> void:
	if not _local_preview_allowed():
		return
	_health = get_parent().get_node_or_null("Health") as ShipHealth
	if _health == null:
		return
	_last_hull_ratio = _health.normalized()
	_last_shield_ratio = _health.shield_normalized()
	_health.health_changed.connect(_sync_local_preview_state)
	_health.ship_respawned.connect(_on_local_preview_respawn)
	_sync_local_preview_state()


func _on_local_preview_respawn(_ship: ShipMotor) -> void:
	if _local_preview_allowed() and not _server_presentation_mode: _reset_visuals()


func _sync_local_preview_state() -> void:
	if _health == null or not _local_preview_allowed() or _server_presentation_mode:
		return
	var hull_ratio := clampf(_health.normalized(), 0.0, 1.0)
	var shield_ratio := clampf(_health.shield_normalized(), 0.0, 1.0)
	if shield_ratio < _last_shield_ratio:
		_shield_flash_left = 0.24
	elif hull_ratio < _last_hull_ratio:
		_hull_flash_left = 0.18
	var preview_state := _preview_state_for_ratio(hull_ratio, _health.is_sunk)
	var shield_state := "NONE" if _health.max_shield <= 0.0 else ("BROKEN" if shield_ratio <= 0.0 else ("LOW" if shield_ratio < 0.3 else "STABLE"))
	_set_state(preview_state, shield_state)
	_last_hull_ratio = hull_ratio
	_last_shield_ratio = shield_ratio


func _set_state(next_state: String, _shield_state: String) -> void:
	_damage_state = next_state
	var severity := DAMAGE_STATES.find(next_state)
	for index in _damage_marks.size():
		_damage_marks[index].visible = severity >= index + 2
	for index in _fire_nodes.size():
		_fire_nodes[index].visible = severity >= index + 3 and (not _reduced_budget or index == 0)
	for index in _smoke_nodes.size():
		_smoke_nodes[index].visible = severity >= index + 2 and (not _reduced_budget or index == 0)
	if _critical_ring != null:
		_critical_ring.visible = next_state == "CRITICAL"
	# A shield state snapshot alone must not impersonate a confirmed SHIELD_HIT.
	# Only a verified impact event (or guarded local health delta) starts the flash.
	if next_state == "DEFEATED":
		_show_sinking_placeholder()
	elif _sinking_debris != null:
		_sinking_debris.visible = false


func _build_replaceable_placeholder_rig() -> void:
	name = "M285ShipDamageVisualRig"
	set_meta("presentation_only", true)
	set_meta("replaceable_slot_ids", SLOT_IDS.duplicate(true))
	set_meta("final_art_status", "PLACEHOLDER")
	var socket_root := get_parent().get_node_or_null("Sockets") as Node3D
	if socket_root == null:
		socket_root = Node3D.new()
		socket_root.name = "Sockets"
		get_parent().add_child(socket_root)
	var damage_a := _ensure_socket(socket_root, "VFX_Damage_01", Vector3(-0.62, 0.82, -0.65))
	var damage_b := _ensure_socket(socket_root, "VFX_Damage_02", Vector3(0.58, 0.82, 0.72))
	var shield := _ensure_socket(socket_root, "VFX_Shield", Vector3(0.0, 0.48, 0.0))
	var sink := _ensure_socket(socket_root, "VFX_Sink", Vector3(0.0, -0.18, 0.0))
	_build_shield(shield)
	_build_damage_cluster(damage_a, 0)
	_build_damage_cluster(damage_b, 1)
	_build_critical_and_sink(sink)
	_reset_visuals()


func _build_shield(parent: Node3D) -> void:
	_shield_shell = MeshInstance3D.new()
	_shield_shell.name = "ShieldImpactPlaceholder"
	var mesh := SphereMesh.new()
	mesh.radius = 2.55
	mesh.height = 5.1
	mesh.radial_segments = 24
	mesh.rings = 12
	_shield_shell.mesh = mesh
	_shield_shell.scale = Vector3(1.0, 0.42, 1.55)
	_shield_material = _emissive_material(Color(0.26, 0.72, 0.86, 0.34), 1.7)
	_shield_material.cull_mode = BaseMaterial3D.CULL_FRONT
	_shield_shell.material_override = _shield_material
	_shield_shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_shield_shell)


func _build_damage_cluster(parent: Node3D, index: int) -> void:
	var mark := MeshInstance3D.new()
	mark.name = "HullDamagePlaceholder_%02d" % (index + 1)
	var mark_mesh := BoxMesh.new()
	mark_mesh.size = Vector3(0.72, 0.045, 1.15)
	mark.mesh = mark_mesh
	mark.rotation_degrees = Vector3(0.0, 18.0 if index == 0 else -23.0, 7.0)
	mark.material_override = _material(Color("211714"), 0.92)
	parent.add_child(mark)
	_damage_marks.append(mark)

	var fire := MeshInstance3D.new()
	fire.name = "FirePlaceholder_%02d" % (index + 1)
	var fire_mesh := CylinderMesh.new()
	fire_mesh.top_radius = 0.04
	fire_mesh.bottom_radius = 0.28
	fire_mesh.height = 1.05
	fire_mesh.radial_segments = 8
	fire.mesh = fire_mesh
	fire.position = Vector3(0.0, 0.58, 0.0)
	fire.material_override = _emissive_material(Color(0.95, 0.31, 0.055, 0.86), 2.6)
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(fire)
	_fire_nodes.append(fire)

	var smoke := MeshInstance3D.new()
	smoke.name = "SmokePlaceholder_%02d" % (index + 1)
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.42 + index * 0.08
	smoke_mesh.height = 0.66 + index * 0.1
	smoke_mesh.radial_segments = 10
	smoke_mesh.rings = 6
	smoke.mesh = smoke_mesh
	smoke.material_override = _material(Color(0.055, 0.065, 0.072, 0.58), 1.0, true)
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(smoke)
	_smoke_nodes.append(smoke)


func _build_critical_and_sink(parent: Node3D) -> void:
	_critical_ring = MeshInstance3D.new()
	_critical_ring.name = "CriticalStatePlaceholder"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.35
	ring_mesh.outer_radius = 2.48
	_critical_ring.mesh = ring_mesh
	_critical_ring.material_override = _emissive_material(Color(0.82, 0.16, 0.065, 0.62), 2.15)
	_critical_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_critical_ring)

	_sinking_debris = Node3D.new()
	_sinking_debris.name = "SinkingDebrisPlaceholder"
	parent.add_child(_sinking_debris)
	for index in 4:
		var debris := MeshInstance3D.new()
		debris.name = "Debris_%02d" % (index + 1)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.18 + index * 0.04, 0.08, 0.72 - index * 0.08)
		debris.mesh = mesh
		debris.position = Vector3(-1.25 + index * 0.82, 0.18 + (index % 2) * 0.18, -0.75 + (index % 3) * 0.72)
		debris.rotation_degrees = Vector3(8.0 * index, 31.0 * index, 12.0 - 5.0 * index)
		debris.material_override = _material(Color("49301f"), 0.86)
		_sinking_debris.add_child(debris)


func _show_sinking_placeholder() -> void:
	if _sinking_debris != null:
		_sinking_debris.visible = true
	if _critical_ring != null:
		_critical_ring.visible = false


func _reset_visuals() -> void:
	_damage_state = "INTACT"
	_shield_flash_left = 0.0
	_hull_flash_left = 0.0
	if _shield_shell != null: _shield_shell.visible = false
	if _critical_ring != null: _critical_ring.visible = false
	if _sinking_debris != null: _sinking_debris.visible = false
	for node in _damage_marks: node.visible = false
	for node in _fire_nodes: node.visible = false
	for node in _smoke_nodes: node.visible = false


func _ensure_socket(parent: Node3D, socket_name: String, local_position: Vector3) -> Marker3D:
	var existing := parent.get_node_or_null(socket_name) as Marker3D
	if existing != null:
		return existing
	var socket := Marker3D.new()
	socket.name = socket_name
	socket.position = local_position
	parent.add_child(socket)
	return socket


func _preview_state_for_ratio(ratio: float, sunk: bool) -> String:
	if sunk or ratio <= 0.0: return "DEFEATED"
	if ratio <= 0.18: return "CRITICAL"
	if ratio <= 0.42: return "HEAVY"
	if ratio <= 0.68: return "MODERATE"
	if ratio < 0.9: return "LIGHT"
	return "INTACT"


func _local_preview_allowed() -> bool:
	var root := get_tree().root
	return str(root.get_meta("environment_id", "LOCAL_DEVELOPMENT")) == "LOCAL_DEVELOPMENT" and not bool(root.get_meta("server_authority_verified", false))


func _material(color: Color, roughness: float, transparent := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	if transparent: result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return result


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var result := _material(color, 0.38, color.a < 1.0)
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.emission_enabled = true
	result.emission = Color(color.r, color.g, color.b)
	result.emission_energy_multiplier = energy
	return result


func snapshot() -> Dictionary:
	return {"damage_state": _damage_state, "placeholder": true, "slot_ids": SLOT_IDS.duplicate(true), "local_preview": _local_preview_allowed(), "reduced_budget": _reduced_budget}


func reaction_presentation() -> Dictionary:
	# Read-only strengths for whole-model animation; cannot certify impact or damage.
	return {"hull": clampf(_hull_flash_left / 0.18, 0.0, 1.0), "shield": clampf(_shield_flash_left / 0.24, 0.0, 1.0), "damage_state": _damage_state}


func can_apply_damage() -> bool: return false
func can_confirm_defeat() -> bool: return false
func can_despawn_ship() -> bool: return false
func can_grant_reward_or_drop() -> bool: return false
