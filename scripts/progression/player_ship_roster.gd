class_name PlayerShipRoster
extends Node

signal roster_changed
signal ship_mastery_leveled(ship_id: String, level: int)
signal progression_ship_awarded(ship_id: String, defeated_map_level: int)

var owned_ship_ids: Array[String] = [BeginnerRules.START_SHIP]
var selected_ship_id := BeginnerRules.START_SHIP
var preview_index := 0
var preview_ship_id := BeginnerRules.START_SHIP
var eligible_main_ship_ids: Array[String] = []
var reward_history: Array[Dictionary] = []
var designs: Dictionary = {}
var starter_chosen := false

@onready var ship: ShipMotor = get_parent() as ShipMotor
@onready var health: ShipHealth = get_parent().get_node("Health") as ShipHealth
@onready var progression: PlayerProgression = get_parent().get_node("Progression") as PlayerProgression
@onready var visual_adapter: ReferenceVisualAdapter = get_parent().get_node("ReferenceVisualAdapter") as ReferenceVisualAdapter


func _ready() -> void:
	preview_index = ShipCatalog.index_of(selected_ship_id)
	preview_ship_id = selected_ship_id
	_refresh_eligibility()
	_apply_selected_ship(true)


func preview_ship_ids() -> Array[String]:
	var ids: Array[String] = []
	for profile in ShipCatalog.SHIPS:
		var id := str(profile.id)
		if not ids.has(id): ids.append(id)
	var tree:=get_tree()
	for profile in DynamicContentResolver.active_records(tree,"ship"):
		var dynamic_id:=str(profile.get("id",""))
		if not dynamic_id.is_empty() and not ids.has(dynamic_id):ids.append(dynamic_id)
	for id in owned_ship_ids:
		if not ids.has(id): ids.append(id)
	for id in eligible_main_ship_ids:
		if not ids.has(id): ids.append(id)
	return ids

func preview_ship() -> Dictionary:
	if not ShipCatalog.has_ship(preview_ship_id):
		preview_ship_id = selected_ship_id
	return ShipCatalog.profile_by_id(preview_ship_id)

func preview_previous() -> void:
	if not progression.shop_open: return
	var ids := preview_ship_ids()
	if ids.is_empty(): return
	var index := maxi(0, ids.find(preview_ship_id))
	preview_ship_id = ids[posmod(index - 1, ids.size())]
	roster_changed.emit()

func preview_next() -> void:
	if not progression.shop_open: return
	var ids := preview_ship_ids()
	if ids.is_empty(): return
	var index := maxi(0, ids.find(preview_ship_id))
	preview_ship_id = ids[posmod(index + 1, ids.size())]
	roster_changed.emit()


func buy_or_equip_preview() -> bool:
	if not progression.shop_open:
		return false
	var profile := preview_ship()
	var ship_id := str(profile.id)
	if health.is_sunk: return false
	if not owns_ship(ship_id):
		var locked_message := acquisition_message(ship_id)
		ship.set_meta("dock_message", locked_message)
		ship.set_meta("dock_message_until", Time.get_ticks_msec() / 1000.0 + 3.0)
		return false # Unowned starter/main designs are reward-only; preview never purchases them.
	capture_active()
	selected_ship_id = ship_id
	_apply_selected_ship(false)
	roster_changed.emit()
	return true


func owns_ship(ship_id: String) -> bool:
	return owned_ship_ids.has(ship_id)


func selected_ship() -> Dictionary:
	return ShipCatalog.profile_by_id(selected_ship_id)


func acquisition_class(ship_id: String) -> String:
	var dynamic:=DynamicContentResolver.by_id(get_tree(),"ship",ship_id)
	if not dynamic.is_empty():return str(dynamic.get("acquisition","admin_defined"))
	if ship_id == BeginnerRules.START_SHIP or BeginnerRules.SHIP_REWARDS.values().has(ship_id):
		return "beginner_reward"
	if ship_id.begins_with("ship_main_"):
		return "main_progression_reward"
	return "owned_or_external"


