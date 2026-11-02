class_name M286ShipDamageOverlayRig
extends Node3D
## Legacy filename; runtime overlays for a complete single ship model, never ship modules.

const SEGMENTS := ["BOW", "PORT_HULL", "STARBOARD_HULL", "DECK", "MAST", "SAILS", "STERN"]
const SEGMENT_STATES := ["INTACT", "DAMAGED", "BREACHED", "DESTROYED"]
const DEFEAT_PHASES := ["NONE", "STAGGER", "FLOODING", "BREAKUP", "SUBMERGED", "CLEANUP_PENDING"]
const SLOT_IDS := {
	"deck_breach": "m286_model_deck_breach_placeholder",
	"mast_damage_overlay": "m286_vfx_mast_damage_overlay_placeholder",
	"sail_damage_overlay": "m286_vfx_sail_damage_overlay_placeholder",
	"bow_breach": "m286_model_bow_breach_placeholder",
	"stern_damage": "m286_model_stern_damage_placeholder",
	"waterline": "m286_vfx_waterline_flooding_placeholder",
	"bubbles": "m286_vfx_sinking_bubbles_placeholder",
	"wreck": "m286_model_wreck_silhouette_placeholder",
}

var _segment_visuals: Dictionary = {}
var _waterline_ring: MeshInstance3D
var _bubble_root: Node3D
var _wreck_root: Node3D
var _defeat_phase := "NONE"
var _presentation_seed := 0
var _elapsed := 0.0
var _reduced_budget := false
var _qa_preview_mode := false
var _server_presentation_mode := false


func _ready() -> void:
	name = "M286ShipDamageOverlayRig"
	add_to_group("m286_ship_damage_overlay_rigs")
	set_meta("presentation_only", true)
	set_meta("replaceable_slot_ids", SLOT_IDS.duplicate(true))
	set_meta("final_art_status", "PLACEHOLDER")
	set_meta("ship_model_strategy", "SINGLE_COMPLETE_3D_MODEL")
	set_meta("overlay_does_not_require_modular_mesh", true)
	_reduced_budget = OS.has_feature("mobile") or OS.has_feature("web") or bool(get_tree().root.get_meta("touch_ui", false))
	_build_rig()
	_reset_visuals()


func _process(delta: float) -> void:
	_elapsed += delta
	if _qa_preview_mode and not _local_qa_allowed():
		_qa_preview_mode = false
		_reset_visuals()
	if _waterline_ring != null and _waterline_ring.visible:
		var pulse := 1.0 + sin(_elapsed * 2.2 + float(_presentation_seed % 11)) * 0.045
		_waterline_ring.scale = Vector3(pulse, 1.0, pulse)
	if _bubble_root != null and _bubble_root.visible:
		for index in _bubble_root.get_child_count():
			var bubble := _bubble_root.get_child(index) as MeshInstance3D
			if bubble != null:
				bubble.position.y = -0.18 + fposmod(_elapsed * (0.34 + index * 0.035) + index * 0.23, 1.65)
	if _wreck_root != null and _wreck_root.visible:
		_wreck_root.position.y = -0.32 + sin(_elapsed * 0.55) * 0.04


