class_name PlayerShipInput
extends Node

signal navigation_intent_created(target: Vector3, intent: String)
signal repair_intent_created(mode: String)

var steering_finger := -1
var steering_start := Vector2.ZERO
var steering_current := Vector2.ZERO
var joystick_visible := false
var repair_charges: int:
	get:
		return (get_parent().get_node("Inventory") as PlayerInventory).count("repair")
	set(value):
		(get_parent().get_node("Inventory") as PlayerInventory).set_count("repair", value)
var ability_ready_at := 0.0
var touch_positions := {}
var pinch_distance := 0.0
var pinch_active := false
var pending_action_finger := -1
var pending_action_position := Vector2.ZERO
var pending_picker_press_msec := 0
var navigation_target := Vector3.ZERO
var navigation_steering_target := Vector3.ZERO
var has_navigation_target := false
var navigation_marker: MeshInstance3D
var pending_hud_action := ""
var sail_finger := -1
var sail_start := Vector2.ZERO
var camera_pan := Vector2.ZERO
var item_ready_at: Dictionary = {}

@onready var ship: ShipMotor = get_parent() as ShipMotor
@onready var weapons: ShipWeapons = get_parent().get_node("Weapons") as ShipWeapons
@onready var health: ShipHealth = get_parent().get_node("Health") as ShipHealth
@onready var targeting: TargetingSystem = get_parent().get_node("Targeting") as TargetingSystem
@onready var progression: PlayerProgression = get_parent().get_node("Progression") as PlayerProgression
@onready var ship_roster: PlayerShipRoster = get_parent().get_node("ShipRoster") as PlayerShipRoster


func _ready() -> void:
	var profile:=InputDeviceProfile.detect(get_viewport().get_visible_rect().size)
	ship.set_meta("input_mode",str(profile.get("input_mode","mouse_keyboard")))
	ship.set_meta("hud_profile",str(profile.get("hud_profile","desktop_wide")))
	ship.set_meta("crossplay_intent_schema",1)
	_create_navigation_marker.call_deferred()


func _process(_delta: float) -> void:
	if Time.get_ticks_msec() < int(ship.get_meta("ui_action_guard_until", 0)):
		ship.stop_ship()
		return
	if _modal_input_blocked() or health.is_sunk:
		ship.stop_ship()
		return
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if hud != null and hud.global_map_open:
		ship.stop_ship()
		return
	if hud != null and hud.menu_open:
		ship.turn_input = 0.0
		ship.throttle_input = 0.0
		return
	if progression.shop_open:
		ship.turn_input = 0.0
		ship.throttle_input = 0.0
		if Input.is_action_just_pressed("upgrade_hull"):
			progression.purchase_upgrade("hull")
		if Input.is_action_just_pressed("upgrade_cannon"):
			progression.purchase_upgrade("cannon")
		if Input.is_action_just_pressed("upgrade_sails"):
			progression.purchase_upgrade("sails")
		if Input.is_action_just_pressed("ship_previous"):
			ship_roster.preview_previous()
		if Input.is_action_just_pressed("ship_next"):
			ship_roster.preview_next()
		if Input.is_action_just_pressed("ship_select"):
			ship_roster.buy_or_equip_preview()
		if Input.is_action_just_pressed("shop_toggle"):
			progression.toggle_shop()
		return
	var keyboard_turn := Input.get_axis("turn_left", "turn_right")
	var keyboard_throttle := Input.get_axis("move_back", "move_forward")
	var camera := get_viewport().get_camera_3d() as IsometricCameraRig
	if camera != null and steering_finger >= 0: camera.pan_camera(camera_pan, _delta)
	# Camera panning never cancels Tap-to-Sail.
	if abs(keyboard_turn) > 0.05 or abs(keyboard_throttle) > 0.05:
		has_navigation_target = false
		if navigation_marker != null:
			navigation_marker.visible = false
		ship.turn_input = keyboard_turn
		ship.throttle_input = keyboard_throttle
	elif has_navigation_target:
		_follow_navigation_target()
	else:
		ship.turn_input = 0.0
		ship.throttle_input = 0.0
	if Input.is_action_just_pressed("fire"):
		weapons.fire_broadside(weapons.selected_target() != null)
	if Input.is_action_just_pressed("respawn"):
		health.force_respawn()
	if Input.is_action_just_pressed("target_next"):
		targeting.cycle_target()
	if Input.is_action_just_pressed("cycle_cannon"):
		weapons.cycle_cannon()
	if Input.is_action_just_pressed("cycle_ammo"):
		weapons.cycle_ammo()
	if Input.is_action_just_pressed("repair"):
		use_repair()
	if Input.is_action_just_pressed("ability"):
		use_speed_ability()
	if Input.is_action_just_pressed("interact"):
		if not use_halloween_event_interaction() and not use_port_interaction() and not use_poi_interaction():
			use_guild_island_interaction()
	if Input.is_action_just_pressed("shop_toggle"):
		progression.toggle_shop()
	if hud!=null and not hud.guild_island_panel.is_empty():
		if Input.is_action_just_pressed("ship_next"):hud.guild_island_focus(1)
		elif Input.is_action_just_pressed("ship_previous"):hud.guild_island_focus(-1)


