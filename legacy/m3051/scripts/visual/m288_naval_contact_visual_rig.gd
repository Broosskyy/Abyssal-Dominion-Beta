class_name M288NavalContactVisualRig
extends Node3D
## World-space readability overlays for a complete individual ship model.

const CONTACT_CLASSES := ["PLAYER", "FLEET_ALLY", "FRIENDLY", "NEUTRAL", "HOSTILE", "ELITE", "ADMIRAL", "MONSTER", "BOSS"]
const ENGAGEMENT_STATES := ["PASSIVE", "AWARE", "AGGRO", "TARGETED", "IN_RANGE", "OUT_OF_RANGE", "PROTECTED", "DEFEATED"]
const SLOT_IDS := {
	"target_focus": "m288_vfx_target_focus_ring_placeholder",
	"relation_arc": "m288_vfx_relation_arc_placeholder",
	"threat_chevrons": "m288_vfx_threat_chevrons_placeholder",
	"range_bracket": "m288_vfx_range_state_bracket_placeholder",
	"priority_beacon": "m288_vfx_priority_beacon_placeholder",
	"offscreen_marker": "m288_ui_offscreen_contact_marker_placeholder",
}

var _target_ring: MeshInstance3D
var _relation_ring: MeshInstance3D
var _range_ring: MeshInstance3D
var _threat_nodes: Array[MeshInstance3D] = []
var _priority_beacon: MeshInstance3D
var _contact_class := "NEUTRAL"
var _engagement_state := "PASSIVE"
var _selected := false
var _in_range := false
var _protected := false
var _attack_legal := false
var _presentation_seed := 0
var _elapsed := 0.0
var _server_mode := false
var _reduced_budget := false


func _ready() -> void:
	name = "M288NavalContactVisualRig"
	add_to_group("m288_naval_contact_visual_rigs")
	set_meta("presentation_only", true)
	set_meta("replaceable_slot_ids", SLOT_IDS.duplicate(true))
	set_meta("final_art_status", "PLACEHOLDER")
	set_meta("ship_model_strategy", "SINGLE_COMPLETE_3D_MODEL")
	set_meta("overlay_does_not_require_modular_mesh", true)
	_reduced_budget = OS.has_feature("mobile") or OS.has_feature("web") or bool(get_tree().root.get_meta("touch_ui", false))
	_build_rig()


func _process(delta: float) -> void:
	_elapsed += delta
	_animate_presentation()


func apply_server_contact(state: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(state.get("source", "")) != "SERVER": return false
	var next_class := str(state.get("contact_class", "NEUTRAL")).to_upper()
	var next_engagement := str(state.get("engagement_state", "PASSIVE")).to_upper()
	if next_class not in CONTACT_CLASSES or next_engagement not in ENGAGEMENT_STATES: return false
	_contact_class = next_class
	_engagement_state = next_engagement
	_selected = bool(state.get("selected", false))
	_in_range = bool(state.get("in_range", false))
	_protected = bool(state.get("protected", false))
	_attack_legal = bool(state.get("attack_legal", false))
	_presentation_seed = maxi(0, int(state.get("presentation_seed", 0)))
	_server_mode = true
	return true


func play_server_contact_event(kind: String, event: Dictionary, server_verified: bool) -> bool:
	if not server_verified or str(event.get("source", "")) != "SERVER": return false
	_presentation_seed = maxi(0, int(event.get("presentation_seed", _presentation_seed)))
	match kind.to_upper():
		"TARGET_ACQUIRED": _selected = true
		"TARGET_CLEARED": _selected = false
		"THREAT_ENTER": _engagement_state = "AGGRO"
		"THREAT_EXIT": _engagement_state = "PASSIVE"
		"RANGE_ENTER": _in_range = true
		"RANGE_EXIT": _in_range = false
		"PROTECTION_CHANGED": _protected = bool(event.get("protected", _protected))
		"PRIORITY_CHANGED": pass
		_: return false
	return true


func clear_server_contact(server_verified: bool) -> bool:
	if not server_verified: return false
	_server_mode = false
	_selected = false
	_engagement_state = "PASSIVE"
	_in_range = false
	_protected = false
	return true


func _build_rig() -> void:
	var sockets := get_parent().get_node_or_null("Sockets") as Node3D
	if sockets == null:
		sockets = Node3D.new()
		sockets.name = "Sockets"
		get_parent().add_child(sockets)
	var water_anchor := _ensure_socket(sockets, "CONTACT_WaterAnchor", Vector3(0.0, -0.5, 0.0))
	var upper_anchor := _ensure_socket(sockets, "CONTACT_UpperAnchor", Vector3(0.0, 3.8, 0.0))
	_target_ring = _ring("TargetFocusRingPlaceholder", 2.72, 2.92, Color("e8bd69"), water_anchor)
	_relation_ring = _ring("RelationArcPlaceholder", 2.25, 2.4, Color("7896a4"), water_anchor)
	_range_ring = _ring("RangeStateBracketPlaceholder", 3.12, 3.25, Color("6cae91"), water_anchor)
	for index in 3:
		var chevron := MeshInstance3D.new()
		chevron.name = "ThreatChevronPlaceholder_%d" % index
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.42, 0.08, 0.72)
		chevron.mesh = mesh
		chevron.position = Vector3((index - 1) * 0.72, 0.0, 3.25)
		chevron.material_override = _overlay_material(Color("d75d4b"))
		chevron.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		water_anchor.add_child(chevron)
		_threat_nodes.append(chevron)
	_priority_beacon = MeshInstance3D.new()
	_priority_beacon.name = "PriorityBeaconPlaceholder"
	var beacon_mesh := CylinderMesh.new()
	beacon_mesh.top_radius = 0.04
	beacon_mesh.bottom_radius = 0.26
	beacon_mesh.height = 1.0
	_priority_beacon.mesh = beacon_mesh
	_priority_beacon.material_override = _overlay_material(Color("d6a657"))
	_priority_beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	upper_anchor.add_child(_priority_beacon)


