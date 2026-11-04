class_name M298ShipVisualAnimationRig
extends Node
## Animates ONLY the full GLB scene's local model transform, never the ship/collision.

const PROFILE_PATH := "res://data/m298_ship_visual_animation_profiles.json"
const SLOTS := ["ship_small", "ship_medium", "ship_large", "npc_friendly_coastal_sloop", "npc_scout_01", "npc_raider_01", "npc_gunship_01", "npc_heavy_01"]
static var _profiles: Dictionary = {}

var _model: Node3D
var _ship: ShipMotor
var _motion: M287ShipMotionVisualRig
var _damage: M285ShipDamageVisualRig
var _defeat: M286ShipDamageOverlayRig
var _base_position := Vector3.ZERO
var _base_rotation := Vector3.ZERO
var _profile: Dictionary = {}
var _elapsed := 0.0
var _sample_left := 0.0
var _phase := 0.0
var _speed := 0.0
var _turn := 0.0
var _hull_pulse := 0.0
var _shield_pulse := 0.0
var _defeated := false
var _defeat_phase := "NONE"
var _reduced_motion := false
var _mobile_budget := false


static func supports_slot(slot_id: String) -> bool:
	return slot_id in SLOTS


static func profile_for(slot_id: String) -> Dictionary:
	if _profiles.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
		_profiles = parsed if parsed is Dictionary else {}
	var defaults: Dictionary = _profiles.get("default", {})
	var entries: Dictionary = _profiles.get("slots", {})
	var values: Dictionary = entries.get(slot_id, {})
	var result := defaults.merged(values, true)
	result["defeat_phase_offsets_m"] = _profiles.get("confirmed_defeat_phase_offsets_m", {})
	result["defeat_phase_roll_deg"] = _profiles.get("confirmed_defeat_phase_roll_deg", {})
	return result


func _ready() -> void:
	name = "M298ShipVisualAnimationRig"
	var visual := get_parent() as Node3D
	if visual != null:
		_ship = visual.get_parent() as ShipMotor
		_model = visual.get_node_or_null("Model") as Node3D
	if _ship == null or _model == null:
		set_process(false)
		return
	var slot_id := str(visual.get_meta("asset_id", ""))
	if not supports_slot(slot_id):
		set_process(false)
		return
	_profile = profile_for(slot_id)
	_base_position = _model.position
	_base_rotation = _model.rotation
	_phase = float(posmod(slot_id.hash(), 127)) * 0.049
	_mobile_budget = OS.has_feature("mobile") or OS.has_feature("web") or bool(get_tree().root.get_meta("touch_ui", false))
	set_meta("presentation_only", true)
	set_meta("single_complete_model", true)
	set_meta("slot_id", slot_id)
	set_meta("native_qa", "NOT_EVALUATED")
	_sample_presentation()


func _process(delta: float) -> void:
	if _model == null: return
	var dt := clampf(delta, 0.0, 0.05)
	_elapsed += dt
	_sample_left -= dt
	if _sample_left <= 0.0:
		_sample_left = 0.08
		_sample_presentation()
	_animate_model(dt)