func _unhandled_input(event: InputEvent) -> void:
	if Time.get_ticks_msec() < int(ship.get_meta("ui_action_guard_until", 0)):
		return
	if _modal_input_blocked() or health.is_sunk:
		return
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if hud == null:
		return
	var geometry := hud.layout()
	var safe: Rect2 = geometry.safe
	if hud.menu_open:
		return
	# M38 combat pickers own input while visible, so taps never leak through to sailing.
	if not hud.combat_picker.is_empty():
		if event is InputEventMouseButton and event.pressed:
			var picker_action := hud.combat_picker_action_at(event.position)
			if event.button_index == MOUSE_BUTTON_RIGHT and not picker_action.is_empty() and picker_action not in ["close", "dismiss", "detail_close"]:
				hud.show_combat_detail(picker_action)
			elif event.button_index == MOUSE_BUTTON_LEFT and not picker_action.is_empty():
				hud.activate_combat_picker_action(picker_action)
			return
		if event is InputEventScreenTouch:
			if event.pressed:
				pending_action_finger = event.index
				pending_action_position = event.position
				pending_picker_press_msec = Time.get_ticks_msec()
			else:
				if event.index == pending_action_finger and event.position.distance_to(pending_action_position) < 28.0:
					var touch_picker_action := hud.combat_picker_action_at(event.position)
					var held := Time.get_ticks_msec() - pending_picker_press_msec
					if held >= 420 and touch_picker_action not in ["", "close", "dismiss", "detail_close"]:
						hud.show_combat_detail(touch_picker_action)
					elif not touch_picker_action.is_empty():
						hud.activate_combat_picker_action(touch_picker_action)
				pending_action_finger = -1
				pending_picker_press_msec = 0
			return
		if event is InputEventScreenDrag:
			return
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var guild_detail_row:=hud.guild_island_detail_row_at(event.position)
		if guild_detail_row>=0:
			hud.guild_island_set_focus(guild_detail_row)
			return
		if hud.halloween_event_action_at(event.position):
			hud.activate_halloween_event_interaction()
			return
		var guild_action:=hud.guild_island_action_at(event.position)
		if not guild_action.is_empty():
			hud.activate_guild_island_action(guild_action)
			return
		var action := NauticalLayout.action_at(event.position, geometry)
		if hud.global_map_open:
			hud.toggle_global_map()
		elif progression.shop_open:
			if _in_shop_actions(event.position, safe):
				_handle_action_touch(event.position, safe)
		elif not action.is_empty():
			_activate_hud_action(action, hud)
		elif not NauticalLayout.blocks_world(event.position, geometry, hud.log_visible()):
			_set_navigation_target(event.position)
	elif event is InputEventScreenTouch:
		if event.canceled:
			cancel_navigation()
			return
		if event.pressed:
			var guild_detail_row:=hud.guild_island_detail_row_at(event.position)
			if guild_detail_row>=0:
				if pending_action_finger>=0:return
				pending_action_finger=event.index
				pending_action_position=event.position
				pending_hud_action="guild_focus:%d"%guild_detail_row
				return
			if hud.halloween_event_action_at(event.position):
				if pending_action_finger>=0:return
				pending_action_finger=event.index
				pending_action_position=event.position
				pending_hud_action="halloween_event"
				return
			var guild_action:=hud.guild_island_action_at(event.position)
			if not guild_action.is_empty():
				if pending_action_finger>=0:return
				pending_action_finger=event.index
				pending_action_position=event.position
				pending_hud_action="guild:"+guild_action
				return
			var action := NauticalLayout.action_at(event.position, geometry)
			if hud.global_map_open or progression.shop_open or not action.is_empty():
				if pending_action_finger >= 0: return
				pending_action_finger = event.index
				pending_action_position = event.position
				pending_hud_action = "map" if hud.global_map_open else ("shop" if progression.shop_open else action)
				return
			var in_wheel := (geometry.wheel as Rect2).has_point(event.position)
			if not in_wheel and NauticalLayout.blocks_world(event.position, geometry, hud.log_visible()):
				return
			touch_positions[event.index] = event.position
			if touch_positions.size() >= 2:
				_begin_pinch()
				sail_finger = -1
			elif in_wheel:
				steering_finger = event.index
				steering_start = (geometry.wheel as Rect2).get_center()
				steering_current = event.position
				joystick_visible = true
			else:
				sail_finger = event.index
				sail_start = event.position
		else:
			if event.index == pending_action_finger:
				if event.position.distance_to(pending_action_position) < 24 and not pinch_active:
					if pending_hud_action == "shop":
						if _in_shop_actions(event.position, safe):
							_handle_action_touch(event.position, safe)
					elif pending_hud_action == "map" and hud.global_map_open:
						hud.toggle_global_map()
					elif pending_hud_action.begins_with("guild_focus:"):
						var guild_index:=int(pending_hud_action.trim_prefix("guild_focus:"))
						if hud.guild_island_detail_row_at(event.position)==guild_index:
							hud.guild_island_set_focus(guild_index)
					elif pending_hud_action=="halloween_event":
						if hud.halloween_event_action_at(event.position):
							hud.activate_halloween_event_interaction()
					elif pending_hud_action.begins_with("guild:"):
						var guild_id:=pending_hud_action.trim_prefix("guild:")
						if hud.guild_island_action_at(event.position)==guild_id:
							hud.activate_guild_island_action(guild_id)
					elif NauticalLayout.action_at(event.position, geometry) == pending_hud_action:
						_activate_hud_action(pending_hud_action, hud)
				pending_action_finger = -1
				pending_hud_action = ""
			if event.index == sail_finger:
				if not pinch_active and event.position.distance_to(sail_start) < 18 and not NauticalLayout.blocks_world(event.position, geometry, hud.log_visible()):
					_set_navigation_target(event.position)
				sail_finger = -1
			if event.index == steering_finger:
				_release_joystick()
			touch_positions.erase(event.index)
			if touch_positions.size() < 2:
				pinch_active = false
				pinch_distance = 0
	elif event is InputEventScreenDrag:
		if event.index == pending_action_finger:
			if event.position.distance_to(pending_action_position) > 24:
				pending_hud_action = ""
			return
		if not touch_positions.has(event.index):
			return
		touch_positions[event.index] = event.position
		if pinch_active and touch_positions.size() >= 2:
			_update_pinch()
		elif event.index == steering_finger:
			steering_current = event.position
			var drag: Vector2 = (event.position - steering_start) / 52.0
			var magnitude := minf(drag.length(), 1.0)
			if magnitude < 0.12:
				camera_pan = Vector2.ZERO
			else:
				var shaped := drag.normalized() * inverse_lerp(0.12, 1.0, magnitude)
				camera_pan = shaped
		elif event.index == sail_finger and not pinch_active:
			# M34 mobile comfort: dragging over open water continuously redirects the ship.
			# This keeps Tap-to-Sail as the core contract while allowing immediate course changes.
			if event.position.distance_to(sail_start) >= 12.0 and not NauticalLayout.blocks_world(event.position, geometry, hud.log_visible()):
				_set_navigation_target(event.position)


