class_name ShipWeapons
extends Node

signal loadout_changed
signal presentation_salvo_fired(mode: String, target: ShipMotor)

const ProjectileScript = preload("res://scripts/gameplay/cannon_projectile.gd")
const MuzzleFlashScript = preload("res://scripts/visual/muzzle_flash.gd")
const CANNON_AUDIO := "res://assets/recovered_test/m8/audio/Blast-Test-10-4-23__570.wav"

@export var reload_seconds := 1.15
@export var projectile_speed := 18.0
@export var damage := 72.0

var last_shot_time := -99.0
var cannon_index := 1
var ammo_index := 0
var auto_fire := false
var weapon_mode := "cannon"
var harpoon_payload_index := 0
var support_ammo_index := 0
var support_target: ShipMotor = null
var last_reload_duration := 1.15


func selected_target() -> ShipMotor:
	var targeting := get_parent().get_node_or_null("Targeting") as TargetingSystem
	return targeting.target if targeting != null and targeting.valid_hostile(targeting.target) else null

func selected_support_target() -> ShipMotor:
	var ship := get_parent() as ShipMotor
	if support_target != null and is_instance_valid(support_target):
		var h := support_target.get_node_or_null("Health") as ShipHealth
		if h != null and not h.is_sunk and (support_target == ship or support_target.is_in_group("support_allies")):
			return support_target
	support_target = ship
	return ship

func cycle_support_target() -> ShipMotor:
	var ship := get_parent() as ShipMotor
	var candidates: Array[ShipMotor] = [ship]
	for value in get_tree().get_nodes_in_group("support_allies"):
		var candidate := value as ShipMotor
		if candidate != null and candidate != ship:
			var h := candidate.get_node_or_null("Health") as ShipHealth
			if h != null and not h.is_sunk: candidates.append(candidate)
	var current := candidates.find(selected_support_target())
	support_target = candidates[(current + 1) % candidates.size()]
	loadout_changed.emit()
	return support_target


func _support_missing_score(candidate: ShipMotor) -> float:
	var h := candidate.get_node_or_null("Health") as ShipHealth
	if h == null or h.is_sunk:
		return -1.0
	var hull_missing := maxf(0.0, h.max_health - h.current_health)
	var shield_missing := maxf(0.0, h.max_shield - h.current_shield)
	return hull_missing + shield_missing



func effective_range() -> float:
	if weapon_mode == "harpoon":
		var hrows:=SupportPayloadCatalog.harpoon_payloads()
		var hrow:Dictionary=hrows[harpoon_payload_index % hrows.size()] if not hrows.is_empty() else {}
		return 30.0 * float(hrow.get("range_mult",1.0))
	if weapon_mode == "support":
		var rows := SupportPayloadCatalog.support_ammo()
		var row: Dictionary = rows[support_ammo_index % rows.size()] if not rows.is_empty() else {}
		return float(row.get("range", 26.0))
	# Real projectile lifetime is 3 seconds; reserve time for muzzle offsets.
	var cannon := CombatCatalog.cannon(cannon_index).duplicate(true)
	var ammo := CombatCatalog.ammo(ammo_index).duplicate(true)
	var range_mult:=1.0
	if get_parent().is_in_group("player"):
		var mods:=M158CannonRuntime.modifiers(cannon,_cannon_upgrade_level(),str(ammo.get("id","")))
		range_mult=float(mods.get("range_mult",1.0))
	return maxf(1, projectile_speed * float(cannon.speed) * float(cannon.range) * float(ammo.range) * range_mult * 2.6 - 3.0)


func attack_status() -> String:
	var ship := get_parent() as ShipMotor
	var health := ship.get_node_or_null("Health") as ShipHealth
	if health == null or health.is_sunk: return "GESPERRT"
	if _player_modal_open(ship): return "MENÜ OFFEN"
	if ship.get_meta("in_safe_zone", false): return "HAFENSCHUTZ"
	var progression := ship.get_node_or_null("Progression") as PlayerProgression
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if (ship.get_meta("inventory_open", false) or ship.get_meta("journal_open", false) or ship.get_meta("external_panel_open", false)) or (progression != null and progression.shop_open) or (hud != null and hud.global_map_open): return "MENÜ OFFEN"
	if weapon_mode == "support":
		var friend := selected_support_target()
		if friend == null: return "KEIN VERBÜNDETER"
		if ship.global_position.distance_to(friend.global_position) > effective_range(): return "ZU WEIT"
		var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
		if inventory != null and inventory.count(ammo_id()) <= 0: return "MUNITION LEER"
		if reload_progress() < 1: return "LÄDT NACH"
		return "BEREIT"
	var enemy := selected_target()
	if enemy == null: return "KEIN ZIEL"
	var monster: bool = enemy.get_meta("encounter_kind", "ship") == "monster"
	if (weapon_mode == "harpoon") != monster: return "HARPUNE WÄHLEN" if monster else "KANONE WÄHLEN"
	if enemy.get_meta("in_safe_zone", false): return "ZIEL GESCHÜTZT"
	var offset := enemy.global_position - ship.global_position
	offset.y = 0
	if offset.length() > effective_range(): return "ZU WEIT"
	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	if inventory != null and inventory.count(ammo_id()) < (1 if weapon_mode == "harpoon" else inventory.volley_size()): return "MUNITION LEER"
	if reload_progress() < 1: return "LÄDT NACH"
	return "BEREIT"


