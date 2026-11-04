class_name GameState
extends Node

const SAVE_VERSION := 1
const SAVE_PATH := "user://seefight_save_v1.json"
const BACKUP_PATH := "user://seefight_save_v1.backup.json"

var player: ShipMotor
var world_map: WorldMapSystem
var save_path := SAVE_PATH
var backup_path := BACKUP_PATH
var transient_session := false
var _loaded_payload := {}
var _autosave_elapsed := 0.0
var _dirty := false
var load_failed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_state")
	var session := get_tree().get_first_node_in_group("local_session") as LocalSession
	if session != null:
		transient_session = session.guest or not session.active()
		if not transient_session:
			save_path = LocalProfileStore.save_path(session.profile)
			backup_path = save_path + ".backup"
	if transient_session:
		return
	if get_tree().root.get_meta("reconstruction_test_mode", false):
		return
	_loaded_payload = _read_valid_payload(save_path)
	if _loaded_payload.is_empty():
		_loaded_payload = _read_valid_payload(backup_path)
	load_failed = _loaded_payload.is_empty() and (FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path))


func _process(delta: float) -> void:
	if get_tree().paused or player == null:
		return
	_autosave_elapsed += delta
	if abs(player.current_speed) > 0.05:
		_dirty = true
	if _dirty and _autosave_elapsed >= 12.0:
		save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if player != null:
			save_now()


func bind(player_value: ShipMotor, world_map_value: WorldMapSystem) -> void:
	player = player_value
	world_map = world_map_value
	var progression := player.get_node("Progression") as PlayerProgression
	var missions := player.get_node("Missions") as MissionSystem
	var health := player.get_node("Health") as ShipHealth
	var weapons := player.get_node("Weapons") as ShipWeapons
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var tracked_quest := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	progression.progression_changed.connect(mark_dirty)
	missions.mission_changed.connect(mark_dirty)
	health.health_changed.connect(mark_dirty)
	weapons.loadout_changed.connect(mark_dirty)
	roster.roster_changed.connect(mark_dirty)
	if tracked_quest != null: tracked_quest.changed.connect(mark_dirty)
	(player.get_node("Voyage") as VoyageProgress).changed.connect(mark_dirty)
	(player.get_node("Inventory") as PlayerInventory).inventory_changed.connect(mark_dirty)
	var support_telemetry := player.get_node_or_null("SupportContribution") as SupportContributionTelemetry
	if support_telemetry != null: support_telemetry.changed.connect(mark_dirty)
	var special_pve_oracle := player.get_node_or_null("SpecialPveOracle") as M245SpecialPveOracleRuntime
	if special_pve_oracle != null: special_pve_oracle.changed.connect(mark_dirty)
	var achievement_collections := player.get_node_or_null("AchievementCollections") as M246AchievementCollectionRuntime
	if achievement_collections != null: achievement_collections.changed.connect(mark_dirty)
	var bazaar_trading := player.get_node_or_null("BazaarTrading") as M247BazaarTradingRuntime
	if bazaar_trading != null: bazaar_trading.changed.connect(mark_dirty)
	var social_runtime := player.get_node_or_null("SocialRuntime") as M248SocialRuntime
	if social_runtime != null: social_runtime.changed.connect(mark_dirty)
	var pvp_honor_ranked := player.get_node_or_null("PvpHonorRanked") as M249PvpHonorRankedRuntime
	if pvp_honor_ranked != null: pvp_honor_ranked.changed.connect(mark_dirty)
	var guild_governance := player.get_node_or_null("GuildGovernance") as M250GuildGovernanceRuntime
	if guild_governance != null: guild_governance.changed.connect(mark_dirty)
	var meta_progression := player.get_node_or_null("MetaProgression") as M251MetaProgressionRuntime
	if meta_progression != null: meta_progression.changed.connect(mark_dirty)
	world_map.sector_changed.connect(_on_sector_changed)
	world_map.encounters.encounter_changed.connect(mark_dirty)
	call_deferred("_apply_loaded_state")


func mark_dirty() -> void:
	_dirty = true