func _record_local_intent(id:String,payload:Dictionary={})->void:
	if not GameplayIntentContract.is_gameplay(id) and not GameplayIntentContract.is_presentation(id):
		return
	ship.set_meta("last_local_intent",GameplayIntentContract.local_envelope(id,payload))

func _activate_hud_action(action: String, hud: GameHud) -> void:
	match action:
		"recenter":
			_record_local_intent("camera_recenter")
			var camera := get_viewport().get_camera_3d() as IsometricCameraRig
			if camera != null: camera.recenter()
		"auto_fire":
			var voyage := ship.get_node_or_null("Voyage") as VoyageProgress
			if voyage != null and not voyage.auto_unlocked():
				hud.note("AUTO: Anfängerauftrag 1 abschließen")
				return
			weapons.toggle_auto_fire()
			hud.note("Dauerfeuer aktiv" if weapons.auto_fire else "Dauerfeuer aus · " + weapons.attack_status())
		"ammo_menu": hud.toggle_combat_picker("ammo")
		"items_menu": hud.toggle_combat_picker("items")
		"quick_0", "quick_1", "quick_2", "quick_3": hud.activate_quickslot(int(action.right(1)))
		"fire":
			_record_local_intent("fire",{"has_target":weapons.selected_target()!=null})
			if weapons.fire_broadside(weapons.selected_target() != null): hud.note("Salve abgefeuert · " + weapons.ammo_name())
			else: hud.note(weapons.attack_status())
		"repair": _record_local_intent("repair"); use_repair()
		"boost": _record_local_intent("boost"); use_speed_ability()
		"target":
			if weapons.weapon_mode == "support":
				var ally := weapons.cycle_support_target()
				hud.note("SUPPORT-ZIEL · " + (ally.name if ally != null else "KEINS"))
				return
			# M188: the target utility becomes a contextual harbor action only while a real port is in range.
			# Outside port range it remains the ordinary target-cycle action.
			if ship.has_meta("nearby_port"):
				_record_local_intent("interact", {"kind":"harbor"})
				if use_port_interaction():
					hud.open_menu("harbor")
					hud.note("HAFEN · Lokale Dienste geöffnet")
			else:
				_record_local_intent("target_next")
				targeting.cycle_target()
		"map", "minimap": hud.toggle_global_map()
		"nav_map": hud.toggle_global_map()
		"nav_log": hud.log_open = not hud.log_open
		"log": hud.log_open = not hud.log_open
		"world": hud.toggle_global_map()
		"group", "achievements", "events", "quests", "shop", "guild", "chat", "rankings", "bonus", "home":
			hud.open_menu(action)
		"shipyard":
			# M188: Shipyard is a global meta screen, never an alias for the harbor journal.
			var roster := ship.get_node_or_null("ShipRoster") as PlayerShipRoster
			var screen := ShipyardPanel.new()
			get_tree().root.add_child(screen)
			hud.route_panel(screen, "home")
			screen.open(hud, roster.selected_ship_id if roster != null else "")
		"arsenal":
			var arsenal := get_tree().get_first_node_in_group("arsenal_ui") as ArsenalPanel
			if arsenal != null: arsenal.toggle()
		"zoom_in", "zoom_out":
			var camera := get_viewport().get_camera_3d() as IsometricCameraRig
			if camera != null: camera.apply_pinch_delta(40 if action == "zoom_in" else -40)
		"ammo_0", "ammo_1", "ammo_2":
			weapons.select_mode("cannon")
			weapons.ammo_index = int(action.right(1))
			weapons.loadout_changed.emit()
			hud.note("Munition: " + weapons.ammo_name())


