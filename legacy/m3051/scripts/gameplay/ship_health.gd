class_name ShipHealth
extends Node

signal ship_sunk(ship: ShipMotor, attacker: Node3D)
signal ship_respawned(ship: ShipMotor)
signal health_changed
signal damage_applied(target: Node3D, attacker: Node3D, actual_damage: float, slowed: bool, critical: bool)

const SINK_AUDIO := "res://assets/recovered_test/m8/audio/DESTROYED_SHIP_SINKING__571.wav"
const M216ShipCombatFxScript = preload("res://scripts/visual/m216_ship_combat_fx.gd")
const M218EncounterReadabilityScript = preload("res://scripts/visual/m218_encounter_readability.gd")

@export var max_health := 500.0
@export var armor := 0.08
@export var max_shield := 0.0
var current_health := 0.0
var current_shield := 0.0
var respawn_position := Vector3.ZERO
var is_sunk := false
var auto_respawn := true
var _respawn_generation := 0
var _sink_tween: Tween
var ammo_effect_until: Dictionary = {}
var ammo_effect_power: Dictionary = {}
var ammo_effect_attacker: Dictionary = {}
var _dot_tick := 0.0
var temporary_barrier := 0.0
var temporary_barrier_until := 0.0
var repair_block_until := 0.0
const PLAYER_RESPAWN_PROTECTION_SECONDS := 6.0

@onready var ship: ShipMotor = get_parent() as ShipMotor


func _ready() -> void:
	current_health = max_health
	current_shield = max_shield
	var feedback := GameScope.owner_of(self).get_node_or_null("CombatFeedback") as CombatFeedback
	if feedback != null:
		damage_applied.connect(feedback.record_hit)


func _process(delta: float) -> void:
	if is_sunk: return
	var now := Time.get_ticks_msec() / 1000.0
	_dot_tick -= delta
	if _dot_tick <= 0.0:
		_dot_tick = 1.0
		for id in ammo_effect_until.keys():
			if now < float(ammo_effect_until.get(id, 0.0)) and _effect_category(str(id)) == "dot":
				apply_damage(float(ammo_effect_power.get(id, 0.0)), ammo_effect_attacker.get(id, null), 1.0, 0.0, false)

func _m166_effect(effect_id:String)->Dictionary:
	var tree:=get_tree()
	if tree==null:return {}
	var cat:=tree.get_first_node_in_group("m166_production_depth_catalog") as M166ProductionDepthCatalog
	return cat.effect(effect_id) if cat!=null else {}

func _effect_category(effect_id:String)->String:
	var row:=_m166_effect(effect_id)
	if not row.is_empty():return str(row.get("category",""))
	if effect_id in ["burn","venom"]:return "dot"
	if effect_id=="armor_break":return "defense_debuff"
	if effect_id=="spectral_mark":return "vulnerability"
	return ""

func _active_category_power(categories:Array[String], now:float)->float:
	var result:=0.0
	for key in ammo_effect_until.keys():
		if now < float(ammo_effect_until.get(key,0.0)) and _effect_category(str(key)) in categories:
			result=maxf(result,float(ammo_effect_power.get(key,0.0)))
	return result

func apply_ammo_effect(effect_id: String, power: float, duration: float, attacker: Node3D) -> void:
	if effect_id=="none" or duration <= 0.0:return
	var category:=_effect_category(effect_id)
	if category.is_empty():return
	var now := Time.get_ticks_msec() / 1000.0
	ammo_effect_until[effect_id] = maxf(float(ammo_effect_until.get(effect_id, 0.0)), now + duration)
	ammo_effect_power[effect_id] = maxf(float(ammo_effect_power.get(effect_id, 0.0)), power)
	ammo_effect_attacker[effect_id] = attacker
	if category=="control":ship.add_speed_effect("ammo_%s"%effect_id,1.0-clampf(power,0.0,0.65),duration)
	if category=="weapon_debuff":
		ship.set_meta("weapon_reload_debuff_power",maxf(float(ship.get_meta("weapon_reload_debuff_power",0.0)),power))
		ship.set_meta("weapon_reload_debuff_until",maxf(float(ship.get_meta("weapon_reload_debuff_until",0.0)),now+duration))
	health_changed.emit()

func grant_temporary_barrier(amount: float, duration: float) -> float:
	if is_sunk or amount <= 0.0 or duration <= 0.0: return 0.0
	var now := Time.get_ticks_msec() / 1000.0
	temporary_barrier = maxf(temporary_barrier, amount)
	temporary_barrier_until = maxf(temporary_barrier_until, now + duration)
	health_changed.emit()
	return temporary_barrier