func save_now() -> bool:
	if load_failed: return false # Never overwrite unreadable profiles with a fresh game.
	if transient_session:
		return true
	if get_tree().root.get_meta("reconstruction_test_mode", false):
		return true
	if player == null or world_map == null:
		return false
	var health := player.get_node("Health") as ShipHealth
	var weapons := player.get_node("Weapons") as ShipWeapons
	var input_node := player.get_node("PlayerInput") as PlayerShipInput
	var progression := player.get_node("Progression") as PlayerProgression
	var missions := player.get_node("Missions") as MissionSystem
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var payload := {
		"save_version": SAVE_VERSION,
		"m31_version": 1,
		"m32_version": 1,
		"m77_beginner_progression_schema": BeginnerRules.BEGINNER_SAVE_VERSION,
		"voyage": (player.get_node("Voyage") as VoyageProgress).export_state(),
		"player": {
			"position": [player.position.x, player.position.y, player.position.z],
			"health": health.current_health,
			"shield": health.current_shield,
			"repair_charges": input_node.repair_charges,
			"cannon_index": weapons.cannon_index,
			"ammo_index": weapons.ammo_index,
			"weapon_mode": weapons.weapon_mode,
			"harpoon_payload_index": weapons.harpoon_payload_index,
			"support_ammo_index": weapons.support_ammo_index,
			"last_port": str(player.get_meta("last_port", "")),
		},
		"world":WorldSaveMigration.payload(world_map.current_stable_sector_id(),WorldSectorRegistry.coord_for_id(world_map.current_stable_sector_id())).merged({
			"local_position":[player.position.x,player.position.z],
			"content_version":(ServiceLocator.from(get_tree()).content.effective_version() if ServiceLocator.from(get_tree())!=null and ServiceLocator.from(get_tree()).content!=null else "local"),
			"poi_state":world_map.export_poi_state()
		}),
		"progression": progression.export_state(),
		"ship_roster": roster.export_state(),
		"inventory": (player.get_node("Inventory") as PlayerInventory).export_state(),
		"missions": missions.export_state(),
		"dynamic_quests":(player.get_node("DynamicQuestRuntime") as DynamicQuestRuntime).export_state() if player.has_node("DynamicQuestRuntime") else {},
		"quest_tracking":(player.get_node("TrackedQuestRuntime") as TrackedQuestRuntime).export_state() if player.has_node("TrackedQuestRuntime") else {},
		"support_telemetry": (player.get_node("SupportContribution") as SupportContributionTelemetry).export_state() if player.has_node("SupportContribution") else {},
		"m240_sustain_support": (player.get_node("SustainSupport") as M240SustainSupportRuntime).export_state() if player.has_node("SustainSupport") else {},
		"m241_crew_officers": (player.get_node("CrewOfficers") as M241CrewOfficerRuntime).export_state() if player.has_node("CrewOfficers") else {},
		"m242_officer_progression": (player.get_node("OfficerProgression") as M242OfficerProgressionRuntime).export_state() if player.has_node("OfficerProgression") else {},
		"m245_special_pve_oracle": (player.get_node("SpecialPveOracle") as M245SpecialPveOracleRuntime).export_state() if player.has_node("SpecialPveOracle") else {},
		"m246_achievement_collections": (player.get_node("AchievementCollections") as M246AchievementCollectionRuntime).export_state() if player.has_node("AchievementCollections") else {},
		"m247_bazaar_trading": (player.get_node("BazaarTrading") as M247BazaarTradingRuntime).export_state() if player.has_node("BazaarTrading") else {},
		"m248_social": (player.get_node("SocialRuntime") as M248SocialRuntime).export_state() if player.has_node("SocialRuntime") else {},
		"m249_pvp_honor_ranked": (player.get_node("PvpHonorRanked") as M249PvpHonorRankedRuntime).export_state() if player.has_node("PvpHonorRanked") else {},
		"m250_guild_governance": (player.get_node("GuildGovernance") as M250GuildGovernanceRuntime).export_state() if player.has_node("GuildGovernance") else {},
		"m251_meta_progression": (player.get_node("MetaProgression") as M251MetaProgressionRuntime).export_state() if player.has_node("MetaProgression") else {},
		"encounters": world_map.encounters.export_state(),
	}
	# Normalize JSON numeric types before hashing (JSON parses every number as float).
	payload = JSON.parse_string(JSON.stringify(payload))
	var payload_json := JSON.stringify(payload)
	var envelope := {"payload": payload, "checksum": payload_json.sha256_text()}
	var text := JSON.stringify(envelope, "  ")
	if not _read_valid_payload(save_path).is_empty():
		if not _write_text(backup_path, FileAccess.get_file_as_string(save_path)): return false
	var success := _write_text(save_path, text)
	if success:
		_dirty = false
		_autosave_elapsed = 0.0
	return success