func acquisition_message(ship_id: String) -> String:
	match acquisition_class(ship_id):
		"beginner_reward":
			return BeginnerRules.unlock_text(ship_id)
		"main_progression_reward":
			if eligible_main_ship_ids.has(ship_id):
				return "NICHT KAUFBAR · Design über vorgesehenen Kampf-/Progressions-Meilenstein erspielen"
			var req := int(MainProgressionFleet.design(ship_id).get("unlock",{}).get("map_level",999))
			return "GESPERRT · Kartenlevel %d · danach erspielen, nicht kaufen" % req
		"shop":
			var profile:=ShipCatalog.profile_by_id(ship_id);return "SHOP · %d Gold"%int(profile.get("price",0))
		"quest","event","trial","admin_defined":
			var profile:=ShipCatalog.profile_by_id(ship_id);return str((profile.get("unlock",{}) as Dictionary).get("hint","Über konfigurierten Erwerbsweg freischalten"))
		_:
			return "NICHT VERFÜGBAR"


func record_local_migration(source: String, ship_id: String, stage: int = -1) -> void:
	for row in reward_history:
		if str(row.get("source","")) == source and str(row.get("ship_id","")) == ship_id:
			return
	reward_history.append({
		"type":"local_save_migration",
		"ship_id":ship_id,
		"source":source,
		"stage":stage,
		"local_sequence":reward_history.size()+1,
		"migrated":true,
	})


func preview_status() -> String:
	var profile := preview_ship()
	var ship_id := str(profile.id)
	if selected_ship_id == ship_id: return "AKTIV"
	if owns_ship(ship_id): return "AUSRÜSTEN"
	return acquisition_message(ship_id)


func export_state() -> Dictionary:
	capture_active()
	return {
		"owned_ship_ids": owned_ship_ids.duplicate(),
		"selected_ship_id": selected_ship_id,
		"preview_ship_id": preview_ship_id,
		"eligible_main_ship_ids": eligible_main_ship_ids.duplicate(),
		"reward_history": reward_history.duplicate(true),
		"designs": designs.duplicate(true),
	}


func import_state(data: Dictionary) -> void:
	starter_chosen = true
	owned_ship_ids.clear()
	var saved_owned: Array = data.get("owned_ship_ids", [BeginnerRules.START_SHIP]) if data.get("owned_ship_ids", []) is Array else [BeginnerRules.START_SHIP]
	for value in saved_owned:
		var ship_id := str(value)
		if ShipCatalog.has_ship(ship_id) and not owned_ship_ids.has(ship_id):
			owned_ship_ids.append(ship_id)
	if not owned_ship_ids.has(BeginnerRules.START_SHIP): owned_ship_ids.append(BeginnerRules.START_SHIP)
	var saved_selected := str(data.get("selected_ship_id", BeginnerRules.START_SHIP))
	selected_ship_id = saved_selected if owned_ship_ids.has(saved_selected) else owned_ship_ids[0]
	preview_ship_id = str(data.get("preview_ship_id", selected_ship_id))
	reward_history.clear()
	var saved_history: Variant = data.get("reward_history", [])
	if saved_history is Array:
		for row in saved_history:
			if row is Dictionary:
				reward_history.append((row as Dictionary).duplicate(true))
	_migrate_legacy_reward_history()
	designs.clear()
	var saved: Variant = data.get("designs", {})
	for id in owned_ship_ids:
		var record: Variant = saved.get(id, {}) if saved is Dictionary else {}
		var entry := _record(id)
		if record is Dictionary:
			entry.level = VoyageProgress.safe_int(record.get("level", 1), 1, ShipMasteryCatalog.max_level())
			entry.xp = VoyageProgress.safe_int(record.get("xp", 0), 0, maxi(0, ShipMasteryCatalog.xp_to_next(int(entry.level)) - 1))
			if entry.level >= ShipMasteryCatalog.max_level(): entry.xp = 0
			var upgrades: Variant = record.get("upgrades", progression.upgrades if id == selected_ship_id and not data.has("designs") else {})
			for key in PlayerProgression.UPGRADE_KEYS:
				entry.upgrades[key] = VoyageProgress.safe_int(upgrades.get(key, 0), 0, 10) if upgrades is Dictionary else 0
	preview_index = ShipCatalog.index_of(selected_ship_id)
	_refresh_eligibility()
	if not preview_ship_ids().has(preview_ship_id): preview_ship_id = selected_ship_id
	_apply_selected_ship(false)
	roster_changed.emit()