func block_repair(duration: float) -> void:
	if duration <= 0.0: return
	repair_block_until = maxf(repair_block_until, Time.get_ticks_msec() / 1000.0 + duration)
	health_changed.emit()

func repair_blocked() -> bool:
	return Time.get_ticks_msec() / 1000.0 < repair_block_until

func barrier_remaining() -> float:
	if Time.get_ticks_msec() / 1000.0 >= temporary_barrier_until: return 0.0
	return temporary_barrier

func normalized() -> float:
	return 0.0 if max_health <= 0.0 else current_health / max_health

func shield_normalized() -> float:
	return 0.0 if max_shield <= 0.0 else current_shield / max_shield

func restore_shield(amount: float, source: Node3D = null) -> float:
	if is_sunk or max_shield <= 0.0: return 0.0
	var previous := current_shield
	current_shield = minf(max_shield, current_shield + maxf(0.0, amount))
	var applied := current_shield - previous
	if applied > 0.0:
		health_changed.emit()
		_record_feedback(applied, source, "shield")
	return applied


func apply_damage(amount: float, attacker: Node3D, armor_pierce: float = 0.0, slow: float = 0.0, critical: bool = false) -> void:
	if bool(ship.get_meta("admin_invulnerable",false)) and ship.is_in_group("player"):
		return
	if is_sunk:
		return
	if ship.is_in_group("player") and Time.get_ticks_msec() < int(ship.get_meta("respawn_protection_until", 0)):
		return
	if ship.get_meta("in_safe_zone", false):
		return
	var now := Time.get_ticks_msec() / 1000.0
	var armor_break := _active_category_power(["defense_debuff"],now)
	var vulnerability := _active_category_power(["vulnerability","hunter_mark","siege_debuff"],now)
	var incoming := maxf(0.0, amount) * (1.0 + vulnerability)
	if ship.is_in_group("player"):
		incoming *= clampf(float(ship.get_meta("corruption_damage_taken_mult",1.0)),1.0,1.20)

	# M54 canonical local defense stack:
	# 1) temporary barrier, 2) shield, 3) armor + consumable plate mitigation, 4) hull.
	# Barrier/shield are separate pools and therefore are not reduced by hull armor.
	if now >= temporary_barrier_until:
		temporary_barrier = 0.0
	var barrier_absorb := 0.0
	if temporary_barrier > 0.0 and incoming > 0.0:
		barrier_absorb = minf(temporary_barrier, incoming)
		temporary_barrier -= barrier_absorb
		incoming -= barrier_absorb

	var previous_shield := current_shield
	if current_shield > 0.0 and incoming > 0.0:
		var shield_absorb := minf(current_shield, incoming)
		current_shield -= shield_absorb
		incoming -= shield_absorb

	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	var module_armor := inventory.module_modifier("armor_add", 0.0) if inventory != null else 0.0
	module_armor += clampf(float(ship.get_meta("ancient_armor_add",0.0)),0.0,0.08)
	var mitigation := clampf(armor + module_armor - armor_break - armor_pierce, 0.0, 0.72)
	var pre_armor_incoming := incoming
	var hull_incoming := incoming * (1.0 - mitigation)
	if inventory != null and hull_incoming > 0.0:
		hull_incoming *= 1.0 - inventory.consume_plate_for_hit()

	var previous_health := current_health
	current_health = maxf(0.0, current_health - hull_incoming)
	health_changed.emit()

	var actual_total := (previous_health - current_health) + (previous_shield - current_shield)
	if actual_total > 0.0:
		damage_applied.emit(ship, attacker, actual_total, slow > 0.0, critical)
		# M216: visual hull response remains presentation-only and does not modify damage authority.
		M216ShipCombatFxScript.hit_reaction(ship, critical)
	if barrier_absorb >= 5.0:
		_record_feedback(barrier_absorb, attacker, "block")
	var armor_saved := maxf(0.0, pre_armor_incoming - hull_incoming)
	if armor_saved >= maxf(5.0, pre_armor_incoming * 0.08):
		_record_feedback(armor_saved, attacker, "armor")
	if slow > 0.0:
		_apply_temporary_slow(slow)
	if current_health <= 0.0:
		is_sunk = true
		ship_sunk.emit(ship, attacker)
		_sink_and_respawn()