func apply_server_escalation(state: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(state.get("source", "")) != "SERVER": return false
	var phase := str(state.get("defeat_phase", "NONE")).to_upper()
	if phase not in DEFEAT_PHASES: return false
	var segments := state.get("segment_states", {}) as Dictionary
	for segment in segments:
		var segment_id := str(segment).to_upper()
		var segment_state := str(segments[segment]).to_upper()
		if segment_id not in SEGMENTS or segment_state not in SEGMENT_STATES: return false
	_presentation_seed = maxi(0, int(state.get("presentation_seed", 0)))
	_server_presentation_mode = true
	_qa_preview_mode = false
	for segment in SEGMENTS:
		_set_segment_state(segment, str(segments.get(segment, "INTACT")).to_upper())
	_set_defeat_phase(phase)
	return true


func play_server_transition(kind: String, event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(event.get("source", "")) != "SERVER": return false
	if kind.to_upper() not in ["DECK_BREACH", "MAST_BREAK", "SAIL_TEAR", "BOW_BREACH", "STERN_BREAK", "FLOODING_START", "BREAKUP_START", "SUBMERGED", "WRECK_REVEAL"]: return false
	_presentation_seed = maxi(0, int(event.get("presentation_seed", _presentation_seed)))
	_server_presentation_mode = true
	_qa_preview_mode = false
	match kind.to_upper():
		"DECK_BREACH": _set_segment_state("DECK", "BREACHED")
		"MAST_BREAK": _set_segment_state("MAST", "DESTROYED")
		"SAIL_TEAR": _set_segment_state("SAILS", "DAMAGED")
		"BOW_BREACH": _set_segment_state("BOW", "BREACHED")
		"STERN_BREAK": _set_segment_state("STERN", "DESTROYED")
		"FLOODING_START": _set_defeat_phase("FLOODING")
		"BREAKUP_START": _set_defeat_phase("BREAKUP")
		"SUBMERGED": _set_defeat_phase("SUBMERGED")
		"WRECK_REVEAL": _set_defeat_phase("CLEANUP_PENDING")
		_: return false
	return true


func apply_local_qa_defeat_phase(phase: String) -> bool:
	if not _local_qa_allowed() or _server_presentation_mode: return false
	var next_phase := phase.to_upper()
	if next_phase not in DEFEAT_PHASES: return false
	_qa_preview_mode = true
	if next_phase == "NONE": _reset_visuals()
	else: _set_defeat_phase(next_phase)
	return true


func _local_qa_allowed() -> bool:
	var root := get_tree().root
	return str(root.get_meta("environment_id", "LOCAL_DEVELOPMENT")) == "LOCAL_DEVELOPMENT" and not bool(root.get_meta("server_authority_verified", false)) and bool(root.get_meta("m299_animation_qa", false))


func confirm_visual_cleanup(server_verified: bool) -> bool:
	if not server_verified: return false
	_server_presentation_mode = false
	_qa_preview_mode = false
	_reset_visuals()
	return true


func _build_rig() -> void:
	var sockets := get_parent().get_node_or_null("Sockets") as Node3D
	if sockets == null:
		sockets = Node3D.new()
		sockets.name = "Sockets"
		get_parent().add_child(sockets)
	_build_damage_plate(_ensure_socket(sockets, "VFX_Bow", Vector3(0.0, 0.28, 2.52)), "BOW", Color("2c1712"), Vector3(1.4, 0.5, 0.16))
	_build_damage_plate(_ensure_socket(sockets, "VFX_PortHull", Vector3(-1.08, 0.0, 0.0)), "PORT_HULL", Color("241612"), Vector3(0.12, 0.52, 1.55))
	_build_damage_plate(_ensure_socket(sockets, "VFX_StarboardHull", Vector3(1.08, 0.0, 0.0)), "STARBOARD_HULL", Color("241612"), Vector3(0.12, 0.52, 1.55))
	_build_deck_breach(_ensure_socket(sockets, "VFX_Deck", Vector3(0.0, 0.68, 0.0)))
	_build_mast_damage_overlay(_ensure_socket(sockets, "VFX_Mast", Vector3(0.0, 1.25, 0.28)))
	_build_sail_damage_overlay(_ensure_socket(sockets, "VFX_Sails", Vector3(0.0, 2.1, 0.25)))
	_build_damage_plate(_ensure_socket(sockets, "VFX_Stern", Vector3(0.0, 0.42, -2.48)), "STERN", Color("311912"), Vector3(1.42, 0.62, 0.14))
	_build_waterline(_ensure_socket(sockets, "VFX_Waterline", Vector3(0.0, -0.42, 0.0)))
	_build_wreck(_ensure_socket(sockets, "VFX_Wreck", Vector3(0.0, -0.48, 0.0)))


func _build_damage_plate(parent: Node3D, segment: String, color: Color, size: Vector3) -> void:
	var root := Node3D.new()
	root.name = segment.capitalize().replace("_", "") + "DamagePlaceholder"
	parent.add_child(root)
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	plate.mesh = mesh
	plate.material_override = _material(color, 0.94)
	root.add_child(plate)
	for index in 3:
		var splinter := MeshInstance3D.new()
		var splinter_mesh := BoxMesh.new()
		splinter_mesh.size = Vector3(0.08, 0.08, 0.58 - index * 0.1)
		splinter.mesh = splinter_mesh
		splinter.position = Vector3(-0.22 + index * 0.22, 0.12 + index * 0.04, 0.08)
		splinter.rotation_degrees = Vector3(10.0 * index, 24.0 * index, -18.0 + 13.0 * index)
		splinter.material_override = _material(Color("5b351f"), 0.9)
		root.add_child(splinter)
	_segment_visuals[segment] = root


func _build_deck_breach(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "DeckBreachPlaceholder"
	parent.add_child(root)
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.32
	rim_mesh.outer_radius = 0.48
	rim.mesh = rim_mesh
	rim.scale.z = 1.5
	rim.material_override = _material(Color("241510"), 0.95)
	root.add_child(rim)
	_segment_visuals["DECK"] = root


func _build_mast_damage_overlay(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "MastDamageOverlayPlaceholder"
	parent.add_child(root)
	var stump := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.14
	mesh.height = 1.25
	stump.mesh = mesh
	stump.rotation_degrees.z = 31.0
	stump.material_override = _material(Color("4d2a16"), 0.88)
	root.add_child(stump)
	_segment_visuals["MAST"] = root


func _build_sail_damage_overlay(parent: Node3D) -> void:
	var root := Node3D.new()
	root.name = "SailDamageOverlayPlaceholder"
	parent.add_child(root)
	for index in 3:
		var strip := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.42 + index * 0.1, 1.08 - index * 0.15)
		strip.mesh = mesh
		strip.position = Vector3(-0.52 + index * 0.5, -0.15 * index, 0.0)
		strip.rotation_degrees.z = -8.0 + index * 7.0
		var mat := _material(Color("918978"), 0.88)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		strip.material_override = mat
		root.add_child(strip)
	_segment_visuals["SAILS"] = root


func _build_waterline(parent: Node3D) -> void:
	_waterline_ring = MeshInstance3D.new()
	_waterline_ring.name = "FloodingWaterlinePlaceholder"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 2.25
	mesh.outer_radius = 2.58
	_waterline_ring.mesh = mesh
	_waterline_ring.scale.z = 1.5
	_waterline_ring.material_override = _emissive(Color(0.31, 0.72, 0.78, 0.48), 1.25)
	_waterline_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(_waterline_ring)
	_bubble_root = Node3D.new()
	_bubble_root.name = "SinkingBubblesPlaceholder"
	parent.add_child(_bubble_root)
	var count := 4 if _reduced_budget else 8
	for index in count:
		var bubble := MeshInstance3D.new()
		var bubble_mesh := SphereMesh.new()
		bubble_mesh.radius = 0.08 + (index % 3) * 0.035
		bubble_mesh.height = bubble_mesh.radius * 2.0
		bubble.mesh = bubble_mesh
		bubble.position = Vector3(-1.1 + (index % 4) * 0.72, -0.18, -0.8 + (index % 3) * 0.72)
		bubble.material_override = _emissive(Color(0.62, 0.88, 0.92, 0.45), 0.8)
		bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_bubble_root.add_child(bubble)


func _build_wreck(parent: Node3D) -> void:
	_wreck_root = Node3D.new()
	_wreck_root.name = "WreckSilhouettePlaceholder"
	parent.add_child(_wreck_root)
	for data in [[Vector3(0.0, 0.0, 0.0), Vector3(1.72, 0.34, 3.5)], [Vector3(-0.68, 0.25, 0.72), Vector3(0.18, 0.18, 1.45)], [Vector3(0.72, 0.12, -0.62), Vector3(0.16, 0.16, 1.2)]]:
		var part := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = data[1]
		part.mesh = mesh
		part.position = data[0]
		part.rotation_degrees = Vector3(8.0, 12.0, -11.0)
		part.material_override = _material(Color("241b18"), 1.0)
		_wreck_root.add_child(part)


func _set_segment_state(segment: String, state: String) -> void:
	var node := _segment_visuals.get(segment) as Node3D
	if node == null: return
	node.visible = state in ["DAMAGED", "BREACHED", "DESTROYED"] and (not _reduced_budget or segment in ["DECK", "MAST", "BOW", "STERN"])
	var severity := SEGMENT_STATES.find(state)
	node.scale = Vector3.ONE * (0.78 + severity * 0.12)


func _set_defeat_phase(phase: String) -> void:
	_defeat_phase = phase
	if _waterline_ring != null: _waterline_ring.visible = phase in ["FLOODING", "BREAKUP"]
	if _bubble_root != null: _bubble_root.visible = phase in ["FLOODING", "BREAKUP", "SUBMERGED"]
	if _wreck_root != null: _wreck_root.visible = phase in ["SUBMERGED", "CLEANUP_PENDING"]


func _reset_visuals() -> void:
	_defeat_phase = "NONE"
	for segment in _segment_visuals: (_segment_visuals[segment] as Node3D).visible = false
	if _waterline_ring != null: _waterline_ring.visible = false
	if _bubble_root != null: _bubble_root.visible = false
	if _wreck_root != null: _wreck_root.visible = false


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


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	if color.a < 1.0: result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return result


func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var result := _material(color, 0.4)
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.emission_enabled = true
	result.emission = Color(color.r, color.g, color.b)
	result.emission_energy_multiplier = energy
	return result


func snapshot() -> Dictionary:
	return {"defeat_phase":_defeat_phase, "presentation_seed":_presentation_seed, "qa_preview_mode":_qa_preview_mode, "placeholder":true, "slot_ids":SLOT_IDS.duplicate(true), "reduced_budget":_reduced_budget}


func can_change_ship_transform() -> bool: return false
func can_require_modular_ship_mesh() -> bool: return false
func can_hide_detach_or_replace_ship_parts() -> bool: return false
func can_apply_segment_damage() -> bool: return false
func can_break_equipment() -> bool: return false
func can_confirm_sinking() -> bool: return false
func can_spawn_loot_or_wreck_entity() -> bool: return false