func _in_shop_actions(point: Vector2, safe: Rect2) -> bool:
	var action_scale := clampf(safe.size.y / 720, 0.85, 1.7)
	return point.x >= safe.position.x + safe.size.x * 0.55 and point.y >= safe.end.y - 210 * action_scale


func _legacy_unhandled_input(event: InputEvent) -> void:
	if _modal_input_blocked() or health.is_sunk:
		return
	var safe := _safe_rect()
	var action_scale: float = clamp(safe.size.y / 720.0, 0.85, 1.7)
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_positions[event.index] = event.position
			if touch_positions.size() >= 2:
				_begin_pinch()
				return
			if progression.shop_open:
				if event.position.x >= safe.position.x + safe.size.x * 0.55 and event.position.y >= safe.end.y - 210.0 * action_scale:
					pending_action_finger = event.index
					pending_action_position = event.position
				return
			var hud_nodes := get_tree().get_nodes_in_group("hud")
			if event.position.x > safe.end.x - 180.0 and event.position.y < safe.position.y + 190.0:
				if not hud_nodes.is_empty():
					hud_nodes[0].toggle_global_map()
			elif not hud_nodes.is_empty() and hud_nodes[0].global_map_open:
				return
			elif event.position.x < safe.position.x + safe.size.x * 0.55 and steering_finger < 0:
				steering_finger = event.index
				steering_start = event.position
				steering_current = event.position
				joystick_visible = true
			elif event.position.x >= safe.position.x + safe.size.x * 0.55:
				pending_action_finger = event.index
				pending_action_position = event.position
		else:
			var execute_action: bool = event.index == pending_action_finger and not pinch_active
			if event.index == steering_finger:
				var tap_to_sail: bool = event.position.distance_to(steering_start) < 18.0 and not pinch_active
				_release_joystick()
				if tap_to_sail and not _touch_hits_hud(event.position, safe):
					_set_navigation_target(event.position)
			if execute_action:
				_handle_action_touch(event.position, safe)
			if event.index == pending_action_finger:
				pending_action_finger = -1
			touch_positions.erase(event.index)
			if touch_positions.size() < 2:
				pinch_active = false
				pinch_distance = 0.0
	elif event is InputEventScreenDrag:
		touch_positions[event.index] = event.position
		if touch_positions.size() >= 2:
			_update_pinch()
		elif event.index == steering_finger and not pinch_active:
			steering_current = event.position
			var dpi_scale: float = max(90.0, DisplayServer.screen_get_dpi() * 0.45)
			var drag: Vector2 = (steering_current - steering_start) / dpi_scale
			ship.turn_input = clamp(drag.x, -1.0, 1.0)
			ship.throttle_input = clamp(-drag.y, -1.0, 1.0)
		elif event.index == pending_action_finger and event.position.distance_to(pending_action_position) > 24.0:
			pending_action_finger = -1
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hud_nodes := get_tree().get_nodes_in_group("hud")
		if progression.shop_open and event.position.x >= safe.position.x + safe.size.x * 0.55 and event.position.y >= safe.end.y - 210.0 * action_scale:
			_handle_action_touch(event.position, safe)
		elif not progression.shop_open and event.position.x >= safe.position.x + safe.size.x * 0.58 and (hud_nodes.is_empty() or not hud_nodes[0].global_map_open):
			weapons.fire_broadside()
		elif not progression.shop_open and (hud_nodes.is_empty() or not hud_nodes[0].global_map_open):
			_set_navigation_target(event.position)