func _animate_presentation() -> void:
	if not _server_mode:
		_set_all_visible(false)
		return
	var settings := ClientSettings.current(get_tree())
	var motion_scale := 0.28 if settings != null and settings.values.reduced_motion else 1.0
	var pulse := 0.82 + sin(_elapsed * 3.2 * motion_scale + float(_presentation_seed % 11)) * 0.12
	var relation_color := _class_color(_contact_class)
	_target_ring.visible = _selected
	_target_ring.rotation_degrees.y = fposmod(_elapsed * 10.0 * motion_scale, 360.0)
	_set_color_alpha(_target_ring, Color("e8bd69"), 0.58 * pulse)
	_relation_ring.visible = _contact_class != "NEUTRAL" and (_selected or not _reduced_budget)
	_set_color_alpha(_relation_ring, relation_color, 0.42)
	_range_ring.visible = _selected and not _protected
	_set_color_alpha(_range_ring, Color("65b889") if _in_range and _attack_legal else Color("ba6b58"), 0.42)
	var threat := _engagement_state in ["AGGRO", "TARGETED", "IN_RANGE"]
	for index in _threat_nodes.size():
		var node := _threat_nodes[index]
		node.visible = threat and (not _reduced_budget or index == 1)
		node.position.z = 3.2 + sin(_elapsed * 4.0 * motion_scale + index * 0.7) * 0.1
		_set_color_alpha(node, Color("dc654f"), 0.46 * pulse)
	var priority := _contact_class in ["ELITE", "ADMIRAL", "MONSTER", "BOSS"]
	_priority_beacon.visible = priority and (_selected or not _reduced_budget)
	_priority_beacon.scale.y = 0.78 + pulse * 0.35
	_set_color_alpha(_priority_beacon, relation_color, 0.5 * pulse)


func _set_all_visible(value: bool) -> void:
	for node in [_target_ring, _relation_ring, _range_ring, _priority_beacon]:
		if node != null: node.visible = value
	for node in _threat_nodes: node.visible = value


func _ring(node_name: String, inner: float, outer: float, color: Color, parent: Node3D) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 28
	mesh.ring_segments = 5
	node.mesh = mesh
	node.scale.y = 0.08
	node.material_override = _overlay_material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


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


func _overlay_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.55
	return material


func _set_color_alpha(node: MeshInstance3D, color: Color, alpha: float) -> void:
	var material := node.material_override as StandardMaterial3D
	if material == null: return
	material.albedo_color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 0.68))
	material.emission = color


func _class_color(contact_class: String) -> Color:
	match contact_class:
		"PLAYER": return Color("8fc7d8")
		"FLEET_ALLY", "FRIENDLY": return Color("72b89d")
		"HOSTILE": return Color("ca5c50")
		"ELITE": return Color("d49250")
		"ADMIRAL", "BOSS": return Color("e2b45f")
		"MONSTER": return Color("a779c7")
		_: return Color("83939b")


func snapshot() -> Dictionary:
	return {"contact_class":_contact_class, "engagement_state":_engagement_state, "selected":_selected, "in_range":_in_range, "protected":_protected, "server_mode":_server_mode, "placeholder":true, "slot_ids":SLOT_IDS.duplicate(true), "reduced_budget":_reduced_budget, "ship_model_strategy":"SINGLE_COMPLETE_3D_MODEL"}


func can_select_or_clear_target() -> bool: return false
func can_decide_attack_legality_or_range() -> bool: return false
func can_set_relationship_or_aggro() -> bool: return false
func can_remove_protection() -> bool: return false
func can_require_modular_ship_mesh() -> bool: return false
func can_hide_detach_or_replace_ship_parts() -> bool: return false
func can_promote_visual_contact_to_authority() -> bool: return false
