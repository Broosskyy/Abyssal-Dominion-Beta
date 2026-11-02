class_name M299ShipAnimationVisualQA
extends Node3D
## Standalone LOCAL_DEVELOPMENT visual lab; never a multiplayer/world QA verdict.

const SHIP_SLOTS := ["ship_small", "ship_medium", "ship_large", "npc_friendly_coastal_sloop", "npc_scout_01", "npc_raider_01", "npc_gunship_01", "npc_heavy_01"]
const SCENARIOS := ["IDLE", "CRUISE", "TURN PORT", "TURN STARBOARD", "SHIELD HIT", "HULL HIT", "STAGGER", "FLOODING", "BREAKUP", "SUBMERGED", "CLEANUP PENDING", "RESET"]
const M285Rig = preload("res://scripts/visual/m285_ship_damage_visual_rig.gd")
const M286Rig = preload("res://scripts/visual/m286_ship_damage_overlay_rig.gd")
const M287Rig = preload("res://scripts/visual/m287_ship_motion_visual_rig.gd")

var _ships: Array[ShipMotor] = []
var _status: Label
var _opened_qa := false
var _missing: Array[String] = []
var _compact_layout := false


func _ready() -> void:
	name = "M299ShipAnimationVisualQA"
	set_meta("native_status", "NOT_EVALUATED")
	set_meta("release_approved", false)
	set_meta("presentation_only", true)
	var root := get_tree().root
	if str(root.get_meta("environment_id", "LOCAL_DEVELOPMENT")) != "LOCAL_DEVELOPMENT" or bool(root.get_meta("server_authority_verified", false)):
		_build_ui(false)
		_status.text = "BLOCKIERT · nur LOCAL_DEVELOPMENT ohne Serverautorität"
		return
	root.set_meta("m299_animation_qa", true)
	_opened_qa = true
	var viewport_size := get_viewport().get_visible_rect().size
	_compact_layout = viewport_size.x / maxf(viewport_size.y, 1.0) < 0.9
	_build_environment()
	for index in SHIP_SLOTS.size(): _add_ship(SHIP_SLOTS[index], index)
	_build_ui(true)
	_apply_scenario("IDLE")


func _exit_tree() -> void:
	if _opened_qa: get_tree().root.set_meta("m299_animation_qa", false)


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("142a37")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a6b6bd")
	env.ambient_light_energy = 0.75
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-51.0, -36.0, 0.0)
	sun.light_color = Color("ffe2b5")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	add_child(sun)
	var sea := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(46.0, 52.0 if _compact_layout else 33.0)
	sea.mesh = plane
	sea.position.y = -0.5
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("19485a")
	water.roughness = 0.78
	sea.material_override = water
	add_child(sea)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 38.0, 42.0) if _compact_layout else Vector3(0.0, 31.0, 34.0)
	camera.fov = 55.0 if _compact_layout else 47.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0))


func _add_ship(slot_id: String, index: int) -> void:
	var ship := ShipMotor.new()
	ship.name = "QA_" + slot_id
	var columns := 2 if _compact_layout else 4
	var rows := 4 if _compact_layout else 2
	ship.position = Vector3((float(index % columns) - float(columns - 1) * 0.5) * (9.4 if _compact_layout else 8.4), 0.55, (floorf(float(index) / float(columns)) - float(rows - 1) * 0.5) * (10.5 if _compact_layout else 13.5))
	ship.rotation_degrees.y = -18.0
	ship.set_physics_process(false)
	add_child(ship)
	var motion: M287ShipMotionVisualRig = M287Rig.new()
	motion.name = "M287ShipMotionVisualRig"
	ship.add_child(motion)
	var damage: M285ShipDamageVisualRig = M285Rig.new()
	damage.name = "M285ShipDamageVisualRig"
	ship.add_child(damage)
	var defeat: M286ShipDamageOverlayRig = M286Rig.new()
	defeat.name = "M286ShipDamageOverlayRig"
	ship.add_child(defeat)
	var visual := AssetVisualLibrary.install(ship, slot_id, Vector3.ONE * 0.82)
	if visual == null:
		_missing.append(slot_id)
	else:
		var animation := visual.get_node_or_null("M298ShipVisualAnimationRig") as M298ShipVisualAnimationRig
		if animation == null: _missing.append(slot_id + " (Animation)")
	var label := Label3D.new()
	label.text = slot_id.to_upper()
	label.position = Vector3(0.0, 4.9, 0.0)
	label.font_size = 24
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ship.add_child(label)
	_ships.append(ship)


func _build_ui(enabled: bool) -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(12.0, 12.0)
	panel.custom_minimum_size = Vector2(280.0, 0.0)
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "M299 · VISUAL QA / KEINE LIVE-DATEN"
	box.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	if not enabled: return
	var choice := OptionButton.new()
	for scenario in SCENARIOS: choice.add_item(scenario)
	choice.item_selected.connect(func(item: int): _apply_scenario(choice.get_item_text(item)))
	box.add_child(choice)
	var info := Label.new()
	info.text = "M297 Modelle · M298 Animation · M299 Demo\nMobil/Desktop + Reduced Motion manuell prüfen"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)


func _apply_scenario(scenario: String) -> void:
	if not _opened_qa: return
	var accepted := 0
	for ship in _ships:
		var motion := ship.get_node_or_null("M287ShipMotionVisualRig") as M287ShipMotionVisualRig
		var damage := ship.get_node_or_null("M285ShipDamageVisualRig") as M285ShipDamageVisualRig
		var defeat := ship.get_node_or_null("M286ShipDamageOverlayRig") as M286ShipDamageOverlayRig
		var visual := ship.get_node_or_null("AssetVisual") as Node3D
		var slot_id := str(visual.get_meta("asset_id", "")) if visual != null else ""
		var profile := str(M298ShipVisualAnimationRig.profile_for(slot_id).get("profile", "BALANCED"))
		var state := "IDLE"
		var speed := 0.0
		var turn := 0.0
		if scenario == "CRUISE":
			state = "CRUISE"
			speed = 0.85
		if scenario == "TURN PORT":
			state = "TURNING"
			speed = 0.65
			turn = -0.9
		if scenario == "TURN STARBOARD":
			state = "TURNING"
			speed = 0.65
			turn = 0.9
		if motion != null and motion.apply_local_qa_preview(state, profile, speed, turn): accepted += 1
		var phase := scenario.replace(" ", "_") if scenario in ["STAGGER", "FLOODING", "BREAKUP", "SUBMERGED", "CLEANUP PENDING"] else "NONE"
		if defeat != null and defeat.apply_local_qa_defeat_phase(phase): accepted += 1
		if damage != null:
			damage.clear_local_qa_reactions()
			if scenario == "SHIELD HIT": damage.play_local_qa_reaction("SHIELD_HIT")
			elif scenario == "HULL HIT": damage.play_local_qa_reaction("HULL_HIT")
	_status.text = "Szenario: %s · %d/%d Demo-Eingaben\nNATIVE QA: NICHT AUSGEWERTET" % [scenario, accepted, _ships.size() * 2]
	if not _missing.is_empty(): _status.text += "\nFEHLENDE SLOTS: " + ", ".join(_missing)