func _apply_loaded_state() -> void:
	if player == null or world_map == null:
		return
	if _loaded_payload.is_empty():
		(player.get_node("ShipRoster") as PlayerShipRoster).choose_starter(BeginnerRules.START_SHIP)
		mark_dirty()
		return
	var progression := player.get_node("Progression") as PlayerProgression
	var missions := player.get_node("Missions") as MissionSystem
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	progression.import_state(_loaded_payload.get("progression", {}))
	# M78 migration order is intentional: roster first, voyage second.
	# Voyage may grandfather v1 beginner ship entitlements into the already-loaded roster.
	roster.import_state(_loaded_payload.get("ship_roster", {}))
	var voyage_state:Dictionary=_loaded_payload.get("voyage", {})
	(player.get_node("Voyage") as VoyageProgress).import_state(voyage_state, not _loaded_payload.has("m31_version"))
	var loaded_beginner_schema:=int(_loaded_payload.get("m77_beginner_progression_schema", voyage_state.get("beginner_version",0)))
	if loaded_beginner_schema<BeginnerRules.BEGINNER_SAVE_VERSION:
		mark_dirty() # Persist the reconciled local schema on the next safe save.
	missions.import_state(_loaded_payload.get("missions", {}))
	var dynamic_quests:=player.get_node_or_null("DynamicQuestRuntime") as DynamicQuestRuntime
	if dynamic_quests!=null and _loaded_payload.get("dynamic_quests",{}) is Dictionary:dynamic_quests.import_state(_loaded_payload.get("dynamic_quests",{}))
	var tracked_quest:=player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	if tracked_quest!=null and _loaded_payload.get("quest_tracking",{}) is Dictionary:tracked_quest.import_state(_loaded_payload.get("quest_tracking",{}))
	world_map.encounters.import_state(_loaded_payload.get("encounters", {}))
	var world_data:Dictionary=_loaded_payload.get("world",{})
	if world_data.get("poi_state",{}) is Dictionary:world_map.import_poi_state(world_data.get("poi_state",{}))
	var world_resolution:=WorldSaveMigration.resolve_sector_id(world_data)
	var stable_sector_id:=str(world_resolution.get("sector_id","SECTOR-001"))
	var restored:=world_map.restore_sector_id(stable_sector_id)
	if bool(world_resolution.get("migrated",false)):mark_dirty()
	if not restored:world_map.restore_sector_id("SECTOR-001")
	var player_data:Dictionary=_loaded_payload.get("player",{})
	var world_position:Variant=world_data.get("local_position",[])
	if world_position is Array and world_position.size()>=2:
		player.position=WorldSaveMigration.sanitize_local_position(world_position,world_map.sector_half_size())
	else:
		var position_data:Array=player_data.get("position",[0.0,0.55,0.0])
		if position_data.size()>=3:
			player.position=WorldSaveMigration.sanitize_local_position([position_data[0],position_data[2]],world_map.sector_half_size())
	var saved_content_version:=str(world_data.get("content_version",""))
	var services:=ServiceLocator.from(get_tree())
	if not saved_content_version.is_empty() and services!=null and services.content!=null and saved_content_version!=services.content.effective_version():
		player.set_meta("content_version_changed_since_save",true)
	var health := player.get_node("Health") as ShipHealth
	health.current_health = clamp(float(player_data.get("health", health.max_health)), 1.0, health.max_health)
	health.current_shield = clampf(float(player_data.get("shield", health.max_shield)), 0.0, health.max_shield)
	var input_node := player.get_node("PlayerInput") as PlayerShipInput
	input_node.repair_charges = clamp(int(player_data.get("repair_charges", 3)), 0, 3)
	if _loaded_payload.get("inventory") is Dictionary:
		(player.get_node("Inventory") as PlayerInventory).import_state(_loaded_payload.inventory)
	var weapons := player.get_node("Weapons") as ShipWeapons
	weapons.cannon_index = posmod(int(player_data.get("cannon_index", 1)), CombatCatalog.CANNONS.size())
	weapons.ammo_index = posmod(int(player_data.get("ammo_index", 0)), CombatCatalog.ammo_count())
	weapons.harpoon_payload_index = maxi(0, int(player_data.get("harpoon_payload_index", 0)))
	weapons.support_ammo_index = maxi(0, int(player_data.get("support_ammo_index", 0)))
	weapons.weapon_mode = str(player_data.get("weapon_mode", "cannon")) if player_data.get("weapon_mode", "cannon") in ["cannon", "harpoon", "support"] else "cannon"
	var support_telemetry := player.get_node_or_null("SupportContribution") as SupportContributionTelemetry
	if support_telemetry != null and _loaded_payload.get("support_telemetry", {}) is Dictionary:
		support_telemetry.import_state(_loaded_payload.get("support_telemetry", {}))
	var crew_officers := player.get_node_or_null("CrewOfficers") as M241CrewOfficerRuntime
	if crew_officers != null:
		if _loaded_payload.get("m241_crew_officers", {}) is Dictionary and not (_loaded_payload.get("m241_crew_officers", {}) as Dictionary).is_empty():
			crew_officers.import_state(_loaded_payload.get("m241_crew_officers", {}))
		elif _loaded_payload.get("m240_sustain_support", {}) is Dictionary:
			crew_officers.import_legacy_sustain_state(_loaded_payload.get("m240_sustain_support", {}))
			mark_dirty()
	var officer_progression := player.get_node_or_null("OfficerProgression") as M242OfficerProgressionRuntime
	if officer_progression != null and _loaded_payload.get("m242_officer_progression", {}) is Dictionary:
		officer_progression.import_state(_loaded_payload.get("m242_officer_progression", {}))
	var special_pve_oracle := player.get_node_or_null("SpecialPveOracle") as M245SpecialPveOracleRuntime
	if special_pve_oracle != null and _loaded_payload.get("m245_special_pve_oracle", {}) is Dictionary:
		special_pve_oracle.import_state(_loaded_payload.get("m245_special_pve_oracle", {}))
	var achievement_collections := player.get_node_or_null("AchievementCollections") as M246AchievementCollectionRuntime
	if achievement_collections != null and _loaded_payload.get("m246_achievement_collections", {}) is Dictionary:
		achievement_collections.import_state(_loaded_payload.get("m246_achievement_collections", {}))
	var bazaar_trading := player.get_node_or_null("BazaarTrading") as M247BazaarTradingRuntime
	if bazaar_trading != null and _loaded_payload.get("m247_bazaar_trading", {}) is Dictionary:
		bazaar_trading.import_state(_loaded_payload.get("m247_bazaar_trading", {}))
	var social_runtime := player.get_node_or_null("SocialRuntime") as M248SocialRuntime
	if social_runtime != null and _loaded_payload.get("m248_social", {}) is Dictionary:
		social_runtime.import_state(_loaded_payload.get("m248_social", {}))
	var pvp_honor_ranked := player.get_node_or_null("PvpHonorRanked") as M249PvpHonorRankedRuntime
	if pvp_honor_ranked != null and _loaded_payload.get("m249_pvp_honor_ranked", {}) is Dictionary:
		pvp_honor_ranked.import_state(_loaded_payload.get("m249_pvp_honor_ranked", {}))
	var guild_governance := player.get_node_or_null("GuildGovernance") as M250GuildGovernanceRuntime
	if guild_governance != null and _loaded_payload.get("m250_guild_governance", {}) is Dictionary:
		guild_governance.import_state(_loaded_payload.get("m250_guild_governance", {}))
	var meta_progression := player.get_node_or_null("MetaProgression") as M251MetaProgressionRuntime
	if meta_progression != null and _loaded_payload.get("m251_meta_progression", {}) is Dictionary:
		meta_progression.import_state(_loaded_payload.get("m251_meta_progression", {}))
	var sustain := player.get_node_or_null("SustainSupport") as M240SustainSupportRuntime
	if sustain != null and _loaded_payload.get("m240_sustain_support", {}) is Dictionary:
		sustain.import_state(_loaded_payload.get("m240_sustain_support", {}))
	var last_port := str(player_data.get("last_port", ""))
	player.set_meta("last_port", last_port)
	if not last_port.is_empty():
		call_deferred("_restore_checkpoint", last_port)
	_dirty = false