func toggle_auto_fire() -> void:
	if auto_fire:
		auto_fire = false
		return
	var voyage := get_parent().get_node_or_null("Voyage") as VoyageProgress
	if voyage != null and not voyage.auto_unlocked(): return
	var status := attack_status()
	auto_fire = status in ["BEREIT", "LÄDT NACH", "ZU WEIT"]


func _process(_delta: float) -> void:
	if not auto_fire: return
	var status := attack_status()
	if status == "BEREIT":
		fire_broadside(true)
	elif status != "LÄDT NACH" and status != "ZU WEIT":
		auto_fire = false


func reload_progress() -> float:
	return clamp((Time.get_ticks_msec() / 1000.0 - last_shot_time) / maxf(0.05, last_reload_duration), 0.0, 1.0)


func cannon_name() -> String:
	if weapon_mode == "harpoon": return "Jagdharpune"
	if weapon_mode == "support": return "Support Cannon"
	return CombatCatalog.cannon(cannon_index).name


func ammo_name() -> String:
	if weapon_mode == "harpoon":
		var rows := SupportPayloadCatalog.harpoon_payloads()
		return str(rows[harpoon_payload_index % rows.size()].get("label", "Harpoon")) if not rows.is_empty() else "Harpunen"
	if weapon_mode == "support":
		var rows := SupportPayloadCatalog.support_ammo()
		return str(rows[support_ammo_index % rows.size()].get("label", "Support")) if not rows.is_empty() else "Support"
	return CombatCatalog.ammo(ammo_index).name


func combat_summary() -> String:
	var cannon := CombatCatalog.cannon(cannon_index)
	var ammo := CombatCatalog.ammo(ammo_index)
	return "%s · %s · %.0fm" % [cannon.name, ammo.name, effective_range()]


func target_distance_ratio() -> float:
	var enemy := selected_target()
	if enemy == null:
		return 0.0
	return get_parent().global_position.distance_to(enemy.global_position) / maxf(1.0, effective_range())

func cycle_cannon() -> void:
	cannon_index = (cannon_index + 1) % CombatCatalog.cannon_count()
	loadout_changed.emit()


func cycle_ammo() -> void:
	ammo_index = (ammo_index + 1) % CombatCatalog.ammo_count()
	loadout_changed.emit()