func _apply_selected_ship(initial: bool) -> void:
	var profile := selected_ship()
	var record := _record(selected_ship_id)
	progression.upgrades = record.upgrades.duplicate()
	var health_ratio := 1.0 if initial else health.normalized()
	ship.set_meta("visual_profile", selected_ship_id)
	ship.name = "PLAYER • %s" % str(profile.display_name).to_upper()
	ship.acceleration = float(profile.acceleration)
	ship.turn_speed_degrees = float(profile.turn_speed)
	health.armor = float(profile.armor)
	var bonus := 1.0 + (int(record.level) - 1) * 0.02
	progression.set_ship_base_stats(float(profile.hull) * bonus, float(profile.damage) * bonus, float(profile.speed))
	health.current_health = clamp(health.max_health * health_ratio, 1.0, health.max_health)
	visual_adapter.apply_profile(selected_ship_id)
	var production_slot:=ProceduralShipSilhouetteAdapter.production_slot_for_gameplay_ship(selected_ship_id)
	if not production_slot.is_empty():ProceduralShipSilhouetteAdapter.apply(ship,production_slot)
	ship.set_meta("dock_message", "%s EQUIPPED" % str(profile.display_name).to_upper())
	ship.set_meta("dock_message_until", Time.get_ticks_msec() / 1000.0 + 2.2)

func _record(id: String) -> Dictionary:
	if not designs.has(id): designs[id] = {"level": 1, "xp": 0, "upgrades": {"hull": 0, "cannon": 0, "sails": 0}}
	return designs[id]

func capture_active() -> void:
	_record(selected_ship_id).upgrades = progression.upgrades.duplicate()

func ship_level() -> int:
	return int(_record(selected_ship_id).level)

func earn_ship_xp(amount: int) -> void:
	if amount <= 0: return
	capture_active()
	var record := _record(selected_ship_id)
	if int(record.level) >= ShipMasteryCatalog.max_level(): return
	record.xp += amount
	var leveled := false
	while int(record.level) < ShipMasteryCatalog.max_level() and int(record.xp) >= ShipMasteryCatalog.xp_to_next(int(record.level)):
		record.xp -= ShipMasteryCatalog.xp_to_next(int(record.level))
		record.level += 1
		ship_mastery_leveled.emit(selected_ship_id, int(record.level))
		leveled = true
	if int(record.level) >= ShipMasteryCatalog.max_level(): record.xp = 0
	if leveled: _apply_selected_ship(false)
	roster_changed.emit()



func mastery_record(ship_id: String) -> Dictionary:
	if not ShipCatalog.has_ship(ship_id):
		return {}
	return _record(ship_id).duplicate(true)


func mastery_level(ship_id: String) -> int:
	return int(_record(ship_id).get("level", 1)) if ShipCatalog.has_ship(ship_id) else 1


func mastery_xp(ship_id: String) -> int:
	return int(_record(ship_id).get("xp", 0)) if ShipCatalog.has_ship(ship_id) else 0


func mastery_progress(ship_id: String) -> float:
	var level := mastery_level(ship_id)
	return ShipMasteryCatalog.progress(level, mastery_xp(ship_id))