func _restore_checkpoint(port_name: String) -> void:
	for port in get_tree().get_nodes_in_group("ports"):
		if port.name != port_name:
			continue
		var spawn := port.get_node_or_null("SpawnPoint") as Marker3D
		var health := player.get_node("Health") as ShipHealth
		if spawn != null:
			health.respawn_position = spawn.global_position
		return


func _read_valid_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	var raw := FileAccess.get_file_as_string(path)
	var result := parser.parse(raw)
	var parsed = parser.data if result == OK else null
	if not parsed is Dictionary:
		return {}
	var envelope := parsed as Dictionary
	var payload = envelope.get("payload", {})
	if not payload is Dictionary:
		return {}
	var payload_dictionary := payload as Dictionary
	if int(payload_dictionary.get("save_version", -1)) != SAVE_VERSION:
		return {}
	if int(payload_dictionary.get("m31_version", 0)) > 1: return {}
	if int(payload_dictionary.get("m32_version", 0)) > 1: return {}
	var checksum := str(envelope.get("checksum", ""))
	if JSON.stringify(payload_dictionary).sha256_text() != checksum:
		# Legacy files hash ints before JSON readback. Verify original numeric spelling,
		# never accept a bad checksum by recomputing/replacing it.
		var original := _legacy_payload_json(raw)
		if original.is_empty() or original.sha256_text() != checksum: return {}
	return payload_dictionary