func _begin_pinch() -> void:
	pinch_active = true
	pending_action_finger = -1
	_release_joystick()
	var points := touch_positions.values()
	pinch_distance = (points[0] as Vector2).distance_to(points[1] as Vector2)


func _update_pinch() -> void:
	var points := touch_positions.values()
	var current_distance := (points[0] as Vector2).distance_to(points[1] as Vector2)
	if pinch_distance > 0.0:
		var camera := get_viewport().get_camera_3d() as IsometricCameraRig
		if camera != null:
			camera.apply_pinch_delta(current_distance - pinch_distance)
	pinch_distance = current_distance


func _handle_action_touch(position: Vector2, safe: Rect2) -> void:
	if position.y < safe.end.y - 145.0 and not progression.shop_open:
		weapons.fire_broadside()
		return
	var action_width := safe.size.x * 0.45 / 4.0
	var action_start := safe.position.x + safe.size.x * 0.55
	var slot := int((position.x - action_start) / max(action_width, 1.0))
	if progression.shop_open:
		var action_scale: float = clamp(safe.size.y / 720.0, 0.85, 1.7)
		if position.y < safe.end.y - 138.0 * action_scale:
			match clamp(slot, 0, 3):
				0:
					ship_roster.preview_previous()
				1:
					ship_roster.buy_or_equip_preview()
				2:
					ship_roster.preview_next()
				_:
					progression.toggle_shop()
			return
		match clamp(slot, 0, 3):
			0:
				progression.purchase_upgrade("hull")
			1:
				progression.purchase_upgrade("cannon")
			2:
				progression.purchase_upgrade("sails")
			_:
				progression.toggle_shop()
		return
	match clamp(slot, 0, 3):
		0:
			if not use_port_interaction():
				targeting.cycle_target()
		1:
			use_repair()
		2:
			use_speed_ability()
		_:
			weapons.fire_broadside()


func use_repair() -> void:
	if _modal_input_blocked(): return
	repair_intent_created.emit("repair_or_shield")
	var sustain := ship.get_node_or_null("SustainSupport") as M240SustainSupportRuntime
	if sustain != null:
		sustain.toggle_repair()
		return
	# Compatibility fallback for old reconstructed scenes only.
	use_action_item("repair")

func use_speed_ability() -> void:
	if _modal_input_blocked(): return
	if use_action_item("boost"):
		ability_ready_at = float(item_ready_at.get("boost", 0.0))


func item_cooldown_remaining(id: String) -> float:
	return maxf(0.0, float(item_ready_at.get(id, 0.0)) - Time.get_ticks_msec() / 1000.0)

func item_cooldown_progress(id: String) -> float:
	var definition := ActionItemCatalog.item(id)
	var cooldown := float(definition.get("cooldown", 0.0))
	if cooldown <= 0.0: return 1.0
	return clampf(1.0 - item_cooldown_remaining(id) / cooldown, 0.0, 1.0)