func repair(amount: float, source: Node3D = null, feedback_kind: String = "repair") -> float:
	if is_sunk or repair_blocked():
		return 0.0
	var previous := current_health
	current_health = min(max_health, current_health + max(0.0, amount))
	var applied := current_health - previous
	if applied > 0.0:
		health_changed.emit()
		_record_feedback(applied, source, feedback_kind)
	return applied


func _record_feedback(amount: float, source: Node3D, kind: String) -> void:
	var feedback := GameScope.owner_of(self).get_node_or_null("CombatFeedback") as CombatFeedback
	if feedback != null:
		feedback.record_value(ship, source, amount, kind)


func _apply_temporary_slow(strength: float) -> void:
	ship.add_speed_effect("chain_slow", 1.0 - clampf(strength, 0.0, 0.7), 2.5)


func force_respawn() -> void:
	_respawn_generation += 1
	if _sink_tween != null and _sink_tween.is_valid():
		_sink_tween.kill()
	_restore_now()


func _sink_and_respawn() -> void:
	is_sunk = true
	ship.set_meta("navigation_pivoting", false)
	ship.set_meta("respawn_at_msec", Time.get_ticks_msec() + 3450)
	if ship.is_in_group("player"):
		var input := ship.get_node_or_null("PlayerInput") as PlayerShipInput
		if input != null:
			input.cancel_navigation()
		var hud := get_tree().get_first_node_in_group("hud") as GameHud
		if hud != null:
			hud.note_prioritized("SCHIFF VERSENKT · RÜCKKEHR ZUM HAFEN", 10, "defeat", 5000)
	_play_sink_audio()
	M216ShipCombatFxScript.sink_burst(ship, str(ship.get_meta("rarity", "")) == "boss" or bool(ship.get_meta("is_admiral", false)))
	M218EncounterReadabilityScript.sink_class_read(ship)
	ship.stop_ship()
	ship.set_physics_process(false)
	_set_collision(false)
	health_changed.emit()
	_respawn_generation += 1
	var generation := _respawn_generation
	_sink_tween = create_tween().set_parallel(true)
	_sink_tween.tween_property(ship, "position:y", ship.position.y - 2.4, 1.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_sink_tween.tween_property(ship, "rotation:z", ship.rotation.z + deg_to_rad(24.0), 1.35)
	await _sink_tween.finished
	if generation != _respawn_generation:
		return
	ship.visible = false
	ship.set_physics_process(false)
	_set_collision(false)
	if not auto_respawn:
		ship.queue_free()
		return
	await get_tree().create_timer(2.1).timeout
	if generation == _respawn_generation:
		_restore_now()


func _play_sink_audio() -> void:
	if not ResourceLoader.exists(SINK_AUDIO):
		return
	var audio := AudioStreamPlayer3D.new()
	audio.bus = "Combat"
	audio.name = "SinkAudio"
	audio.stream = load(SINK_AUDIO) as AudioStream
	audio.volume_db = -4.0
	audio.max_distance = 48.0
	GameScope.owner_of(self).add_child(audio)
	audio.global_position = ship.global_position
	audio.finished.connect(audio.queue_free)
	audio.play()


func _restore_now() -> void:
	ship.speed_effects.clear()
	ammo_effect_until.clear()
	ammo_effect_power.clear()
	ammo_effect_attacker.clear()
	temporary_barrier = 0.0
	temporary_barrier_until = 0.0
	repair_block_until = 0.0
	ship.position = respawn_position
	ship.rotation = Vector3.ZERO
	ship.visible = true
	ship.set_physics_process(true)
	_set_collision(true)
	current_health = max_health
	current_shield = max_shield
	is_sunk = false
	ship.remove_meta("respawn_at_msec")
	var protection_seconds := float(GameplayRuleset.rule_value(get_tree(), "respawn.protection_seconds", PLAYER_RESPAWN_PROTECTION_SECONDS))
	if ship.is_in_group("player"):
		ship.set_meta("respawn_protection_until", Time.get_ticks_msec() + roundi(protection_seconds * 1000.0))
	ship.stop_ship()
	health_changed.emit()
	ship_respawned.emit(ship)
	if ship.is_in_group("player"):
		M216ShipCombatFxScript.respawn_read(ship, protection_seconds)
		var hud := get_tree().get_first_node_in_group("hud") as GameHud
		if hud != null:
			hud.note_prioritized("ZURÜCK IM HAFEN · %.0f SEK. SCHUTZ" % protection_seconds, 9, "respawn", 5000)


func _set_collision(enabled: bool) -> void:
	var collision := ship.get_node_or_null("ShipCollision") as CollisionShape3D
	if collision != null:
		collision.set_deferred("disabled", not enabled)