func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var success := file.get_error() == OK
	file.close()
	return success and DirAccess.rename_absolute(path + ".tmp", path) == OK

static func _legacy_payload_json(raw: String) -> String:
	var depth := 0
	var quoted := false
	var escaped := false
	var string_start := -1
	var pending := false
	var begin := -1
	var end := -1
	for i in raw.length():
		var c := raw[i]
		if quoted:
			if escaped: escaped = false
			elif c == "\\": escaped = true
			elif c == "\"":
				quoted = false
				if depth == 1 and raw.substr(string_start + 1, i - string_start - 1) == "payload":
					var tail := raw.substr(i + 1).strip_edges()
					pending = tail.begins_with(":")
			continue
		if c == "\"": quoted = true; string_start = i
		elif c == "{" or c == "[":
			depth += 1
			if pending and depth == 2:
				begin = i
				pending = false
		elif c == "}" or c == "]":
			depth -= 1
			if begin >= 0 and depth == 1: end = i + 1; break
	if begin < 0 or end <= begin: return ""
	var compact := ""
	quoted = false
	escaped = false
	for c in raw.substr(begin, end - begin):
		if quoted:
			compact += c
			if escaped: escaped = false
			elif c == "\\": escaped = true
			elif c == "\"": quoted = false
		elif c == "\"": quoted = true; compact += c
		elif c not in [" ", "\t", "\r", "\n"]: compact += c
	return compact


func _on_sector_changed(_previous: Vector2i, _current: Vector2i, _direction: Vector2i) -> void:
	mark_dirty()
	save_now()