func use_action_item(id: String) -> bool:
	var definition := ActionItemCatalog.item(id)
	if definition.is_empty() or health.is_sunk or progression.shop_open: return false
	var now := Time.get_ticks_msec() / 1000.0
	if now < float(item_ready_at.get(id, 0.0)): return false
	var inventory := ship.get_node("Inventory") as PlayerInventory
	if inventory.count(id) <= 0: return false
	var target := weapons.selected_target()
	var target_rule := str(definition.get("target", "self"))
	var range := float(definition.get("range", 0.0))
	if target_rule in ["hostile", "monster"]:
		if target == null: return false
		if range > 0.0 and ship.global_position.distance_to(target.global_position) > range: return false
		if target_rule == "monster" and str(target.get_meta("encounter_kind", "ship")) != "monster": return false
	var effect:=str(definition.get("effect",""))
	var executable:bool=not definition.get("behavior_components",[]).is_empty() or not ActionItemBehaviorExecutor.legacy_component(definition).is_empty()
	if not executable or not ActionItemBehaviorExecutor.execute(get_tree(),ship,target,definition):return false
	CombatVfx.action(get_tree(), id, ship.global_position, target)
	if not inventory.consume(id): return false
	item_ready_at[id] = now + float(definition.get("cooldown", 0.0))
	if bool(definition.get("breaks_veil", false)):
		ship.set_meta("veil_active", false)
		ship.set_meta("veil_until", 0.0)
	return true

func use_abyssal_veil() -> void:
	use_action_item("veil")


func ability_progress() -> float:
	var remaining := ability_ready_at - Time.get_ticks_msec() / 1000.0
	return 1.0 - clamp(remaining / 12.0, 0.0, 1.0)


func use_halloween_event_interaction()->bool:
	var hud:=get_tree().get_first_node_in_group("hud") as GameHud
	if hud==null:return false
	if hud.halloween_event_prompt().is_empty():return false
	var used:=hud.activate_halloween_event_interaction()
	if used:_record_local_intent("interact",{"kind":"halloween_event"})
	return used

func use_poi_interaction()->bool:
	var poi:=DynamicPoiInteraction.nearest(get_tree(),ship)
	if poi==null:return false
	var used:=DynamicPoiInteraction.activate(get_tree(),poi)
	if used:
		var hud:=get_tree().get_first_node_in_group("hud") as GameHud
		if hud!=null:hud.note("POI · "+str(poi.get_meta("poi_label",poi.name)))
		_record_local_intent("interact",{"kind":"poi","content_id":str(poi.get_meta("content_id",poi.name))})
	return used

func use_guild_island_interaction()->bool:
	var hud:=get_tree().get_first_node_in_group("hud") as GameHud
	if hud==null:return false
	var prompt:=GuildIslandInteraction.prompt(ship)
	if prompt.is_empty():return false
	hud.activate_guild_island_action("inspect_guild")
	_record_local_intent("interact",{"kind":"guild_island_preview"})
	return true

func use_port_interaction() -> bool:
	var interaction := ship.get_meta("nearby_port", null) as PortInteraction
	return interaction != null and interaction.activate(ship)


func _release_joystick() -> void:
	camera_pan = Vector2.ZERO
	steering_finger = -1
	joystick_visible = false
	ship.turn_input = 0.0
	ship.throttle_input = 0.0


func cancel_navigation() -> void:
	if is_instance_valid(weapons):
		weapons.auto_fire = false
	has_navigation_target = false
	navigation_steering_target = Vector3.ZERO
	if is_instance_valid(ship):
		ship.set_meta("navigation_pivoting", false)
		ship.set_meta("navigation_intent", "")
	_release_joystick()
	touch_positions.clear()
	pending_action_finger = -1
	pending_hud_action = ""
	sail_finger = -1
	pinch_active = false
	if is_instance_valid(navigation_marker):
		navigation_marker.visible = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(ship):
		cancel_navigation()
		ship.stop_ship()