func _sample_presentation() -> void:
	if _ship == null: return
	if _motion == null: _motion = _ship.get_node_or_null("M287ShipMotionVisualRig") as M287ShipMotionVisualRig
	if _damage == null: _damage = _ship.get_node_or_null("M285ShipDamageVisualRig") as M285ShipDamageVisualRig
	if _defeat == null: _defeat = _ship.get_node_or_null("M286ShipDamageOverlayRig") as M286ShipDamageOverlayRig
	var settings := ClientSettings.current(get_tree())
	_reduced_motion = settings != null and settings.values.reduced_motion
	_speed = 0.0
	_turn = 0.0
	if _motion != null:
		var motion := _motion.snapshot()
		# M287 alone controls local-preview eligibility and verifies server snapshots.
		if bool(motion.get("server_mode", false)) or _local_preview_allowed():
			_speed = clampf(float(motion.get("speed_ratio", 0.0)), 0.0, 1.0)
			_turn = clampf(float(motion.get("turn_ratio", 0.0)), -1.0, 1.0)
	_hull_pulse = 0.0
	_shield_pulse = 0.0
	_defeated = false
	_defeat_phase = "NONE"
	if _damage != null:
		var impact := _damage.reaction_presentation()
		_hull_pulse = clampf(float(impact.get("hull", 0.0)), 0.0, 1.0)
		_shield_pulse = clampf(float(impact.get("shield", 0.0)), 0.0, 1.0)
		_defeated = str(impact.get("damage_state", "")) == "DEFEATED"
		if _defeated:
			_hull_pulse = 0.0
			_shield_pulse = 0.0
	if _defeat != null:
		# The separate M299 lab may preview phases locally; live play reads M286
		# only when the phase is not a QA-only preview.
		var phase_view := _defeat.snapshot()
		if not bool(phase_view.get("qa_preview_mode", false)) or _local_qa_allowed():
			_defeat_phase = str(phase_view.get("defeat_phase", "NONE"))


func _animate_model(dt: float) -> void:
	var ambient := 0.0 if _reduced_motion or _defeated or _defeat_phase != "NONE" else (0.65 if _mobile_budget else 1.0)
	var impact_scale := 0.12 if _reduced_motion else 1.0
	var cycle := _elapsed * TAU * clampf(float(_profile.get("cycles_per_second", 0.30)), 0.1, 0.6) + _phase
	var heave := sin(cycle) * clampf(float(_profile.get("heave_m", 0.035)), 0.0, 0.07) * ambient
	var pitch := sin(cycle + 0.7) * clampf(float(_profile.get("pitch_deg", 0.55)), 0.0, 1.2) * ambient
	var roll := sin(cycle * 0.83 + 1.1) * clampf(float(_profile.get("roll_deg", 0.62)), 0.0, 1.4) * ambient
	roll += _turn * _speed * clampf(float(_profile.get("turn_heel_deg", 0.82)), 0.0, 1.5) * ambient
	roll += _hull_pulse * clampf(float(_profile.get("hull_hit_heel_deg", 1.28)), 0.0, 1.8) * impact_scale
	var offsets: Dictionary = _profile.get("defeat_phase_offsets_m", {})
	var rolls: Dictionary = _profile.get("defeat_phase_roll_deg", {})
	var sink_m := clampf(float(offsets.get(_defeat_phase, 0.0)), 0.0, 2.1)
	var sink_roll_deg := clampf(float(rolls.get(_defeat_phase, 0.0)), 0.0, 8.0)
	var desired_position := _base_position + Vector3(0.0, clampf(heave + _shield_pulse * 0.012 * impact_scale, -0.09, 0.09) - sink_m, 0.0)
	var desired_rotation := _base_rotation + Vector3(deg_to_rad(pitch), 0.0, deg_to_rad(clampf(roll, -3.5, 3.5) + sink_roll_deg))
	var blend := 1.0 - exp(-dt * 8.0)
	_model.position = _model.position.lerp(desired_position, blend)
	_model.rotation = _model.rotation.lerp(desired_rotation, blend)


func _local_preview_allowed() -> bool:
	var root := get_tree().root
	return str(root.get_meta("environment_id", "LOCAL_DEVELOPMENT")) == "LOCAL_DEVELOPMENT" and not bool(root.get_meta("server_authority_verified", false))


func _local_qa_allowed() -> bool:
	return _local_preview_allowed() and bool(get_tree().root.get_meta("m299_animation_qa", false))


func snapshot() -> Dictionary:
	return {"slot_id": str(get_meta("slot_id", "")), "source": "PRESENTATION_ONLY", "reduced_motion": _reduced_motion, "mobile_budget": _mobile_budget, "defeat_phase": _defeat_phase, "single_complete_model": true, "native_qa": "NOT_EVALUATED"}


func can_move_ship() -> bool: return false
func can_change_collision() -> bool: return false
func can_confirm_hit() -> bool: return false
func can_apply_damage() -> bool: return false