func fire_broadside(aim_at_selection: bool = false) -> bool:
	if get_parent().is_in_group("player"):
		aim_at_selection = true
	if Time.get_ticks_msec() < int(get_parent().get_meta("ui_action_guard_until", 0)):
		return false
	if aim_at_selection and attack_status() != "BEREIT":
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if weapon_mode == "support":
		return _fire_support(now)
	var cannon := CombatCatalog.cannon(cannon_index).duplicate(true)
	var ammo := CombatCatalog.ammo(ammo_index).duplicate(true)
	if weapon_mode == "harpoon":
		cannon = {"speed": 1.3, "reload": 1.7, "damage": 1.8}
		var payload_rows := SupportPayloadCatalog.harpoon_payloads()
		var payload: Dictionary = payload_rows[harpoon_payload_index % payload_rows.size()] if not payload_rows.is_empty() else {}
		var effect := str(payload.get("effect", "none"))
		var status_effect := str(payload.get("status_effect", effect))
		ammo = {"id": str(payload.get("id", "harpoon")), "color": Color(str(payload.get("color","76e7c5"))),
			"crit": float(payload.get("crit",0.05)), "damage": float(payload.get("damage_mult",1.0)),
			"armor_pierce": float(payload.get("armor_pierce",0.12)),
			"slow": float(payload.get("slow",0.0)), "range": float(payload.get("range_mult",1.0)),
			"effect": status_effect, "effect_power": float(payload.get("effect_power",0.0)), "effect_duration": float(payload.get("effect_duration",0.0))}
		cannon.reload *= float(payload.get("reload_mult",1.0))
	if weapon_mode=="cannon" and get_parent().is_in_group("player"):
		var m158_mods:=M158CannonRuntime.modifiers(cannon,_cannon_upgrade_level(),str(ammo.get("id","")))
		cannon.damage*=float(m158_mods.get("damage_mult",1.0))*float(m158_mods.get("ammo_mult",1.0))
		cannon.reload*=float(m158_mods.get("reload_mult",1.0))
	var module_inventory := get_parent().get_node_or_null("Inventory") as PlayerInventory
	var build_cannon_mult:=float(get_parent().get_meta("build_cannon_damage_mult",1.0))*clampf(float(get_parent().get_meta("ancient_cannon_damage_mult",1.0)),1.0,1.12)
	var build_harpoon_mult:=float(get_parent().get_meta("build_harpoon_damage_mult",1.0))*clampf(float(get_parent().get_meta("ancient_harpoon_damage_mult",1.0)),1.0,1.16)
	if weapon_mode=="harpoon":cannon.damage*=build_harpoon_mult
	elif weapon_mode=="cannon":cannon.damage*=build_cannon_mult
	if module_inventory != null:
		cannon.damage *= module_inventory.m162_multiplier("harpoon_damage_pct" if weapon_mode == "harpoon" else "cannon_damage_pct")
		cannon.reload /= module_inventory.m162_multiplier("reload_pct")
		if weapon_mode == "harpoon":
			cannon.damage *= module_inventory.module_modifier("harpoon_damage_mult", 1.0)
			cannon.reload *= module_inventory.module_modifier("harpoon_reload_mult", 1.0)
		else:
			cannon.damage *= module_inventory.module_modifier("cannon_damage_mult", 1.0)
			cannon.reload *= module_inventory.module_modifier("cannon_reload_mult", 1.0)
	if reload_progress() < 1.0:
		return false
	var ship := get_parent() as ShipMotor
	if ship == null:
		return false
	var health := ship.get_node_or_null("Health") as ShipHealth
	if (health != null and health.is_sunk) or ship.get_meta("in_safe_zone", false) or _player_modal_open(ship):
		return false
	if ship.is_in_group("player"):
		var progression := ship.get_node("Progression") as PlayerProgression
		var hud_nodes := get_tree().get_nodes_in_group("hud")
		if progression.shop_open or (not hud_nodes.is_empty() and hud_nodes[0].global_map_open):
			return false
		if Time.get_ticks_msec() < int(ship.get_meta("respawn_protection_until", 0)):
			ship.set_meta("respawn_protection_until", 0)
			var protection_hud := get_tree().get_first_node_in_group("hud") as GameHud
			if protection_hud != null:
				protection_hud.note_prioritized("RESPAWN-SCHUTZ BEENDET · ANGRIFF AUSGEFÜHRT", 6, "combat", 2600)
	var direction := _best_broadside_direction(ship)
	var origins := _broadside_origins(ship, direction)
	if weapon_mode == "harpoon": origins.assign([ship.global_position + Vector3.UP * 0.3])
	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	var supply_damage_multiplier := 1.0
	if inventory != null:
		if not inventory.consume(ammo_id(), origins.size()):
			ship.set_meta("dock_message", "NOT ENOUGH AMMO — RESUPPLY AT HARBOR")
			ship.set_meta("dock_message_until", now + 2.2)
			return false
		if weapon_mode == "cannon": supply_damage_multiplier = inventory.consume_powder_for_salvo()
	if ship.get_meta("veil_active", false):
		ship.set_meta("veil_active", false)
		ship.set_meta("veil_until", 0.0)
	last_shot_time = now
	var reload_debuff:=float(ship.get_meta("weapon_reload_debuff_power",0.0)) if now<float(ship.get_meta("weapon_reload_debuff_until",0.0)) else 0.0
	last_reload_duration = reload_seconds * float(cannon.reload) * (1.0 + clampf(reload_debuff,0.0,0.6))
	_play_cannon_audio(ship)
	var settings := ClientSettings.current(get_tree())
	var reduced := settings != null and bool(settings.values.single_visual_ball)
	for index in origins.size():
		var spread := float(index) - float(origins.size() - 1) * 0.5
		var show_visual := not reduced or index == int(origins.size() / 2)
		var shot_direction := direction
		if aim_at_selection:
			var aim := selected_target().global_position
			aim.y = origins[index].y
			shot_direction = (aim - origins[index]).normalized()
		_spawn_projectile(ship, origins[index], shot_direction.rotated(Vector3.UP, deg_to_rad(spread * 1.5)), cannon, ammo, show_visual, supply_damage_multiplier)
	presentation_salvo_fired.emit(weapon_mode, selected_target())
	return true