func _set_navigation_target(screen_position: Vector2) -> void:
	_record_local_intent("sail_target",{"screen_x":screen_position.x,"screen_y":screen_position.y})
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	if targeting.pick_at(screen_position, camera) != null:
		return
	var tapped_loot := _loot_at_screen(screen_position, camera)
	if tapped_loot != null:
		navigation_target = Vector3(tapped_loot.global_position.x, 0.55, tapped_loot.global_position.z)
		navigation_steering_target = navigation_target
		has_navigation_target = true
		ship.set_meta("navigation_pivoting", false)
		ship.set_meta("navigation_intent", "loot")
		if navigation_marker != null:
			navigation_marker.global_position = navigation_target + Vector3.DOWN * 0.48
			navigation_marker.visible = true
		navigation_intent_created.emit(navigation_target, "loot")
		var hud := get_tree().get_first_node_in_group("hud") as GameHud
		if hud != null:
			hud.note_prioritized("KURS AUF BEUTE · AUTOMATISCHE BERGUNG BEI ANNÄHERUNG", 3, "navigation", 2400)
		return
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if abs(ray_direction.y) < 0.0001:
		return
	var distance := (0.55 - ray_origin.y) / ray_direction.y
	if distance <= 0.0:
		return
	var point := ray_origin + ray_direction * distance
	navigation_target = Vector3(point.x, 0.55, point.z)
	navigation_steering_target = navigation_target
	has_navigation_target = true
	ship.set_meta("navigation_pivoting", false)
	ship.set_meta("navigation_intent", "water")
	if navigation_marker != null:
		navigation_marker.global_position = navigation_target + Vector3.DOWN * 0.48
		navigation_marker.visible = true
	navigation_intent_created.emit(navigation_target, "water")


func set_navigation_world_target(world_position: Vector3, intent := "objective") -> void:
	## Used by resolved UI objectives only. The caller must supply an existing
	## world target; this function does not teleport or fabricate pathfinding.
	navigation_target = Vector3(world_position.x, 0.55, world_position.z)
	navigation_steering_target = navigation_target
	has_navigation_target = true
	ship.set_meta("navigation_pivoting", false)
	ship.set_meta("navigation_intent", intent)
	_record_local_intent("sail_world_target", {"intent":intent, "x":world_position.x, "z":world_position.z})
	if navigation_marker != null:
		navigation_marker.global_position = navigation_target + Vector3.DOWN * 0.48
		navigation_marker.visible = true
	navigation_intent_created.emit(navigation_target, intent)


func _follow_navigation_target() -> void:
	# M192: keep the captain's final tap destination, but steer around hard land.
	# Other ships/NPCs/monsters never become route blockers.
	var steering_target:=_navigation_steering_point(ship.global_position,navigation_target)
	navigation_steering_target = steering_target
	var to_target := steering_target - ship.global_position
	to_target.y = 0.0
	if to_target.length() < 1.35:
		has_navigation_target = false
		navigation_steering_target = Vector3.ZERO
		ship.set_meta("navigation_pivoting", false)
		ship.set_meta("navigation_intent", "")
		ship.set_meta("navigation_detouring_land",false)
		if navigation_marker != null:
			navigation_marker.visible = false
		ship.stop_ship()
		return
	var forward := ship.global_transform.basis.z.normalized()
	var signed_angle := forward.signed_angle_to(to_target.normalized(), Vector3.UP)
	var angle_degrees := absf(rad_to_deg(signed_angle))
	# M181: pivot first for destinations behind the hull. The former 0.32 minimum
	# throttle forced the captain forwards into a wide arc before turning around.
	# Tap-to-Sail now takes the shortest heading and only accelerates once the bow
	# is meaningfully aligned with the selected water position.
	var detouring_land:=bool(ship.get_meta("navigation_detouring_land",false))
	var pivoting := angle_degrees >= 58.0 and not detouring_land
	ship.set_meta("navigation_pivoting", pivoting)
	ship.turn_input = clamp(signed_angle / deg_to_rad(42.0), -1.0, 1.0)
	if detouring_land:
		# Island avoidance is flowing navigation: steer around land without a collision stop
		# or the former low-speed crawl. The final tapped destination stays unchanged.
		ship.throttle_input = clampf(1.0-angle_degrees/140.0,0.72,1.0)
	elif pivoting:
		ship.throttle_input = 0.0
	elif angle_degrees >= 26.0:
		ship.throttle_input = 0.24
	else:
		ship.throttle_input = clampf(1.0 - angle_degrees / 52.0, 0.55, 1.0)