func equip_owned_ship(ship_id: String) -> bool:
	if not owns_ship(ship_id) or health.is_sunk:
		return false
	capture_active()
	selected_ship_id = ship_id
	preview_ship_id = ship_id
	preview_index = ShipCatalog.index_of(ship_id)
	_apply_selected_ship(false)
	roster_changed.emit()
	return true

func unlock_main_progression_for_map_level(map_level: int) -> void:
	# Compatibility entry point: M55 no longer grants ownership from map level.
	var before := eligible_main_ship_ids.duplicate()
	eligible_main_ship_ids = MainProgressionFleet.eligible_designs(map_level)
	if before != eligible_main_ship_ids:
		roster_changed.emit()

func _refresh_eligibility() -> void:
	var voyage := ship.get_node_or_null("Voyage") as VoyageProgress
	var level := voyage.map_level() if voyage != null else BeginnerRules.ELITE_MAP_LEVEL
	eligible_main_ship_ids = MainProgressionFleet.eligible_designs(level)

func is_main_design_eligible(ship_id: String) -> bool:
	return eligible_main_ship_ids.has(ship_id)

func award_ship(ship_id: String, emit_change: bool = true) -> bool:
	if not ShipCatalog.has_ship(ship_id) or owns_ship(ship_id):
		return false
	if ship_id.begins_with("ship_main_") and not eligible_main_ship_ids.has(ship_id):
		return false
	owned_ship_ids.append(ship_id)
	_record(ship_id)
	if emit_change: roster_changed.emit()
	return true

func award_boss_progression_ship(defeated_map_level: int) -> String:
	var reward := MainShipRewardCatalog.reward_for_boss(defeated_map_level)
	var id := str(reward.get("ship_id",""))
	if id.is_empty(): return ""
	_refresh_eligibility()
	if not award_ship(id, false): return ""
	reward_history.append({
		"type":"main_design_reward",
		"ship_id":id,
		"source":"boss_progression",
		"defeated_map_level":defeated_map_level,
		"label":str(reward.get("label","")),
		"local_sequence":reward_history.size() + 1,
	})
	progression_ship_awarded.emit(id, defeated_map_level)
	roster_changed.emit()
	return id

func _migrate_legacy_reward_history() -> void:
	# Older local saves could own a progression design before M56 reward history existed.
	# This migration records provenance as LEGACY only; it is not a reconstructed server audit.
	for row in MainShipRewardCatalog.data().get("boss_rewards", []):
		var id := str(row.get("ship_id",""))
		if id.is_empty() or not owns_ship(id) or has_reward_history_for_ship(id):
			continue
		reward_history.append({
			"type":"main_design_reward",
			"ship_id":id,
			"source":"legacy_owned_migration",
			"defeated_map_level":int(row.get("defeated_map_level",-1)),
			"label":str(row.get("label","")),
			"local_sequence":reward_history.size() + 1,
			"migrated":true,
		})

func reward_history_rows() -> Array[Dictionary]:
	return reward_history.duplicate(true)

func has_reward_history_for_ship(ship_id: String) -> bool:
	for row in reward_history:
		if str(row.get("ship_id","")) == ship_id:
			return true
	return false


func choose_starter(id: String) -> bool:
	if starter_chosen or id != BeginnerRules.START_SHIP: return false
	starter_chosen = true
	owned_ship_ids.assign([id])
	selected_ship_id = id
	designs.clear()
	preview_index = ShipCatalog.index_of(id)
	preview_ship_id = id
	_apply_selected_ship(true)
	roster_changed.emit()
	return true

func unlock_earned_starters() -> void:
	var voyage := ship.get_node_or_null("Voyage") as VoyageProgress
	if voyage == null: return
	var added := false
	for stage in BeginnerRules.SHIP_REWARDS:
		var id: String = BeginnerRules.SHIP_REWARDS[stage]
		if voyage.completed_trials >= int(stage) and not owns_ship(id):
			owned_ship_ids.append(id)
			_record(id)
			added = true
	if added: roster_changed.emit()