func _cannon_upgrade_level()->int:
	var progression:=get_parent().get_node_or_null("Progression") as PlayerProgression
	if progression==null:return 0
	return int(progression.upgrades.get("cannon",0))

func ammo_id() -> String:
	if weapon_mode == "harpoon":
		var rows := SupportPayloadCatalog.harpoon_payloads()
		return str(rows[harpoon_payload_index % rows.size()].get("id", "hunter_standard")) if not rows.is_empty() else "harpoon"
	if weapon_mode == "support":
		var rows := SupportPayloadCatalog.support_ammo()
		return str(rows[support_ammo_index % rows.size()].get("id", "restoration_shell")) if not rows.is_empty() else "restoration_shell"
	return CombatCatalog.ammo_id(ammo_index)

func select_mode(mode: String) -> void:
	if mode not in ["cannon", "harpoon", "support"]: return
	weapon_mode = mode
	auto_fire = false
	loadout_changed.emit()



func select_harpoon_payload(id: String) -> bool:
	var rows := SupportPayloadCatalog.harpoon_payloads()
	for i in rows.size():
		if str(rows[i].get("id", "")) == id:
			harpoon_payload_index = i
			select_mode("harpoon")
			loadout_changed.emit()
			return true
	return false


func select_support_ammo(id: String) -> bool:
	var rows := SupportPayloadCatalog.support_ammo()
	for i in rows.size():
		if str(rows[i].get("id", "")) == id:
			support_ammo_index = i
			select_mode("support")
			loadout_changed.emit()
			return true
	return false


func _fire_support(now: float) -> bool:
	# Historical M176 regression tokens (superseded by data-driven M240): health.repair(180.0 * heal_mult, ship, "heal"); health.restore_shield(150.0 * heal_mult, ship)
	var ship := get_parent() as ShipMotor
	if ship == null or reload_progress() < 1.0:
		return false
	var target := selected_support_target()
	if target == null or ship.global_position.distance_to(target.global_position) > effective_range():
		return false
	var rows := SupportPayloadCatalog.support_ammo()
	if rows.is_empty():
		return false
	var definition: Dictionary = rows[support_ammo_index % rows.size()]
	var id := str(definition.get("id", "restoration_shell"))
	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	if inventory == null or not inventory.consume(id, 1):
		return false
	var health := target.get_node_or_null("Health") as ShipHealth
	if health == null or health.is_sunk:
		return false
	var heal_mult := inventory.module_modifier("support_heal_mult", 1.0)
	var applied := 0.0
	var hull_applied := 0.0
	var shield_applied := 0.0
	var contribution_kind := "hull"
	match str(definition.get("effect", "")):
		"hull_heal":
			hull_applied = health.repair(float(definition.get("heal_power", 0.0)) * heal_mult, ship, "heal")
			applied = hull_applied
		"shield_restore":
			contribution_kind = "shield"
			shield_applied = health.restore_shield(float(definition.get("shield_power", 0.0)) * heal_mult, ship)
			applied = shield_applied
		"hybrid_heal":
			hull_applied = health.repair(float(definition.get("hull_power", 0.0)) * heal_mult, ship, "heal")
			shield_applied = health.restore_shield(float(definition.get("shield_power", 0.0)) * heal_mult, ship)
			applied = hull_applied + shield_applied
			contribution_kind = "hybrid"
		"event_support":
			if target.get_meta("event_participant", false):
				applied = health.repair(float(definition.get("heal_power", 0.0)) * heal_mult, ship, "heal")
	if applied <= 0.0:
		inventory.set_count(id, inventory.count(id) + 1)
		return false
	last_shot_time = now
	last_reload_duration = reload_seconds * float(definition.get("reload_mult", 1.45)) * inventory.module_modifier("support_reload_mult", 1.0)
	var telemetry := ship.get_node_or_null("SupportContribution") as SupportContributionTelemetry
	if telemetry != null:
		if contribution_kind == "hybrid":
			telemetry.record_support("hull", hull_applied, target)
			telemetry.record_support("shield", shield_applied, target)
		else:
			telemetry.record_support(contribution_kind, applied, target)
	CombatVfx.action(get_tree(), "heal_impact" if id != "ward_shell" else "shield_heal_impact", target.global_position)
	loadout_changed.emit()
	presentation_salvo_fired.emit("support", target)
	return true