func _navigation_steering_point(from_world:Vector3,final_world:Vector3)->Vector3:
	var a:=Vector2(from_world.x,from_world.z)
	var b:=Vector2(final_world.x,final_world.z)
	if a.distance_to(b)<0.01:return final_world
	var best_island:Node3D=null
	var best_t:=2.0
	var best_radius:=0.0
	for node in get_tree().get_nodes_in_group("islands"):
		var island:=node as Node3D
		if island==null or not is_instance_valid(island):continue
		var center:=Vector2(island.global_position.x,island.global_position.z)
		var aspect:Vector2=island.get_meta("island_aspect",Vector2.ONE)
		var radius:=float(island.get_meta("island_radius",5.0))*maxf(aspect.x,aspect.y)*0.82+5.2
		var hit:=_segment_circle_hit(a,b,center,radius)
		if bool(hit.get("blocked",false)) and float(hit.get("t",2.0))<best_t:
			best_island=island;best_t=float(hit.t);best_radius=radius
	if best_island==null:
		ship.set_meta("navigation_detouring_land",false)
		return final_world
	var center:=Vector2(best_island.global_position.x,best_island.global_position.z)
	var travel:=(b-a).normalized()
	var perp:=Vector2(-travel.y,travel.x)
	var margin:=best_radius+2.5
	var left:=center+perp*margin
	var right:=center-perp*margin
	# Pick the shorter safe side; no stop/slow command is inserted while detouring.
	var left_cost:=a.distance_to(left)+left.distance_to(b)
	var right_cost:=a.distance_to(right)+right.distance_to(b)
	var chosen:=left if left_cost<=right_cost else right
	ship.set_meta("navigation_detouring_land",true)
	return Vector3(chosen.x,final_world.y,chosen.y)

func _segment_circle_hit(a:Vector2,b:Vector2,center:Vector2,radius:float)->Dictionary:
	var ab:=b-a
	var denom:=ab.length_squared()
	if denom<0.0001:return {"blocked":a.distance_to(center)<radius,"t":0.0}
	var t:=clampf((center-a).dot(ab)/denom,0.0,1.0)
	var closest:=a+ab*t
	return {"blocked":closest.distance_to(center)<radius,"t":t}


func navigation_presentation() -> Dictionary:
	## M220 read-only course preview. This mirrors existing Tap-to-Sail state; it
	## does not add waypoints, teleportation, collision authority or route AI.
	if not has_navigation_target or not is_instance_valid(ship):
		return {"active":false}
	var steering := navigation_steering_target if navigation_steering_target != Vector3.ZERO else navigation_target
	return {
		"active":true,
		"final_target":navigation_target,
		"steering_target":steering,
		"detouring_land":bool(ship.get_meta("navigation_detouring_land",false)),
		"pivoting":bool(ship.get_meta("navigation_pivoting",false)),
		"intent":str(ship.get_meta("navigation_intent","water")),
		"remaining":ship.global_position.distance_to(navigation_target),
	}

func _touch_hits_hud(position: Vector2, safe: Rect2) -> bool:
	return position.x < safe.position.x + min(420.0, safe.size.x * 0.48) and position.y < safe.position.y + 250.0


func _loot_at_screen(screen_position: Vector2, camera: Camera3D) -> Node3D:
	var best: Node3D = null
	var best_score := 44.0 * 44.0
	for node in get_tree().get_nodes_in_group("loot"):
		var loot := node as Node3D
		if loot == null or not is_instance_valid(loot) or camera.is_position_behind(loot.global_position):
			continue
		var screen := camera.unproject_position(loot.global_position + Vector3.UP * 0.8)
		var score := screen_position.distance_squared_to(screen)
		if score < best_score:
			best = loot
			best_score = score
	return best


func _modal_input_blocked() -> bool:
	for key in ["inventory_open", "journal_open", "admin_panel_open", "meta_panel_open", "settings_open", "command_open", "external_panel_open"]:
		if bool(ship.get_meta(key, false)):
			return true
	return false


func _create_navigation_marker() -> void:
	navigation_marker = MeshInstance3D.new()
	navigation_marker.name = "MoveTargetMarker"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.72
	ring.outer_radius = 0.86
	navigation_marker.mesh = ring
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.2, 0.85, 1.0, 0.68)
	marker_material.emission_enabled = true
	marker_material.emission = Color("35cfff")
	marker_material.emission_energy_multiplier = 1.6
	marker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	navigation_marker.material_override = marker_material
	navigation_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	navigation_marker.visible = false
	GameScope.owner_of(self).add_child.call_deferred(navigation_marker)


func _safe_rect() -> Rect2:
	var viewport_rect := get_viewport().get_visible_rect()
	var platform_safe := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()
	if platform_safe.size.x <= 0 or platform_safe.size.y <= 0 or screen_size.x <= 0 or screen_size.y <= 0:
		return viewport_rect
	var ratio := viewport_rect.size / Vector2(screen_size)
	return Rect2(Vector2(platform_safe.position) * ratio, Vector2(platform_safe.size) * ratio)