func _player_modal_open(ship: ShipMotor) -> bool:
	for key in ["inventory_open", "journal_open", "admin_panel_open", "meta_panel_open", "settings_open", "command_open", "external_panel_open"]:
		if bool(ship.get_meta(key, false)):
			return true
	return false


func _broadside_origins(ship: ShipMotor, direction: Vector3) -> Array[Vector3]:
	var origins: Array[Vector3] = []
	var right := ship.global_transform.basis.x.normalized()
	var side := "Starboard" if direction.dot(right) >= 0.0 else "Port"
	var sockets := ship.get_node_or_null("Sockets") as Node3D
	if sockets != null:
		for child in sockets.get_children():
			if child is Marker3D and str(child.name).begins_with("Cannon%s" % side):
				origins.append(child.global_position)
	if origins.is_empty():
		for index in range(-1, 2):
			origins.append(ship.global_position + direction * 1.75 + ship.global_transform.basis.z * index * 1.15 + Vector3.UP * 0.3)
	var inventory := ship.get_node_or_null("Inventory") as PlayerInventory
	if inventory != null:
		var count := inventory.volley_size()
		var first: Vector3 = origins.front()
		var last: Vector3 = origins.back()
		origins.clear()
		for index in count:
			origins.append(first.lerp(last, 0.5 if count == 1 else float(index) / float(count - 1)))
	return origins


func _play_cannon_audio(ship: ShipMotor) -> void:
	if not ResourceLoader.exists(CANNON_AUDIO):
		return
	var audio := AudioStreamPlayer3D.new()
	audio.bus = "Combat"
	audio.name = "BroadsideAudio"
	audio.stream = load(CANNON_AUDIO) as AudioStream
	audio.volume_db = -5.0
	audio.max_distance = 42.0
	GameScope.owner_of(self).add_child(audio)
	audio.global_position = ship.global_position
	audio.finished.connect(audio.queue_free)
	audio.play()


func _best_broadside_direction(ship: ShipMotor) -> Vector3:
	var right := ship.global_transform.basis.x.normalized()
	var target := _closest_hostile(ship)
	if target == null:
		return right
	var to_target := (target.global_position - ship.global_position).normalized()
	return right if right.dot(to_target) >= 0.0 else -right


func _closest_hostile(ship: ShipMotor) -> Node3D:
	var targeting := ship.get_node_or_null("Targeting") as TargetingSystem
	if targeting != null and targeting.target != null and is_instance_valid(targeting.target):
		return targeting.target
	var group_name := "enemies" if ship.is_in_group("player") else "player"
	var closest: Node3D = null
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group(group_name):
		if not candidate is Node3D:
			continue
		var candidate_health := candidate.get_node_or_null("Health") as ShipHealth
		if candidate_health != null and candidate_health.is_sunk:
			continue
		var distance := ship.global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			closest = candidate
	return closest


func _spawn_projectile(ship: ShipMotor, origin: Vector3, direction: Vector3, cannon: Dictionary, ammo: Dictionary, show_visual: bool = true, supply_damage_multiplier: float = 1.0) -> void:
	if show_visual:
		var flash: MuzzleFlash = MuzzleFlashScript.new()
		flash.name = "MuzzleFlash"
		GameScope.owner_of(self).add_child(flash)
		flash.global_position = origin
	var projectile: CannonProjectile = ProjectileScript.new()
	projectile.name = "Cannonball"
	projectile.render_visual = show_visual
	projectile.trail_color = ammo.color
	projectile.visual_id = "harpoon" if weapon_mode == "harpoon" else "cannonball"
	projectile.locked_target = selected_target() if ship.is_in_group("player") else _closest_hostile(ship) as ShipMotor
	projectile.range_remaining = effective_range() + 6.0
	projectile.life_seconds = maxf(3.0, projectile.range_remaining / maxf(1.0, projectile_speed * float(cannon.speed)) + 0.5)
	GameScope.owner_of(self).add_child(projectile)
	var critical_chance := float(ammo.get("crit", 0.08))
	var critical_multiplier := 1.65 if randf() < critical_chance else 1.0
	projectile.critical_hit = critical_multiplier > 1.0
	projectile.configure(ship, origin, direction * projectile_speed * cannon.speed, damage * cannon.damage * ammo.damage * critical_multiplier * supply_damage_multiplier, ammo.armor_pierce, ammo.slow, ammo.color, str(ammo.get("effect", "none")), float(ammo.get("effect_power", 0.0)), float(ammo.get("effect_duration", 0.0)), str(ammo.get("id", "iron")))
