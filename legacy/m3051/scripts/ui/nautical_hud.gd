class_name NauticalHud
extends RefCounted
## Legacy contract vocabulary: AKTIVE MISSION is now represented by the single
## player-selected VERFOLGTES ZIEL; detailed lists remain in the Command Deck.
## Godot-native interpretation of user mockup 152969.png; not a bitmap overlay.

const GOLD := Color("d7a94f")
const LIGHT := Color("ffd98a")
const INK := Color(0.012, 0.043, 0.061, 0.95)
const TEXT := Color("e9e8da")
const BLUE := Color("168cdb")
const GREEN := Color("55bb49")
const RED := Color("c73825")
static var _panel_style: StyleBoxFlat
const ICON_IDS := {
	"fire": "hud_icon_attack", "repair": "hud_icon_repair", "harpoon": "hud_icon_harpoon",
	"target": "hud_icon_target", "ammo_menu": "hud_icon_ammo",
	"nav_map": "world", "nav_log": "log",
	"ammo_0": "iron", "ammo_1": "explosive", "ammo_2": "chain"
}


static func box_style() -> StyleBoxFlat:
	if _panel_style != null:
		return _panel_style
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	_panel_style = style
	return style


static func panel(background: Color = INK, border: Color = GOLD, radius: float = 7.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(roundi(radius))
	return style


static func text(hud: GameHud, value: String, rect: Rect2, font_size := 14, color := TEXT) -> void:
	hud.draw_string(hud.font, rect.position + Vector2(0, font_size), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x, font_size, color)


static func bar(hud: GameHud, rect: Rect2, amount: float, color: Color) -> void:
	hud.draw_rect(rect, Color("020b11"))
	var fill := Rect2(rect.position + Vector2.ONE, Vector2(maxf(0, rect.size.x - 2) * clampf(amount, 0, 1), maxf(1, rect.size.y - 2)))
	hud.draw_rect(fill, color)
	hud.draw_line(fill.position, fill.position + Vector2(fill.size.x, 0), color.lightened(0.4), 1)
	hud.draw_rect(rect, Color("425458"), false, 1)


static func ring(hud: GameHud, rect: Rect2, active := false) -> void:
	if graphic_frame(hud, "hud_combat_ring_active" if active else "hud_combat_ring", rect):
		return
	var center := rect.get_center()
	var radius := rect.size.x * 0.5
	hud.draw_circle(center + Vector2(1, 3), radius + 2, Color(0, 0, 0, 0.5))
	hud.draw_circle(center, radius, INK)
	hud.draw_arc(center, radius - 1, 0, TAU, 64, LIGHT if active else GOLD, 2, true)
	hud.draw_arc(center, radius - 5, 0, TAU, 64, Color("70532b"), 1, true)


static func icon(hud: GameHud, id: String, rect: Rect2) -> void:
	var texture := VisualAssetCatalog.texture(CombatUiIconCatalog.hud_slot(id, str(ICON_IDS.get(id, id))))
	if texture == null: return
	var available := rect.grow(-6)
	var ratio := minf(available.size.x / texture.get_width(), available.size.y / texture.get_height())
	var dimensions := texture.get_size() * ratio
	hud.draw_texture_rect(texture, Rect2(available.get_center() - dimensions * 0.5, dimensions), false)


static func graphic_frame(hud: GameHud, id: String, rect: Rect2) -> bool:
	var texture := VisualAssetCatalog.texture(id)
	if texture == null:
		return false
	hud.draw_texture_rect(texture, rect, false)
	return true


static func paint(hud: GameHud) -> void:
	var player := hud.get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null:
		return
	var layout := hud.layout()
	var safe: Rect2 = layout.safe
	var compact: bool = layout.compact
	var ui_scale: float = float(layout.get("ui_scale", 1.0))
	var health: ShipHealth = player.get_node("Health")
	var weapons: ShipWeapons = player.get_node("Weapons")
	var progression: PlayerProgression = player.get_node("Progression")
	var inventory: PlayerInventory = player.get_node("Inventory")
	var input: PlayerShipInput = player.get_node("PlayerInput")
	var world := hud._world_map()
	hud._draw_world_labels(1.0)
	hud._draw_poi_markers(ui_scale)
	hud.draw_style_box(box_style(), layout.top)
	var profile := Rect2(safe.position + Vector2(14, 8) * ui_scale, Vector2(174 if compact else 216, 48) * ui_scale)
	if not compact:
		icon(hud, "captain_portrait", Rect2(profile.position, Vector2(48, 48) * ui_scale))
		profile.position.x += 52 * ui_scale
		profile.size.x -= 52 * ui_scale
	text(hud, str(player.get_meta("captain_name", "Kapitän")), profile, roundi((18 if compact else 21) * ui_scale), LIGHT)
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	text(hud, "Lv. %d · %s · S%d" % [progression.level, roster.selected_ship().display_name, roster.ship_level()], Rect2(profile.position + Vector2(0, 29) * ui_scale, profile.size), roundi((13 if compact else 12) * ui_scale))
	var stat_x := safe.position.x + (190 if compact else 246) * ui_scale
	var stat_y := safe.position.y + (65 if layout.portrait else 11) * ui_scale
	var stat_w := safe.size.x - 30 * ui_scale if layout.portrait else minf((260 if compact else 300) * ui_scale, safe.size.x * 0.32)
	if layout.portrait:
		stat_x = safe.position.x + 14 * ui_scale
	for row in 3:
		var y := stat_y + row * (18 if compact else 23) * ui_scale
		var label: String = ["EXP", "RUMPF", "SALVE"][row]
		var ratio: float = [progression.xp_progress(), health.normalized(), weapons.reload_progress()][row]
		text(hud, label, Rect2(stat_x, y - 2, 50 * ui_scale, 18 * ui_scale), roundi((11 if compact else 12) * ui_scale), LIGHT)
		bar(hud, Rect2(stat_x + 52 * ui_scale, y + 2 * ui_scale, maxf(35 * ui_scale, stat_w - 120 * ui_scale), (10 if compact else 11) * ui_scale), ratio, GREEN if row == 2 else BLUE)
		var value: String = ["%d/%d" % [progression.xp, progression.xp_to_next_level()], "%.0f/%.0f" % [health.current_health, health.max_health], "%d %%" % roundi(weapons.reload_progress() * 100)][row]
		text(hud, value, Rect2(stat_x + stat_w - 64 * ui_scale, y - 2 * ui_scale, 64 * ui_scale, 18 * ui_scale), roundi((10 if compact else 11) * ui_scale))
	var nav_labels := {"nav_map":"KARTE", "nav_log":"LOG", "shipyard": "WERFT", "events": "EVENTS", "quests": "QUESTS", "shop": "SHOP", "guild": "GUILD", "chat": "CHAT", "achievements": "ERFOLGE", "log": "LOGBOOK", "rankings": "RANKINGS", "bonus": "BONUS", "arsenal": "ARSENAL", "home": "MENÜ"}
	for id in layout.actions:
		if not nav_labels.has(id):
			continue
		var r: Rect2 = layout.actions[id]
		hud.draw_style_box(box_style(), r)
		icon(hud, id, Rect2(r.get_center() - Vector2(18, 25) * ui_scale, Vector2(36, 36) * ui_scale))
		hud._draw_centered(nav_labels[id], r.get_center() + Vector2(0, 21) * ui_scale, roundi(10 * ui_scale), LIGHT)
	if (layout.currency as Rect2).has_area():
		hud.draw_style_box(box_style(), layout.currency)
		text(hud, "GOLD %s  %s %d  SHIELD %.0f" % [progression.coins, "HARP." if weapons.weapon_mode == "harpoon" else "MUN.", inventory.count(weapons.ammo_id()), health.current_shield], (layout.currency as Rect2).grow(-7 * ui_scale), roundi((10 if compact else 13) * ui_scale), LIGHT)
	var m: Rect2 = layout.mission
	var show_sortie_in_mission := false
	if m.has_area():
		hud.draw_style_box(box_style(), m)
		var tracking := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
		var tracked_card := tracking.status_card() if tracking != null else {}
		var tracked_objective := tracking.objective() if tracking != null else {}
		var sortie: Dictionary = hud.m290_first_sortie_state
		var show_sortie := tracked_objective.is_empty() and not sortie.is_empty()
		show_sortie_in_mission = show_sortie
		if show_sortie:
			tracked_card = {
				"title": str(sortie.get("next_label", "AUSFAHRT BEOBACHTET")),
				"state": "%d/%d" % [int(sortie.get("observed", 0)), int(sortie.get("total", 10))],
				"detail": str(sortie.get("hint", "Native QA steht noch aus")),
				"progress": float(sortie.get("progress", 0.0)),
			}
		var mission_icon:=VisualAssetCatalog.texture("m72_poi_objective_frame" if tracked_objective.is_empty() else _objective_icon(str(tracked_objective.get("kind", ""))))
		var mission_icon_size:=34.0*ui_scale
		if mission_icon!=null:
			hud.draw_texture_rect(mission_icon,Rect2(m.position+Vector2(8,7)*ui_scale,Vector2.ONE*mission_icon_size),false)
		var mission_text_x:=48.0 if mission_icon!=null else 10.0
		text(hud, "ERSTE AUSFAHRT" if show_sortie else "VERFOLGTES ZIEL", Rect2(m.position + Vector2(mission_text_x, 7) * ui_scale, Vector2(m.size.x - (mission_text_x+10) * ui_scale, 20 * ui_scale)), roundi(11 * ui_scale), LIGHT)
		text(hud, str(tracked_card.get("title", "KEIN ZIEL VERFOLGT")), Rect2(m.position + Vector2(mission_text_x, 26) * ui_scale, Vector2(m.size.x - (mission_text_x+10) * ui_scale, 22 * ui_scale)), roundi((13 if compact else 16) * ui_scale))
		bar(hud, Rect2(m.position + Vector2(10 * ui_scale, m.size.y - 15 * ui_scale), Vector2(m.size.x - 70 * ui_scale, 6 * ui_scale)), float(tracked_card.get("progress", 0.0)), BLUE)
		var tracked_state := str(tracked_card.get("state", "AUSWAHL"))
		text(hud, tracked_state, Rect2(m.end - Vector2(66, 23) * ui_scale, Vector2(61, 20) * ui_scale), roundi(10 * ui_scale))
		if not compact:
			text(hud, str(tracked_card.get("detail", "MENU > AUFTRÄGE")), Rect2(m.position + Vector2(10, 52) * ui_scale, Vector2(m.size.x - 20 * ui_scale, 20 * ui_scale)), roundi(11 * ui_scale))
	if not show_sortie_in_mission:
		hud._draw_m290_first_sortie_guidance(layout)
	for id in ["zoom_in", "zoom_out", "recenter"]:
		var r: Rect2 = layout.actions[id]
		if not r.has_area():continue
		hud.draw_style_box(box_style(), r)
		hud._draw_centered("ZENTR" if id == "recenter" else ("+" if id == "zoom_in" else "−"), r.get_center() + Vector2(0, 8), 10 if id == "recenter" else 26, LIGHT)
	if (layout.actions.minimap as Rect2).has_area():
		_minimap(hud, layout.actions.minimap, world, player)
	if BeginnerTeachingRuntime.show_objective_strip(player):
		_beginner_objective_strip(hud, layout, player)
	if BeginnerTeachingRuntime.show_first_session(player):
		hud._draw_first_session_guide(player,layout)
	_post_beginner_progress_strip(hud,layout,player)
	_trial_completion_chip(hud, layout, player)
	_havens_reach_first_dock(hud, layout, player)
	_guild_island_interaction(hud,layout,player)
	_halloween_event_interaction(hud,layout,player)
	for id in ["world", "group"]:
		var utility: Rect2 = layout.actions[id]
		if not utility.has_area():continue
		ring(hud, utility)
		icon(hud, id, utility)
	var auto_rect: Rect2 = layout.actions.auto_fire
	if auto_rect.has_area():
		hud.draw_style_box(box_style(), auto_rect)
		var voyage := player.get_node_or_null("Voyage") as VoyageProgress
		var unlocked: bool = voyage == null or voyage.auto_unlocked()
		hud._draw_centered("AUTO", auto_rect.get_center() + Vector2(0, -3), 11, LIGHT)
		hud._draw_centered("GESPERRT" if not unlocked else ("AN" if weapons.auto_fire else "AUS"), auto_rect.get_center() + Vector2(0, 13), 10, GREEN if weapons.auto_fire else LIGHT)
	var enemy := weapons.selected_target()
	if enemy != null and (layout.target_info as Rect2).has_area():
		var info: Rect2 = layout.target_info
		var target_frame_slot := TargetVisualCatalog.frame_slot(enemy)
		if not graphic_frame(hud, target_frame_slot, info):
			hud.draw_style_box(box_style(), info)
		var status := weapons.attack_status()
		var targeting := player.get_node("Targeting") as TargetingSystem
		var readiness := targeting.target_readiness(weapons.effective_range())
		var range_state := str(readiness.get("state", "NO_TARGET"))
		var state_label: String = str({"OPTIMAL":"OPTIMAL", "EDGE":"REICHWEITENGRENZE", "OUT":"AUSSER REICHWEITE", "NO_TARGET":"KEIN ZIEL"}.get(range_state, range_state))
		var state_color := GREEN if status == "BEREIT" and bool(readiness.get("in_range", false)) else (GOLD if range_state == "EDGE" else LIGHT)
		text(hud, "%s · %s" % [status, state_label], info.grow(-5), 11, state_color)
		var target_health := weapons.selected_target().get_node_or_null("Health") as ShipHealth if weapons.selected_target() != null else null
		if target_health != null:
			var target_states: Array[String] = []
			var now := Time.get_ticks_msec() / 1000.0
			for state_id in ["burn", "venom", "armor_break", "spectral_mark"]:
				if now < float(target_health.ammo_effect_until.get(state_id, 0.0)):
					target_states.append(state_id.replace("_", " ").to_upper())
			if target_health.repair_blocked(): target_states.append("REPAIR BLOCK")
			if not target_states.is_empty():
				text(hud, " · ".join(target_states.slice(0, 2)), Rect2(info.position + Vector2(4, info.size.y - 16), Vector2(info.size.x - 8, 15)), 9, GOLD)
		var relation := TargetVisualCatalog.relation_label(enemy)
		text(hud, relation, Rect2(info.position + Vector2(info.size.x - 78, 5), Vector2(72, 18)), 9, GOLD if relation in ["ELITE","ADMIRAL","MONSTER","ALARM"] else LIGHT)
		if relation=="ALARM":
			text(hud,"NPC REAGIERT",Rect2(info.position+Vector2(5,info.size.y-43),Vector2(info.size.x-10,14)),9,RED)
		elif relation in ["ADMIRAL","MONSTER"]:
			var phase:=int(enemy.get_meta("boss_phase",1))
			text(hud,"PHASE %d"%phase,Rect2(info.position+Vector2(5,info.size.y-43),Vector2(info.size.x-10,14)),9,GOLD)
		if target_health != null:
			var hp_rect := Rect2(info.position + Vector2(7, info.size.y - 29), Vector2(info.size.x - 14, 8))
			bar(hud, hp_rect, target_health.normalized(), GREEN)
			if target_health.max_shield > 0.0:
				var shield_ratio := clampf(target_health.current_shield / target_health.max_shield, 0.0, 1.0)
				bar(hud, Rect2(hp_rect.position + Vector2(0, 11), hp_rect.size), shield_ratio, BLUE)
		if not compact:
			text(hud, "DIST %.0fm · RANGE %.0fm · %s" % [float(readiness.get("distance", 0.0)), float(readiness.get("range", weapons.effective_range())), weapons.ammo_name()], Rect2(info.position + Vector2(5, 24), info.size - Vector2(10, 24)), 11)
	_draw_m281_combat_convergence(hud, layout, player, weapons, enemy, ui_scale)
	_draw_m282_combat_event_feedback(hud, layout, ui_scale)
	_draw_m283_projectile_salvo_presentation(hud, layout, ui_scale)
	_draw_m284_naval_combat_identity(hud, layout, ui_scale)
	_draw_m285_ship_damage_defeat_presentation(hud, layout, ui_scale)
	_draw_m286_ship_damage_escalation(hud, layout, ui_scale)
	_draw_m287_ship_motion_identity(hud, layout, ui_scale)
	_draw_m288_naval_contact_readability(hud, layout, ui_scale)
	if enemy != null and bool(enemy.get_meta("first_monster_teaching",false)):
		_first_monster_teaching(hud,layout,player,weapons,enemy)
	_input_affordances(hud,layout)
	var event_runtime := hud.get_tree().get_first_node_in_group("event_runtime") as EventRuntime
	if event_runtime != null and event_runtime.is_active():
		_event_chip(hud, layout, event_runtime)
		# M180: mobile keeps one event summary. Full quest detail lives in MENU > EVENTS.
		if not compact and not bool(layout.get("touch_density",false)):
			_event_quest_strip(hud, layout, event_runtime)
	if (layout.wheel as Rect2).has_area():
		_wheel(hud, layout.wheel, input)
	_active_status_chips(hud, layout, player, health, input)
	_quickslot_bar(hud, layout, player, weapons, inventory, input)
	for id in ["fire", "repair", "boost", "target", "ammo_0", "ammo_1", "ammo_2"]:
		var r: Rect2 = layout.actions[id]
		if r.size.x <= 1.0: continue
		var selected: bool = id == "fire" or (weapons.weapon_mode == "cannon" and id == "ammo_%d" % weapons.ammo_index)
		ring(hud, r, selected)
		icon(hud, id, r)
		var count := ""
		if id.begins_with("ammo_"):
			var ammo_row:=CombatCatalog.ammo(int(id.right(1))); count = str(inventory.count(str(ammo_row.get("id","iron"))))
			hud._draw_centered(str(CombatCatalog.ammo(int(id.right(1))).get("name","Ammo")).left(8).to_upper(), r.get_center() - Vector2(0, r.size.y * 0.5 + 6 * ui_scale), roundi(10 * ui_scale), LIGHT)
		elif id == "repair": count = str(input.repair_charges)
		elif id == "boost": count = str(inventory.count("boost"))
		elif id == "target": count = "HAFEN" if player.has_meta("nearby_port") else "ZIEL"
		elif id == "fire":
			var fire_status := weapons.attack_status()
			if weapons.reload_progress() < 1:
				count = "%d %%" % roundi(weapons.reload_progress() * 100)
			elif fire_status == "BEREIT":
				count = "HARPUNE" if weapons.weapon_mode == "harpoon" else "FEUER"
			elif fire_status == "ZU WEIT":
				count = "ZU WEIT"
			elif fire_status == "MUNITION LEER":
				count = "LEER"
			else:
				count = fire_status.left(10)
		if not count.is_empty():
			hud._draw_centered(count, r.get_center() + Vector2(0, r.size.y * 0.5 - 6 * ui_scale), roundi(12 * ui_scale), TEXT)
		if id in ["fire", "boost"]:
			var progress := weapons.reload_progress() if id == "fire" else input.ability_progress()
			hud.draw_arc(r.get_center(), r.size.x * 0.5 + 2, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, BLUE, maxf(2.0, 2.0 * ui_scale), true)
			if id == "fire" and progress >= 1.0 and weapons.attack_status() == "BEREIT":
				# M249 subtle readiness pulse; visual only, does not affect reload or attack authority.
				var pulse := 0.42 + 0.22 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.007))
				hud.draw_arc(r.get_center(), r.size.x * 0.5 + 5.0 * ui_scale, 0.0, TAU, 48, Color(GREEN.r, GREEN.g, GREEN.b, pulse), maxf(1.5, 2.0 * ui_scale), true)
	# M39 large selectors: responsive current-ammunition and item/supply menu.
	var ammo_button: Rect2 = layout.actions.ammo_menu
	if ammo_button.has_area():
		ring(hud, ammo_button, not hud.combat_picker.is_empty() and hud.combat_picker == "ammo")
		icon(hud, "harpoon" if weapons.weapon_mode == "harpoon" else "ammo_%d" % weapons.ammo_index, ammo_button)
		hud._draw_centered("MUNITION", ammo_button.get_center() + Vector2(0, ammo_button.size.y * 0.5 - 7 * ui_scale), roundi(9 * ui_scale), LIGHT)
		hud._draw_centered(str(inventory.count(weapons.ammo_id())), ammo_button.get_center() - Vector2(0, ammo_button.size.y * 0.5 - 9 * ui_scale), roundi(11 * ui_scale), TEXT)
	var items_button: Rect2 = layout.actions.items_menu
	if items_button.has_area():
		ring(hud, items_button, not hud.combat_picker.is_empty() and hud.combat_picker == "items")
		icon(hud, "repair", items_button)
		hud._draw_centered("ITEMS", items_button.get_center() + Vector2(0, items_button.size.y * 0.5 - 7 * ui_scale), roundi(9 * ui_scale), LIGHT)
	if not hud.combat_picker.is_empty():
		_combat_picker(hud, player, weapons, inventory)
	if hud.log_visible() and (layout.log as Rect2).has_area():
		hud.draw_style_box(box_style(), layout.log)
		text(hud, "LOKALES LOGBUCH · OFFLINE", Rect2((layout.log as Rect2).position + Vector2(9, 7), Vector2((layout.log as Rect2).size.x - 18, 20)), 11, LIGHT)
		for index in mini(hud.recent_log.size(), 3):
			text(hud, hud.recent_log[index], Rect2((layout.log as Rect2).position + Vector2(9, 30 + index * 22), Vector2((layout.log as Rect2).size.x - 18, 20)), 11)
	hud._draw_combat_feedback(safe, 1, player, layout.top)
	if health.is_sunk:
		_draw_defeat_overlay(hud, safe, player, ui_scale)
	if hud.notice_until > Time.get_ticks_msec():
		_draw_notice(hud, layout, ui_scale)
	_draw_m280_reward_visual(hud, layout, ui_scale)
	if world != null and world.transition_message_time > 0 and (world.transition_message == "WORLD EDGE" or ClientSettings.show_map_transition(hud.get_tree())):
		hud._draw_centered(world.transition_message, Vector2(safe.get_center().x, (layout.top as Rect2).end.y + 27), 15, LIGHT)
	if player.get_meta("in_safe_zone", false) and player.has_meta("nearby_port"):
		hud._draw_centered("SICHERER HAFEN · LOKALE HAFENINTERAKTION VERFÜGBAR", Vector2(safe.get_center().x, (layout.top as Rect2).end.y + 48.0 * ui_scale), roundi(11.0 * ui_scale), GREEN)
	if hud.global_map_open:
		hud._draw_global_map(safe, clampf(safe.size.y / 720, 0.7, 1.3), world)
	elif progression.shop_open:
		hud._draw_shop(safe, clampf(safe.size.y / 720, 0.7, 1.3), progression)
	if bool(hud.get_tree().root.get_meta("app_suspended", false)):
		hud.draw_rect(safe, Color(0, 0, 0, 0.72))
		hud._draw_centered("PAUSE", safe.get_center(), 25, TEXT)


static func _draw_m281_combat_convergence(hud:GameHud, layout:Dictionary, player:ShipMotor, weapons:ShipWeapons, enemy:Node3D, ui_scale:float) -> void:
	var view:Dictionary=hud.m281_combat_hud_state
	var safe:Rect2=layout.safe
	var compact:=bool(layout.compact)
	# Existing local prototype combat remains visible when no authoritative replica is bound.
	# M281 only adds authoritative emphasis when all M269/M270/M271 replicas agree.
	if not view.is_empty() and str(view.get("source",""))=="SERVER":
		var info:Rect2=layout.target_info
		if enemy!=null and info.has_area():
			var legal:=bool(view.get("target_legal",false))
			var accent:=GREEN if legal else GOLD
			hud.draw_line(Vector2(info.position.x,info.end.y+3.0*ui_scale),Vector2(info.end.x,info.end.y+3.0*ui_scale),accent,maxf(2.0,2.0*ui_scale),true)
			var relationship:=str(view.get("relationship","UNKNOWN"))
			if relationship!="UNKNOWN": text(hud,relationship,Rect2(info.position+Vector2(5,info.size.y-58),Vector2(info.size.x-10,14)),roundi(9*ui_scale),accent)
			var phase:=int(view.get("boss_phase",0)); var telegraph:=str(view.get("telegraph",""))
			if phase>0 or not telegraph.is_empty():
				var msg:=("PHASE %d"%phase if phase>0 else "GEFAHR") + ((" · "+telegraph.left(24)) if not telegraph.is_empty() else "")
				text(hud,msg,Rect2(info.position+Vector2(5,-18*ui_scale),Vector2(info.size.x-10,16*ui_scale)),roundi(10*ui_scale),GOLD)
		var effects:Array=view.get("status_effects",[]) as Array
		if not effects.is_empty():
			var max_chips:=2 if compact else 4
			var chip_y:=(layout.top as Rect2).end.y + 8.0*ui_scale
			var x:=safe.position.x+12.0*ui_scale
			for i in mini(effects.size(),max_chips):
				var row:Dictionary=effects[i] as Dictionary; var label:=str(row.get("label","STATUS")).left(15)
				var w:=maxf(72.0*ui_scale,(label.length()*6.5+18.0)*ui_scale)
				var r:=Rect2(Vector2(x,chip_y),Vector2(w,24.0*ui_scale)); hud.draw_style_box(panel(Color(0.02,0.045,0.06,0.94),LIGHT,8.0),r); text(hud,label,r.grow(-6.0*ui_scale),roundi(9.0*ui_scale),TEXT); x+=w+6.0*ui_scale
	# Local visual polish: keep current ammo identity directly coupled to the primary fire cluster.
	var fire_rect:Rect2=layout.actions.fire
	if fire_rect.has_area():
		var ammo_label: String = ("HARPUNE" if weapons.weapon_mode=="harpoon" else weapons.ammo_name()).left(13).to_upper()
		var label_rect:=Rect2(Vector2(fire_rect.position.x-8.0*ui_scale,fire_rect.position.y-24.0*ui_scale),Vector2(fire_rect.size.x+16.0*ui_scale,18.0*ui_scale))
		hud.draw_style_box(panel(Color(0.015,0.04,0.055,0.90),GOLD,7.0),label_rect)
		hud._draw_centered(ammo_label,label_rect.get_center()+Vector2(0,4.0*ui_scale),roundi(9.0*ui_scale),LIGHT)


static func _draw_m282_combat_event_feedback(hud:GameHud, layout:Dictionary, ui_scale:float) -> void:
	var view:Dictionary=hud.m282_combat_feedback_state
	if view.is_empty() or str(view.get("source",""))!="SERVER": return
	var entries:Array=view.get("entries",[]) as Array
	if entries.is_empty(): return
	var safe:Rect2=layout.safe; var compact:=bool(layout.compact); var target_info:Rect2=layout.target_info
	# Latest confirmed result stays target-proximate; never becomes a center-screen number wall.
	var latest:Dictionary=view.get("latest",{}) as Dictionary; var kind:=str(latest.get("kind","HIT")).to_upper(); var amount:=float(latest.get("resolved_amount",0.0))
	var accent:=GREEN if kind in ["HEAL","HOT_TICK","REPAIR_APPLIED","SHIELD_APPLIED"] else (GOLD if kind=="CRITICAL" else (Color("8fb5cf") if kind in ["BLOCKED","MISS"] else TEXT))
	var result_text:=kind.replace("_"," ")
	if amount>0.0: result_text += "  %.0f"%amount
	if int(latest.get("event_count",1))>1: result_text += "  ×%d"%int(latest.get("event_count",1))
	if target_info.has_area():
		var result_rect:=Rect2(Vector2(target_info.position.x,target_info.end.y+9.0*ui_scale),Vector2(target_info.size.x,22.0*ui_scale))
		hud.draw_style_box(panel(Color(0.012,0.035,0.05,0.90),accent,7.0),result_rect)
		hud._draw_centered(result_text,result_rect.get_center()+Vector2(0,4.0*ui_scale),roundi((10 if compact else 12)*ui_scale),accent)
	# Small chronological feed hugs the safe-area edge; repeated hits/heals are already coalesced by M282 runtime.
	var feed_w:=minf((190.0 if compact else 250.0)*ui_scale,safe.size.x*0.34)
	var row_h:=(22.0 if compact else 25.0)*ui_scale
	var feed_x:=safe.end.x-feed_w-12.0*ui_scale; var feed_y:=(layout.top as Rect2).end.y+10.0*ui_scale
	for i in entries.size():
		var row:Dictionary=entries[entries.size()-1-i] as Dictionary; var rk:=str(row.get("kind","HIT")).to_upper(); var ra:=float(row.get("resolved_amount",0.0)); var count:=int(row.get("event_count",1))
		var label:=rk.replace("_"," "); if ra>0.0: label += " %.0f"%ra; if count>1: label += " ×%d"%count
		var rr:=Rect2(Vector2(feed_x,feed_y+i*(row_h+4.0*ui_scale)),Vector2(feed_w,row_h)); hud.draw_style_box(panel(Color(0.01,0.028,0.04,0.82),Color("516b76"),6.0),rr); text(hud,label,rr.grow(-6.0*ui_scale),roundi((8 if compact else 9)*ui_scale),TEXT)
	# impact_vfx_hook is a presentation hook only; actual authored VFX remain asset/content-driven.


static func _draw_m283_projectile_salvo_presentation(hud:GameHud, layout:Dictionary, ui_scale:float) -> void:
	var view:Dictionary=hud.m283_projectile_presentation_state
	if view.is_empty() or str(view.get("source",""))!="SERVER": return
	var impacts:Array=view.get("impacts",[]) as Array
	if impacts.is_empty(): return
	var target_info:Rect2=layout.target_info
	if not target_info.has_area(): return
	var latest:Dictionary=impacts[-1] as Dictionary
	var kind:=str(latest.get("kind","PROJECTILE_IMPACT")).replace("_"," ")
	var family:=str(latest.get("weapon_family",latest.get("source_family",""))).to_upper()
	var label:=(family+" · " if not family.is_empty() else "")+kind
	var rect:=Rect2(Vector2(target_info.position.x,target_info.end.y+34.0*ui_scale),Vector2(target_info.size.x,18.0*ui_scale))
	hud.draw_style_box(panel(Color(0.008,0.025,0.038,0.78),Color("6f8792"),6.0),rect)
	hud._draw_centered(label.left(34),rect.get_center()+Vector2(0,3.0*ui_scale),roundi(8.0*ui_scale),LIGHT)
	# Authored travel/impact VFX, audio and haptics are hook-driven elsewhere; this HUD mark only exposes confirmed presentation state.

static func _draw_m280_reward_visual(hud: GameHud, layout: Dictionary, ui_scale: float) -> void:
	var view: Dictionary = hud.m280_reward_visual_state
	if view.is_empty() or str(view.get("source", "")) != "SERVER": return
	var rect: Rect2 = view.get("rect", Rect2())
	if not rect.has_area(): return
	var emphasis := str(view.get("emphasis", "STANDARD")).to_upper()
	var accent := GOLD if emphasis in ["BOSS", "ADMIRAL", "HIGH"] else LIGHT
	hud.draw_style_box(panel(Color(0.015, 0.035, 0.05, 0.965), accent, 14.0), rect)
	var icon_asset_id := str(view.get("icon_asset_id", ""))
	var icon_rect := Rect2(rect.position + Vector2(10, 10) * ui_scale, Vector2.ONE * minf(48.0 * ui_scale, rect.size.y - 20.0 * ui_scale))
	if not icon_asset_id.is_empty():
		var tex := VisualAssetCatalog.texture(icon_asset_id)
		if tex != null: hud.draw_texture_rect(tex, icon_rect, false)
	var text_x := rect.position.x + (68.0 if not icon_asset_id.is_empty() else 16.0) * ui_scale
	text(hud, str(view.get("title", "BELOHNUNG BESTÄTIGT")), Rect2(Vector2(text_x, rect.position.y + 12.0 * ui_scale), Vector2(rect.end.x-text_x-12.0*ui_scale, 22.0*ui_scale)), roundi(14.0*ui_scale), accent)
	var detail := str(view.get("subtitle", ""))
	var qty := str(view.get("quantity_text", ""))
	if not qty.is_empty(): detail = (detail + " · " if not detail.is_empty() else "") + qty
	if not detail.is_empty(): text(hud, detail, Rect2(Vector2(text_x, rect.position.y + 38.0 * ui_scale), Vector2(rect.end.x-text_x-12.0*ui_scale, 20.0*ui_scale)), roundi(11.0*ui_scale), TEXT)
	var badge := int(view.get("inbox_badge_count", 0))
	if badge > 0: hud._draw_centered(str(badge), rect.position + Vector2(rect.size.x - 20.0*ui_scale, 18.0*ui_scale), roundi(10.0*ui_scale), Color.WHITE)


static func _draw_notice(hud: GameHud, layout: Dictionary, ui_scale: float) -> void:
	var safe: Rect2 = layout.safe
	var message := hud.active_notice if not hud.active_notice.is_empty() else hud.recent_log[0]
	if hud.notice_family in ["reward", "respawn", "defeat"]:
		var accent := RED if hud.notice_family == "defeat" else (GREEN if hud.notice_family == "respawn" else GOLD)
		var width := minf(620.0 * ui_scale, safe.size.x - 28.0 * ui_scale)
		var height := 62.0 * ui_scale
		var rect := Rect2(Vector2(safe.get_center().x - width * 0.5, (layout.top as Rect2).end.y + 12.0 * ui_scale), Vector2(width, height))
		hud.draw_style_box(panel(Color(0.015, 0.04, 0.055, 0.96), accent, 12.0), rect)
		hud._draw_centered(message, rect.get_center() + Vector2(0, 6.0 * ui_scale), roundi(16.0 * ui_scale), Color.WHITE)
	else:
		hud._draw_centered(message, Vector2(safe.get_center().x, (layout.top as Rect2).end.y + 25), roundi(12.0 * ui_scale), LIGHT)


static func _draw_defeat_overlay(hud: GameHud, safe: Rect2, player: ShipMotor, ui_scale: float) -> void:
	hud.draw_rect(safe, Color(0.01, 0.015, 0.025, 0.62), true)
	var width := minf(470.0 * ui_scale, safe.size.x - 32.0 * ui_scale)
	var rect := Rect2(safe.get_center() - Vector2(width, 150.0 * ui_scale) * 0.5, Vector2(width, 150.0 * ui_scale))
	hud.draw_style_box(panel(Color(0.035, 0.025, 0.03, 0.97), RED, 16.0), rect)
	hud._draw_centered("SCHIFF VERSENKT", rect.position + Vector2(rect.size.x * 0.5, 48.0 * ui_scale), roundi(24.0 * ui_scale), Color.WHITE)
	var remaining := maxi(0, int(player.get_meta("respawn_at_msec", Time.get_ticks_msec())) - Time.get_ticks_msec())
	var seconds := maxf(0.0, remaining / 1000.0)
	hud._draw_centered("Rückkehr zum sicheren Hafen in %.1f s" % seconds, rect.position + Vector2(rect.size.x * 0.5, 90.0 * ui_scale), roundi(15.0 * ui_scale), LIGHT)
	hud._draw_centered("Gegnerkontakt wird getrennt", rect.position + Vector2(rect.size.x * 0.5, 119.0 * ui_scale), roundi(12.0 * ui_scale), TEXT)


static func _event_quest_strip(hud:GameHud,layout:Dictionary,runtime:EventRuntime)->void:
	var safe:Rect2=layout.safe
	var sx:=float(layout.get("ui_scale",1.0))
	var compact:=bool(layout.compact)
	var rows:=runtime.relevant_quests(1 if compact else 2)
	if rows.is_empty():return
	var width:=minf((250.0 if compact else 310.0)*sx,safe.size.x*0.44)
	var height:=(34.0+rows.size()*24.0)*sx
	var rect:=Rect2(Vector2(safe.end.x-width-10*sx,safe.position.y+(120 if compact else 104)*sx),Vector2(width,height))
	hud.draw_rect(rect,Color(0.025,0.055,0.05,0.90),true)
	hud.draw_rect(rect,Color("789d55"),false,maxf(1.0,1.5*sx))
	text(hud,"NIGHT OF THE DROWNED · AUFTRÄGE",Rect2(rect.position+Vector2(8,7)*sx,Vector2(rect.size.x-16*sx,18*sx)),roundi(9*sx),LIGHT)
	for i in rows.size():
		var q:Dictionary=rows[i]
		var id:=str(q.get("id",""))
		var label:=str(q.get("label",""))
		if label.length()>31:label=label.left(29)+"…"
		text(hud,"%s  %s"%[label,runtime.quest_progress_text(id)],Rect2(rect.position+Vector2(8,29+i*23)*sx,Vector2(rect.size.x-16*sx,18*sx)),roundi(9*sx),TEXT)

static func _objective_icon(kind: String) -> String:
	return {
		"sink":"m70_tutorial_attack", "event_sink":"m70_tutorial_attack",
		"loot":"m72_poi_salvage", "dock":"m70_tutorial_harbor",
		"event_explore":"m94_halloween_quest", "event_monster_hit":"m95_event_target",
	}.get(kind, "m72_poi_objective_frame")

static func _halloween_event_interaction(hud:GameHud,layout:Dictionary,player:ShipMotor)->void:
	var data:=hud.halloween_event_interaction_layout()
	if data.is_empty():return
	var rect:Rect2=data.button
	var sx:=float(data.ui_scale)
	var prompt:Dictionary=data.prompt
	hud.draw_rect(rect,Color(0.035,0.065,0.055,0.95),true)
	hud.draw_rect(rect,Color("86ba5b"),false,maxf(1.0,2.0*sx))
	var icon_tex:=VisualAssetCatalog.texture("m94_halloween_quest" if str(prompt.get("id",""))=="event_halloween_wreck_01" else "m94_halloween_event")
	if icon_tex!=null:hud.draw_texture_rect(icon_tex,Rect2(rect.position+Vector2(8,8)*sx,Vector2.ONE*36*sx),false)
	text(hud,"%s · %s"%[str(prompt.get("title","HALLOWEEN")),str(prompt.get("action","INTERAGIEREN"))],
		Rect2(rect.position+Vector2(52,8)*sx,Vector2(rect.size.x-60*sx,20*sx)),roundi(11*sx),LIGHT)
	text(hud,"%.0fm · lokale Event-Interaktion"%float(prompt.get("distance",0.0)),
		Rect2(rect.position+Vector2(52,29)*sx,Vector2(rect.size.x-60*sx,17*sx)),roundi(9*sx),TEXT)

static func _guild_island_interaction(hud:GameHud,layout:Dictionary,player:ShipMotor)->void:
	var data:=hud.guild_island_interaction_layout()
	if data.is_empty():return
	var panel:Rect2=data.panel
	var sx:=float(data.ui_scale)
	var prompt:Dictionary=data.prompt
	if not graphic_frame(hud,"hud_quickslot_frame",panel):
		hud.draw_style_box(box_style(),panel)
	var icon_tex:=VisualAssetCatalog.texture("m89_guild_island")
	if icon_tex!=null:
		hud.draw_texture_rect(icon_tex,Rect2(panel.position+Vector2(8,7)*sx,Vector2.ONE*30.0*sx),false)
	text(hud,"%s · %s"%[str(prompt.get("title","GILDENINSEL")),str(prompt.get("relation","NEUTRAL"))],
		Rect2(panel.position+Vector2(44,7)*sx,Vector2(panel.size.x-52*sx,18*sx)),roundi(11*sx),GOLD)
	text(hud,str(prompt.get("subtitle","")),Rect2(panel.position+Vector2(44,23)*sx,Vector2(panel.size.x-52*sx,16*sx)),roundi(9*sx),TEXT.darkened(0.12))
	for action_id in data.rows:
		var row:Rect2=data.rows[action_id]
		hud.draw_rect(row,Color(0.035,0.09,0.12,0.92),true)
		hud.draw_rect(row,Color("70532b"),false,maxf(1.0,1.5*sx))
		var action_icon:=VisualAssetCatalog.texture(hud.guild_island_action_icon(str(action_id)))
		var tx:=12.0
		if action_icon!=null:
			hud.draw_texture_rect(action_icon,Rect2(row.position+Vector2(8,7)*sx,Vector2.ONE*28*sx),false)
			tx=42.0
		var label:=str(action_id).replace("inspect_","").replace("_"," ").to_upper()
		for entry in prompt.get("actions",[]):
			if str(entry.get("id",""))==str(action_id):label=str(entry.get("label",label))
		text(hud,label,Rect2(row.position+Vector2(tx,11)*sx,Vector2(row.size.x-(tx+12)*sx,22*sx)),roundi(11*sx),LIGHT)
	var panel_data:=hud.guild_island_panel_data()
	if panel_data.is_empty():return
	var rows:Array=panel_data.get("rows",[])
	if rows.is_empty():return
	var detail_layout:=hud.guild_island_detail_layout()
	if detail_layout.is_empty():return
	var detail:Rect2=detail_layout.panel
	hud.draw_rect(detail,Color(0.02,0.05,0.07,0.97),true)
	hud.draw_rect(detail,Color("d7a94f"),false,maxf(1.0,2.0*sx))
	text(hud,str(panel_data.get("label","DETAILS")),Rect2(detail.position+Vector2(10,8)*sx,Vector2(detail.size.x-20*sx,20*sx)),roundi(12*sx),GOLD)
	var selected:=hud.guild_island_selected_row()
	var island:=GuildIslandInteraction.nearest(player)
	var visible_indices:Array=detail_layout.get("row_indices",[])
	for i in visible_indices.size():
		var absolute_index:=int(visible_indices[i])
		if absolute_index<0 or absolute_index>=rows.size():continue
		var row:Dictionary=rows[absolute_index]
		var focused:=row==selected
		var line:=""
		if row.has("role"):
			line="%s%s · %.0fm · %.1fs · %s"%[("▶ " if focused else ""),str(row.role).to_upper(),float(row.range),float(row.reload),"LIVE AUS" if not bool(row.live_damage) else "LIVE"]
		else:
			line="%s%s · T%d · %s%s"%[("▶ " if focused else ""),str(row.get("label",row.get("id",""))),int(row.get("visual_tier",1)),str(row.get("visual_damage_state","intact")).to_upper(),(" · SERVER" if bool(row.get("server_required",false)) else "")]
		text(hud,line,Rect2(detail.position+Vector2(10,31+i*31)*sx,Vector2(detail.size.x-20*sx,24*sx)),roundi(10*sx),GOLD if focused else TEXT)
	if island!=null:
		var layer:=island.get_node_or_null("M91VisualState")
		if layer!=null:
			for child in layer.get_children():
				if child is MeshInstance3D and str(child.name).begins_with("Range_"):
					child.visible=not selected.is_empty() and selected.has("role") and str(child.name)=="Range_"+str(selected.get("role",""))

static func _combat_picker(hud: GameHud, player: ShipMotor, weapons: ShipWeapons, inventory: PlayerInventory) -> void:
	var data := hud.combat_picker_layout()
	var panel: Rect2 = data.panel
	var sx: float = float(data.ui_scale)
	# dark modal veil keeps the sea visible but makes large touch rows readable
	hud.draw_rect(hud.layout().safe, Color(0, 0, 0, 0.34))
	if not graphic_frame(hud, "hud_ammo_selector_frame", panel):
		hud.draw_style_box(box_style(), panel)
	var title := "MUNITION & HARPUNEN" if hud.combat_picker == "ammo" else "ITEMS & VORRÄTE"
	text(hud, title, Rect2(panel.position + Vector2(16, 9) * sx, Vector2(panel.size.x - 180 * sx, 34 * sx)), roundi(18 * sx), LIGHT)
	text(hud, "ANTIPPEN = WÄHLEN · HALTEN = DETAILS / QUICKSLOT", Rect2(panel.position + Vector2(16, 33) * sx, Vector2(panel.size.x - 180 * sx, 20 * sx)), roundi(9 * sx), TEXT.darkened(0.18))
	var close_rect: Rect2 = data.close
	hud.draw_style_box(box_style(), close_rect)
	hud._draw_centered("×", close_rect.get_center() + Vector2(0, 3 * sx), roundi(24 * sx), LIGHT)
	# M171: presentation comes from runtime definitions rather than a fixed legacy dictionary.
	var labels: Dictionary = {"harpoon":"Jagdharpune", "powder":"Schwarzpulver", "plates":"Panzerplatten"}
	var descriptions: Dictionary = {"harpoon":"Monster-/Jagdwaffe", "powder":"Verstärkt gültige Kanonensalven", "plates":"Reduziert gültigen eingehenden Schaden"}
	for ammo_row in CombatCatalog.ammo_rows():
		if ammo_row is Dictionary:
			var ammo_id := str(ammo_row.get("id", ""))
			labels[ammo_id] = str(ammo_row.get("name", ammo_id.replace("_", " ").capitalize()))
			descriptions[ammo_id] = str(ammo_row.get("role", "tactical")).replace("_", " ").capitalize()
	for payload in SupportPayloadCatalog.harpoon_payloads():
		if payload is Dictionary:
			var payload_id := str(payload.get("id", "")); labels[payload_id] = str(payload.get("name", payload_id.replace("_", " ").capitalize())); descriptions[payload_id] = str(payload.get("role", "Harpoon payload")).replace("_", " ").capitalize()
	for support in SupportPayloadCatalog.support_ammo():
		if support is Dictionary:
			var support_id := str(support.get("id", "")); labels[support_id] = str(support.get("name", support_id.replace("_", " ").capitalize())); descriptions[support_id] = str(support.get("role", "Support ammunition")).replace("_", " ").capitalize()
	for action_id in ActionItemCatalog.item_ids():
		var action_def := ActionItemCatalog.item(action_id)
		if not action_def.is_empty():
			labels[action_id] = str(action_def.get("name", action_id.replace("_", " ").capitalize()))
			descriptions[action_id] = str(action_def.get("category", "action item")).replace("_", " ").capitalize() + " · " + str(action_def.get("effect", "utility")).replace("_", " ").capitalize()
	for id in data.rows:
		var row: Rect2 = data.rows[id]
		var active := false
		if CombatCatalog.ammo_index_by_id(id)>=0: active = weapons.weapon_mode == "cannon" and weapons.ammo_id() == id
		elif id == "harpoon": active = weapons.weapon_mode == "harpoon"
		elif id == "powder": active = inventory.powder_enabled
		elif id == "plates": active = inventory.plates_enabled
		hud.draw_rect(row, Color(0.07, 0.12, 0.16, 0.96) if not active else Color(0.18, 0.14, 0.06, 0.96), true)
		hud.draw_rect(row, LIGHT if active else Color("70532b"), false, maxf(1.0, 2.0 * sx))
		# M203: fast-scanning category rail; presentation only, identical content on every platform.
		var category_accent := Color("47c6d9") if CombatCatalog.ammo_index_by_id(id) >= 0 else (Color("63c8b5") if id == "harpoon" or id in ["hunter_standard", "barbed_chain", "abyss_piercer"] else Color("d6a84f"))
		hud.draw_rect(Rect2(row.position + Vector2(3, 7) * sx, Vector2(4, row.size.y / sx - 14) * sx), category_accent, true)
		var icon_rect := Rect2(row.position + Vector2(11, 9) * sx, Vector2(50, 50) * sx)
		var icon_id := M210InterfaceAssetRuntimeCatalog.item_slot(id)
		icon(hud, icon_id, icon_rect)
		var input := player.get_node("PlayerInput") as PlayerShipInput
		var definition := ActionItemCatalog.item(id)
		var cooldown := input.item_cooldown_remaining(id) if not definition.is_empty() else 0.0
		if cooldown > 0.05:
			var progress := input.item_cooldown_progress(id)
			hud.draw_circle(icon_rect.get_center(), icon_rect.size.x * 0.42, Color(0, 0, 0, 0.42))
			hud.draw_arc(icon_rect.get_center(), icon_rect.size.x * 0.45, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, Color("ffd98a"), maxf(2.0, 3.0 * sx), true)
		text(hud, labels.get(id, str(id)), Rect2(row.position + Vector2(68, 9) * sx, Vector2(row.size.x - 126 * sx, 24 * sx)), roundi(15 * sx), LIGHT if active else TEXT)
		text(hud, descriptions.get(id, ""), Rect2(row.position + Vector2(68, 34) * sx, Vector2(row.size.x - 126 * sx, 28 * sx)), roundi(10 * sx), TEXT.darkened(0.12))
		var count := inventory.count(id)
		var suffix := "AN" if active and id in ["powder", "plates"] else (("%.0fs" % ceil(cooldown)) if cooldown > 0.05 else str(count))
		hud._draw_centered(suffix, Vector2(row.end.x - 34 * sx, row.get_center().y + 5 * sx), roundi(14 * sx), Color("ef8354") if cooldown > 0.05 else (GREEN if active else LIGHT))

	if not hud.combat_detail_id.is_empty():
		_combat_detail_card(hud, player, weapons, inventory, data)

static func _combat_detail_card(hud: GameHud, player: ShipMotor, weapons: ShipWeapons, inventory: PlayerInventory, data: Dictionary) -> void:
	var id := hud.combat_detail_id
	var panel: Rect2 = data.panel
	var sx: float = float(data.ui_scale)
	var rect := Rect2(panel.position + Vector2(18, 58) * sx, panel.size - Vector2(36, 76) * sx)
	hud.draw_rect(rect, Color(0.025, 0.055, 0.08, 0.985), true)
	hud.draw_rect(rect, Color("d7a94f"), false, maxf(1.0, 2.0 * sx))
	var icon_rect := Rect2(rect.position + Vector2(16, 16) * sx, Vector2(64, 64) * sx)
	icon(hud, CombatUiIconCatalog.slot(id), icon_rect)
	var name := id.replace("_", " ").capitalize()
	var category := "SUPPLY"
	var lines: Array[String] = []
	if CombatCatalog.ammo_index_by_id(id) >= 0:
		var idx := CombatCatalog.ammo_index_by_id(id)
		var ammo := CombatCatalog.ammo(idx)
		name = str(ammo.get("name", name))
		category = "KANONENMUNITION · " + str(ammo.get("role", "TACTICAL")).replace("_", " ").to_upper()
		lines.append("Schaden x%.2f · Reichweite x%.2f" % [float(ammo.get("damage", 1.0)), float(ammo.get("range", 1.0))])
		lines.append("Armor Penetration %.0f%% · Crit %.0f%%" % [float(ammo.get("armor_pierce", 0.0)) * 100.0, float(ammo.get("crit", 0.0)) * 100.0])
		if float(ammo.get("slow", 0.0)) > 0.0: lines.append("Slow %.0f%%" % (float(ammo.slow) * 100.0))
		var effect := str(ammo.get("effect", "none"))
		if effect != "none": lines.append("Effekt: %s · %.1fs" % [effect.replace("_", " ").to_upper(), float(ammo.get("effect_duration", 0.0))])
	elif id == "harpoon":
		name = "Jagdharpune"; category = "MONSTERWAFFE"
		lines = ["Primär gegen Meeresmonster", "Eigene Range-/Reload-Routingregeln"]
	else:
		var item := ActionItemCatalog.item(id)
		if not item.is_empty():
			name = str(item.get("name", name))
			category = str(item.get("category", "action item")).replace("_", " ").to_upper()
			lines.append("Effekt: " + str(item.get("effect", "")).replace("_", " ").to_upper())
			if item.has("damage"): lines.append("Wirkung %.0f" % float(item.damage))
			if item.has("amount"): lines.append("Stärke %.0f" % float(item.amount))
			if item.has("duration"): lines.append("Dauer %.1fs" % float(item.duration))
			if item.has("range"): lines.append("Reichweite %.0fm" % float(item.range))
			if item.has("cooldown"): lines.append("Cooldown %.0fs" % float(item.cooldown))
		else:
			lines.append("Aktivierbarer Schiffssupply")
	text(hud, name, Rect2(rect.position + Vector2(94, 16) * sx, Vector2(rect.size.x - 154 * sx, 30 * sx)), roundi(20 * sx), LIGHT)
	text(hud, category, Rect2(rect.position + Vector2(94, 47) * sx, Vector2(rect.size.x - 154 * sx, 22 * sx)), roundi(10 * sx), Color("d7a94f"))
	var y := 98.0 * sx
	for line in lines:
		text(hud, "• " + line, Rect2(rect.position + Vector2(18, y) , Vector2(rect.size.x - 36 * sx, 24 * sx)), roundi(12 * sx), TEXT)
		y += 27.0 * sx
	text(hud, "Bestand: %d" % inventory.count(id), Rect2(rect.position + Vector2(18, rect.size.y - 56 * sx), Vector2(rect.size.x - 90 * sx, 24 * sx)), roundi(13 * sx), GREEN)
	text(hud, "Quelle: Early Harbor / Gameplay", Rect2(rect.position + Vector2(18, rect.size.y - 78 * sx), Vector2(rect.size.x - 90 * sx, 20 * sx)), roundi(10 * sx), TEXT.darkened(0.16))
	text(hud, "ALS QUICKSLOT SPEICHERN", Rect2(rect.position + Vector2(18, rect.size.y - 58 * sx), Vector2(220 * sx, 18 * sx)), roundi(9 * sx), GOLD)
	var bind_size := Vector2(88, 38) * sx
	var bind_y := rect.end.y - 50.0 * sx
	for i in 4:
		var br := Rect2(Vector2(rect.position.x + 18.0 * sx + i * (bind_size.x + 8.0 * sx), bind_y), bind_size)
		hud.draw_style_box(box_style(), br)
		hud._draw_centered("SLOT %d" % (i + 1), br.get_center() + Vector2(0, 4 * sx), roundi(9 * sx), LIGHT)
	var close := Rect2(rect.end - Vector2(48, rect.size.y - 8) * sx, Vector2(40, 40) * sx)
	hud.draw_style_box(box_style(), close)
	hud._draw_centered("×", close.get_center() + Vector2(0, 3 * sx), roundi(24 * sx), LIGHT)


static func _active_status_chips(hud: GameHud, layout: Dictionary, player: ShipMotor, health: ShipHealth, input: PlayerShipInput) -> void:
	var sx: float = float(layout.get("ui_scale", 1.0))
	var safe: Rect2 = layout.safe
	var chips: Array[String] = []
	var now := Time.get_ticks_msec() / 1000.0
	var protection_remaining := maxf(0.0, (int(player.get_meta("respawn_protection_until", 0)) - Time.get_ticks_msec()) / 1000.0)
	if protection_remaining > 0.0: chips.append("SCHUTZ %.0fs" % ceili(protection_remaining))
	if player.get_meta("veil_active", false): chips.append("VEIL %.0fs" % maxf(0.0, float(player.get_meta("veil_until", now)) - now))
	if health.barrier_remaining() > 0.0: chips.append("BARRIER %.0f" % health.barrier_remaining())
	if health.repair_blocked(): chips.append("REPAIR BLOCK")
	# M249: PvP status is presentation-only and appears only from a server-published replica.
	var pvp_runtime := player.get_node_or_null("PvpHonorRanked") as M249PvpHonorRankedRuntime
	if pvp_runtime != null:
		var pvp_hud := pvp_runtime.hud_state()
		if str(pvp_hud.get("source", "")) == "SERVER":
			var zone = pvp_hud.get("zone", {})
			if zone is Dictionary and bool((zone as Dictionary).get("pvp_enabled", false)):
				chips.append(str((zone as Dictionary).get("hud_label", (zone as Dictionary).get("label", "PVP"))).to_upper())
			var timer = pvp_hud.get("combat_timer", {})
			if timer is Dictionary and bool((timer as Dictionary).get("active", false)):
				chips.append("PVP TIMER " + str((timer as Dictionary).get("remaining_label", "AKTIV")))
	# M253: transient network continuity feedback only from a server-verified world-session snapshot.
	var world_session := hud.get_tree().get_first_node_in_group("world_session_readiness") as M253WorldSessionRuntime
	if world_session != null:
		var session_hud := world_session.hud_status()
		if str(session_hud.get("source", "")) == "SERVER" and bool(session_hud.get("visible", false)):
			chips.append(str(session_hud.get("label", "VERBINDUNG…")))
	# M171: render all active runtime status effects, not only the original four IDs.
	for id in health.ammo_effect_until.keys():
		if now < float(health.ammo_effect_until.get(id, 0.0)):
			chips.append(str(id).replace("_", " ").to_upper())
	if chips.is_empty(): return
	var chip_w := (88.0 if layout.compact else 108.0) * sx
	var chip_h := 25.0 * sx
	var total := minf(safe.size.x - 24.0 * sx, chip_w * chips.size())
	var x := safe.get_center().x - total * 0.5
	var y := safe.end.y - 26.0 * sx
	for i in mini(chips.size(), 5):
		var r := Rect2(Vector2(x + i * chip_w, y - chip_h), Vector2(chip_w - 5 * sx, chip_h))
		hud.draw_style_box(box_style(), r)
		hud._draw_centered(chips[i], r.get_center() + Vector2(0, 4 * sx), roundi(9 * sx), LIGHT)



static func _quickslot_bar(hud: GameHud, layout: Dictionary, player: ShipMotor, weapons: ShipWeapons, inventory: PlayerInventory, input: PlayerShipInput) -> void:
	var sx: float = float(layout.get("ui_scale", 1.0))
	for i in PlayerInventory.QUICK_SLOT_COUNT:
		var key := "quick_%d" % i
		if not layout.actions.has(key): continue
		var r: Rect2 = layout.actions[key]
		if not r.has_area():continue
		var binding := inventory.quickslot(i)
		var id := str(binding.get("id", ""))
		var kind := str(binding.get("kind", ""))
		hud.draw_style_box(box_style(), r)
		hud._draw_centered("%d" % (i + 1), r.position + Vector2(8, 11) * sx, roundi(8 * sx), GOLD)
		if id.is_empty(): continue
		var kind_label := M208UnifiedInterfaceCatalog.quickslot_kind_label(kind)
		if not kind_label.is_empty():
			text(hud, kind_label, Rect2(r.position + Vector2(5, r.size.y - 16) * sx, Vector2(r.size.x - 10 * sx, 11 * sx)), roundi(7 * sx), TEXT.darkened(0.18))
		var icon_id := ""
		if kind == "mode":
			icon_id = "hud_icon_harpoon"
		else:
			icon_id = CombatUiIconCatalog.slot(id)
		icon(hud, icon_id, r.grow(-5.0 * sx))
		var amount := inventory.count(id) if kind != "mode" else inventory.count("harpoon")
		if kind == "item":
			var remaining := input.item_cooldown_remaining(id)
			if remaining > 0.05:
				var progress := input.item_cooldown_progress(id)
				hud.draw_circle(r.get_center(), r.size.x * 0.38, Color(0, 0, 0, 0.48))
				hud.draw_arc(r.get_center(), r.size.x * 0.45, -PI * 0.5, -PI * 0.5 + TAU * progress, 28, LIGHT, maxf(2.0, 2.5 * sx), true)
				hud._draw_centered("%.0f" % ceil(remaining), r.get_center() + Vector2(0, 4 * sx), roundi(9 * sx), TEXT)
		if kind == "ammo" and weapons.weapon_mode == "cannon" and weapons.ammo_index == CombatCatalog.ammo_index_by_id(id):
			hud.draw_arc(r.get_center(), r.size.x * 0.47, 0, TAU, 28, GREEN, maxf(2.0, 2.5 * sx), true)
		elif kind == "mode" and weapons.weapon_mode == "harpoon":
			hud.draw_arc(r.get_center(), r.size.x * 0.47, 0, TAU, 28, GREEN, maxf(2.0, 2.5 * sx), true)
		elif kind == "supply":
			var active := inventory.powder_enabled if id == "powder" else inventory.plates_enabled
			if active: hud.draw_arc(r.get_center(), r.size.x * 0.47, 0, TAU, 28, GREEN, maxf(2.0, 2.5 * sx), true)
		hud._draw_centered(str(amount), r.end - Vector2(10, 7) * sx, roundi(8 * sx), LIGHT)



static func _first_monster_teaching(hud:GameHud,layout:Dictionary,player:ShipMotor,weapons:ShipWeapons,enemy:ShipMotor)->void:
	var safe:Rect2=layout.safe
	var sx:=float(layout.get("ui_scale",1.0))
	var compact:=bool(layout.get("compact",false))
	var hint:="MONSTER · HARPUNE EMPFOHLEN"
	var icon_slot:="m76_first_monster"
	if weapons.weapon_mode!="harpoon":
		hint="HARPUNENMODUS WÄHLEN"
		icon_slot="hud_icon_harpoon"
	else:
		var range_state:=(player.get_node("Targeting") as TargetingSystem).target_range_state(weapons.effective_range())
		hint="REICHWEITE: %s"%range_state
		icon_slot="hud_icon_target"
	var width:=minf((286.0 if compact else 360.0)*sx,safe.size.x-24.0*sx)
	var height:=(48.0 if compact else 56.0)*sx
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.position.y+safe.size.y*0.72-height*0.5),Vector2(width,height))
	# Never cover critical combat input.
	for id in ["fire","ammo_menu","items_menu"]:
		var control:Rect2=layout.actions.get(id,Rect2())
		if control.has_area() and rect.grow(6.0).intersects(control):
			rect.position.y=maxf(safe.position.y+8.0*sx,control.position.y-height-12.0*sx)
	hud.draw_style_box(box_style(),rect)
	var tex:=VisualAssetCatalog.texture(icon_slot)
	if tex!=null:hud.draw_texture_rect(tex,Rect2(rect.position+Vector2(8,8)*sx,Vector2.ONE*32.0*sx),false)
	text(hud,hint,Rect2(rect.position+Vector2(48,12)*sx,Vector2(rect.size.x-56*sx,22*sx)),roundi((11 if compact else 13)*sx),GOLD)
	if not compact:
		text(hud,"PL3 · erstes Seeungeheuer · keine automatische Ziel-/Waffenwahl",Rect2(rect.position+Vector2(48,33)*sx,Vector2(rect.size.x-56*sx,16*sx)),roundi(9*sx),TEXT.darkened(0.12))

static func _input_affordances(hud:GameHud,layout:Dictionary)->void:
	if bool(layout.get("touch_density",false)):return
	var mode:=str(layout.get("input_mode","mouse_keyboard"))
	var rows:=[
		["fire","m84_gamepad_fire" if mode=="gamepad" else "m84_key_fire"],
		["target","m86_gamepad_target" if mode=="gamepad" else "m84_key_target"],
		["recenter","m86_gamepad_sail" if mode=="gamepad" else "m86_key_sail"]
	]
	for row in rows:
		var id:=str(row[0])
		var r:Rect2=layout.actions.get(id,Rect2())
		if not r.has_area():continue
		var tex:=VisualAssetCatalog.texture(str(row[1]))
		if tex==null:continue
		var size:=20.0*float(layout.get("ui_scale",1.0))
		var icon_rect:=Rect2(r.position+Vector2(r.size.x-size*0.75,-size*0.25),Vector2.ONE*size)
		hud.draw_texture_rect(tex,icon_rect,false)

static func _event_chip(hud: GameHud, layout: Dictionary, runtime: EventRuntime) -> void:
	var safe: Rect2 = layout.safe
	var sx: float = float(layout.get("ui_scale", 1.0))
	var compact: bool = bool(layout.compact)
	var width := minf((214.0 if compact else 286.0) * sx, safe.size.x * 0.34)
	var height := (42.0 if compact else 54.0) * sx
	var top_rect: Rect2 = layout.top
	var rect := Rect2(Vector2(safe.end.x - width - 12.0 * sx, top_rect.end.y + 8.0 * sx), Vector2(width, height))
	if rect.intersects(layout.actions.minimap):
		rect.position.x = maxf(safe.position.x + 10.0 * sx, (layout.actions.minimap as Rect2).position.x - width - 10.0 * sx)
	if not graphic_frame(hud, "hud_quickslot_frame", rect): hud.draw_style_box(box_style(), rect)
	var event_icon:=VisualAssetCatalog.texture("m94_halloween_event")
	if event_icon!=null:hud.draw_texture_rect(event_icon,Rect2(rect.position+Vector2(7,6)*sx,Vector2.ONE*26*sx),false)
	var tx:=38.0 if event_icon!=null else 9.0
	text(hud, runtime.title().to_upper(), Rect2(rect.position + Vector2(tx, 5) * sx, Vector2(rect.size.x - (tx+8) * sx, 18 * sx)), roundi((9 if compact else 11) * sx), LIGHT)
	bar(hud, Rect2(rect.position + Vector2(9, 24) * sx, Vector2(rect.size.x - 70 * sx, 7 * sx)), runtime.meter_ratio(), Color("7850b8"))
	text(hud, "%d" % runtime.currency, Rect2(Vector2(rect.end.x - 54 * sx, rect.position.y + 20 * sx), Vector2(46, 18) * sx), roundi(10 * sx), TEXT)
	if not compact:
		text(hud, "%s · P%d · %s"%[runtime.currency_label(),runtime.phase,runtime.phase_label()], Rect2(rect.position + Vector2(9, 37) * sx, Vector2(rect.size.x - 18 * sx, 16 * sx)), roundi(9 * sx), TEXT.darkened(0.12))


static func _havens_reach_first_dock(hud:GameHud,layout:Dictionary,player:ShipMotor)->void:
	var until:=float(player.get_meta("havens_reach_first_dock_until",0.0))
	if until<=Time.get_ticks_msec()/1000.0:return
	var safe:Rect2=layout.safe
	var sx:float=float(layout.get("ui_scale",1.0))
	var compact:bool=bool(layout.compact)
	var width:=minf((390.0 if compact else 520.0)*sx,safe.size.x-24.0*sx)
	var height:=(82.0 if compact else 104.0)*sx
	var rect:=Rect2(Vector2(safe.get_center().x-width*0.5,safe.end.y-height-16.0*sx),Vector2(width,height))
	hud.draw_style_box(box_style(),rect)
	text(hud,"HAVEN'S REACH · HAFENSERVICES",Rect2(rect.position+Vector2(12,8)*sx,Vector2(rect.size.x-24*sx,20*sx)),roundi((11 if compact else 13)*sx),GOLD)
	var ids:=["shipyard","repair","market","arsenal","quests"]
	var icon_size:=(34.0 if compact else 42.0)*sx
	var gap:=8.0*sx
	var total:=icon_size*ids.size()+gap*(ids.size()-1)
	var x:=rect.get_center().x-total*0.5
	for i in ids.size():
		var tex:=VisualAssetCatalog.texture(WorldMarkerVisualCatalog.service_slot(ids[i]))
		var r:=Rect2(Vector2(x+i*(icon_size+gap),rect.position.y+34.0*sx),Vector2.ONE*icon_size)
		if tex!=null:hud.draw_texture_rect(tex,r,false)
	if not compact:
		text(hud,"Werft · Reparatur · Markt · Arsenal · Aufträge",Rect2(rect.position+Vector2(12,82)*sx,Vector2(rect.size.x-24*sx,18*sx)),roundi(10*sx),TEXT)


static func _trial_completion_chip(hud:GameHud,layout:Dictionary,player:ShipMotor)->void:
	var until:=float(player.get_meta("trial_completion_feedback_until",0.0))
	if until<=Time.get_ticks_msec()/1000.0:return
	var safe:Rect2=layout.safe
	var sx:float=float(layout.get("ui_scale",1.0))
	var rect:=Rect2(Vector2(safe.get_center().x-120.0*sx,(layout.top as Rect2).end.y+8.0*sx),Vector2(240.0,42.0)*sx)
	hud.draw_style_box(box_style(),rect)
	var tex:=VisualAssetCatalog.texture("m74_trial_complete")
	if tex!=null:hud.draw_texture_rect(tex,Rect2(rect.position+Vector2(6,5)*sx,Vector2.ONE*32.0*sx),false)
	text(hud,"ANFÄNGERAUFTRAG ABGESCHLOSSEN",Rect2(rect.position+Vector2(44,9)*sx,Vector2(rect.size.x-50*sx,22*sx)),roundi(10*sx),GOLD)


static func _beginner_objective_strip(hud: GameHud, layout: Dictionary, player: ShipMotor) -> void:
	if not (layout.objective_strip as Rect2).has_area():return
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	if voyage==null or voyage.beginner_complete() or not voyage.trial_active:return
	var sx:float=float(layout.get("ui_scale",1.0))
	var compact:bool=bool(layout.compact)
	var rect:Rect2=layout.objective_strip
	hud.draw_style_box(box_style(),rect)
	var card:=voyage.presentation_card()
	var primary:=voyage.presentation_primary()
	var icon_texture:=VisualAssetCatalog.texture(str(primary.get("icon","m72_poi_objective_frame")))
	var icon_size:=34.0*sx
	if icon_texture!=null:
		hud.draw_texture_rect(icon_texture,Rect2(rect.position+Vector2(8,7)*sx,Vector2.ONE*icon_size),false)
	var tx:=48.0 if icon_texture!=null else 10.0
	text(hud,"KARTENLEVEL %d · %s"%[int(card.get("level",1)),str(card.get("title","ANFÄNGERAUFTRAG")).to_upper()],
		Rect2(rect.position+Vector2(tx,6)*sx,Vector2(rect.size.x-(tx+8)*sx,18*sx)),roundi(10*sx),LIGHT)
	text(hud,"%s · %d/%d"%[str(primary.get("title","ZIEL")),int(primary.get("current",0)),int(primary.get("target",1))],
		Rect2(rect.position+Vector2(tx,25)*sx,Vector2(rect.size.x-(tx+8)*sx,18*sx)),roundi((10 if compact else 12)*sx),GOLD)
	if not compact:
		text(hud,str(primary.get("hint","")),Rect2(rect.position+Vector2(tx,43)*sx,Vector2(rect.size.x-(tx+8)*sx,15*sx)),roundi(9*sx),TEXT.darkened(0.12))



static func _post_beginner_progress_strip(hud:GameHud,layout:Dictionary,player:ShipMotor)->void:
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	var post:=player.get_node_or_null("PostBeginnerProgress") as PostBeginnerProgress
	if voyage==null or post==null:return
	var level:=voyage.map_level()
	if level<6 or level>60:return
	var rect:Rect2=layout.objective_strip
	if not rect.has_area():return
	var world:=hud.get_tree().get_first_node_in_group("world_map") as WorldMapSystem
	var row:Dictionary=world.current_progression_contract() if world!=null and world.current_map_level()==level else {}
	if row.is_empty():
		if level<=10:row=Pl6To10ProgressionCatalog.level(level)
		elif level<=15:row=Pl11To15ProgressionCatalog.level(level)
		elif level<=20:row=Pl16To20ProgressionCatalog.level(level)
		elif level<=25:row=Pl21To25ProgressionCatalog.level(level)
		elif level<=30:row=Pl26To30ProgressionCatalog.level(level)
		elif level<=35:row=Pl31To35ProgressionCatalog.level(level)
		elif level<=40:row=Pl36To40ProgressionCatalog.level(level)
		elif level<=45:row=Pl41To45ProgressionCatalog.level(level)
		elif level<=50:row=Pl46To50ProgressionCatalog.level(level)
		else:row=Pl51To60ProgressionCatalog.level(level)
	var goal:=int(row.get("map_xp",0));var current:=int(post.map_xp.get(level,0));var boss:=bool(post.boss_clears.get(level,false))
	var sx:=float(layout.get("ui_scale",1.0));hud.draw_style_box(box_style(),rect)
	var region:=WorldRegionRegistry.for_level(level)
	text(hud,"KARTENLEVEL %d · %s"%[level,str(region.get("display_name",row.get("title","HAUPTPROGRESSION"))).to_upper()],Rect2(rect.position+Vector2(10,6)*sx,Vector2(rect.size.x-20*sx,18*sx)),roundi(10*sx),LIGHT)
	var status:="%d/%d XP · ADMIRAL %s"%[current,goal,"✓" if boss else "OFFEN"]
	if level>=11:
		status+=" · H %d/%d · R %d/%d"%[int(post.hunter_clears.get(level,0)),int(row.get("hunter",0)),int(post.region_objectives.get(level,0)),int(row.get("region_objectives",0))]
	if level>=21 and level<=25:status+=" · STATUS %d/%d · BUILD %d/%d"%[int(post.status_objectives.get(level,0)),int(row.get("status_objectives",0)),int(post.build_objectives.get(level,0)),int(row.get("build_objectives",0))]
	elif level>=26 and level<=30:status+=" · CORRUPTION %d/%d"%[int(post.corruption_objectives.get(level,0)),int(row.get("corruption",0))]
	elif level>=31 and level<=35:status+=" · GUARDIAN %d/%d"%[int(post.guardian_fragments.get(level,0)),int(row.get("guardian_fragments",0))]
	elif level>=36 and level<=40:status+=" · VOID ELITE %d/2"%int(post.void_elite_chains.get(level,0))
	elif level>=41 and level<=45:status+=" · PRESTIGE %d/%d"%[int(post.sovereign_prestige.get(level,0)),int(row.get("prestige",0))]
	elif level>=46 and level<=50:status+=" · LEG %d/%d · MAT %d/%d"%[int(post.legendary_chains.get(level,0)),int(row.get("legendary_chain",0)),int(post.top_material_objectives.get(level,0)),int(row.get("top_materials",0))]
	elif level>=51:status+=" · W5 %d/%d · SHARD %d/%d"%[int(post.w5_elite_chains.get(level,0)),int(row.get("w5_elite_chain",0)),int(post.dominion_shard_objectives.get(level,0)),int(row.get("dominion_shards",0))]
	if bool(row.get("trial",false)):status+=" · PRÜFUNG "+("BEREIT" if post.trial_ready(level) else "GESPERRT")
	text(hud,status,Rect2(rect.position+Vector2(10,27)*sx,Vector2(rect.size.x-20*sx,20*sx)),roundi(10*sx),GOLD)

static func _minimap(hud: GameHud, rect: Rect2, world: WorldMapSystem, player: ShipMotor) -> void:
	# M221: circular north-up sea-chart read, aligned to the gameplay master references.
	ring(hud, rect)
	if world == null:
		return
	var c := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.5 - 10.0
	# Restrained nautical range rings keep orientation readable without turning the map into a grid panel.
	for fraction in [0.35, 0.68]:
		hud.draw_arc(c, radius * fraction, 0, TAU, 40, Color(1,1,1,0.10), 1.0, true)
	for cardinal in 4:
		var d := Vector2.from_angle(-PI * 0.5 + cardinal * PI * 0.5)
		hud.draw_line(c + d * radius * 0.78, c + d * radius * 0.94, Color(1,1,1,0.16), 1.0, true)

	var targeting := player.get_node("Targeting") as TargetingSystem
	var tracking := player.get_node_or_null("TrackedQuestRuntime") as TrackedQuestRuntime
	var tracked_target: Node3D = tracking.resolve_target() if tracking != null else null
	for group in ["islands", "ports", "loot", "enemies"]:
		for object: Node3D in hud.get_tree().get_nodes_in_group(group):
			if group == "enemies":
				var enemy_health := object.get_node_or_null("Health") as ShipHealth
				if enemy_health != null and enemy_health.is_sunk:
					continue
			var point := Vector2(object.position.x, object.position.z) / world.sector_half_size()
			point = point.limit_length(1.0) * radius
			var selected := object == targeting.target
			var tracked := object == tracked_target
			var admiral := bool(object.get_meta("is_admiral", false))
			var color := {"islands": GREEN, "ports": LIGHT, "loot": GOLD, "enemies": RED}[group] as Color
			var kind := "port" if group == "ports" else ("loot" if group == "loot" else "enemy")
			var marker_r := M221MinimapNavigationCatalog.marker_radius(kind, selected, tracked, admiral)
			# M230: restrained encounter-zone rings expose M229 elite/monster/admiral identity.
			# They are presentation-only and never represent collision, aggro or weapon range.
			if group == "enemies" and M230EncounterWorldReadCatalog.world_zone_visible(object, selected):
				var zone_r := M230EncounterWorldReadCatalog.danger_radius(object)
				if zone_r > 0.0:
					hud.draw_arc(c + point, zone_r, 0, TAU, 24, Color(1.0,0.42,0.30,M230EncounterWorldReadCatalog.danger_alpha(object)), 1.2, true)
			hud.draw_circle(c + point, marker_r, GOLD if admiral else color)
			if selected:
				# M219 selected target must remain the strongest combat cue at zoomed-out scale.
				hud.draw_arc(c + point, 8.0, 0, TAU, 20, GOLD, 2.0, true)
				hud.draw_arc(c + point, 11.0, 0, TAU, 24, LIGHT, 1.0, true)
			elif tracked:
				hud.draw_arc(c + point, 8.0, 0, TAU, 20, LIGHT, 1.5, true)
			elif admiral:
				hud.draw_arc(c + point, 7.5, 0, TAU, 20, GOLD, 1.2, true)

	var poi_rows:Array=[]
	for node in hud.get_tree().get_nodes_in_group("world_poi_markers"):
		var poi:=node as Node3D
		if poi==null:continue
		poi_rows.append({"node":poi,"distance":player.global_position.distance_to(poi.global_position),
			"priority":WorldMarkerPriorityCatalog.priority_for(poi,str(poi.get_meta("poi_kind","")))})
	WorldMarkerPriorityCatalog.sort_rows(poi_rows)
	var minimap_poi_limit:=MobilePresentationBudget.int_value(hud.get_viewport_rect().size,float(DisplayServer.screen_get_dpi()),"minimap_poi",5)
	for i in mini(poi_rows.size(),minimap_poi_limit):
		var poi:Node3D=poi_rows[i].node
		var point:=Vector2(poi.position.x,poi.position.z)/world.sector_half_size()
		point=point.limit_length(1.0)*radius
		var kind:=str(poi.get_meta("poi_kind",""))
		var hint:=WorldMarkerPriorityCatalog.color_hint(kind)
		var marker_color:=RED if hint=="danger" else (GOLD if hint=="reward" else LIGHT)
		hud.draw_circle(c+point,2.4 if hint!="danger" else 3.0,marker_color)

	# Active Tap-to-Sail course uses the existing M220 read-only navigation state.
	var input := player.get_node_or_null("PlayerInput") as PlayerShipInput
	if input != null:
		var course := input.navigation_presentation()
		if bool(course.get("active", false)):
			var final_world:Vector3 = course.get("final_target", player.global_position)
			var steering_world:Vector3 = course.get("steering_target", final_world)
			var final_point := Vector2(final_world.x, final_world.z) / world.sector_half_size()
			var steering_point := Vector2(steering_world.x, steering_world.z) / world.sector_half_size()
			final_point = c + final_point.limit_length(1.0) * radius
			steering_point = c + steering_point.limit_length(1.0) * radius
			var player_point := Vector2(player.position.x, player.position.z) / world.sector_half_size()
			player_point = c + player_point.limit_length(1.0) * radius
			hud.draw_dashed_line(player_point, steering_point, BLUE, 1.4, 5.0, true)
			if steering_point.distance_to(final_point) > 3.0:
				hud.draw_dashed_line(steering_point, final_point, LIGHT, 1.2, 5.0, true)
			hud.draw_arc(final_point, 5.5, 0, TAU, 18, LIGHT, 1.5, true)

	for node in hud.get_tree().get_nodes_in_group("guild_islands"):
		var island:=node as Node3D
		if island==null:continue
		var point:=Vector2(island.position.x,island.position.z)/world.sector_half_size()
		point=point.limit_length(1)*radius
		var color:=GuildIslandVisualState.relation_color(island)
		hud.draw_circle(c+point,4.2,color)
		hud.draw_arc(c+point,6.2,0,TAU,16,LIGHT,1,true)

	# Player heading is explicit because the minimap remains north-up on every platform.
	var player_point := Vector2(player.position.x, player.position.z) / world.sector_half_size()
	player_point = c + player_point.limit_length(1.0) * radius
	var heading := M221MinimapNavigationCatalog.ship_heading_2d(player)
	hud.draw_circle(player_point, M221MinimapNavigationCatalog.PLAYER_RADIUS, BLUE)
	hud.draw_line(player_point, player_point + heading * 12.0, LIGHT, 2.0, true)
	hud._draw_centered("N", c - Vector2(0, radius + 1), 13, LIGHT)
	hud._draw_centered(world.current_map_name().split(" ")[0], c + Vector2(0, radius + 8), 11, TEXT)


static func _wheel(hud: GameHud, rect: Rect2, input: PlayerShipInput) -> void:
	ring(hud, rect)
	var center := rect.get_center()
	var radius := rect.size.x * 0.34
	hud.draw_arc(center, radius, 0, TAU, 48, GOLD, 2, true)
	for index in 8:
		var direction := Vector2.from_angle(index * TAU / 8)
		hud.draw_line(center + direction * 7, center + direction * (radius + 6), GOLD, 2, true)
	hud.draw_circle(center, 7, LIGHT)
	if input.joystick_visible:
		var offset := (input.steering_current - input.steering_start).limit_length(radius)
		hud.draw_circle(center + offset, 13, Color(1, 0.86, 0.6, 0.55))


static func _draw_m284_naval_combat_identity(hud:GameHud, layout:Dictionary, ui_scale:float) -> void:
	var view:Dictionary=hud.m284_naval_combat_identity_state
	if view.is_empty() or str(view.get("source",""))!="SERVER": return
	var profile:Dictionary=view.get("active_profile",{}) as Dictionary
	if profile.is_empty(): return
	var target_info:Rect2=layout.target_info
	if not target_info.has_area(): return
	var family:=str(profile.get("family_label",profile.get("profile_id","NAVAL"))).to_upper()
	var material:=str(profile.get("impact_material_label","")).to_upper()
	var label:=family + ((" · "+material) if not material.is_empty() else "")
	var rect:=Rect2(Vector2(target_info.position.x,target_info.end.y+54.0*ui_scale),Vector2(target_info.size.x,16.0*ui_scale))
	hud.draw_style_box(panel(Color(0.008,0.022,0.032,0.72),Color("506975"),5.0),rect)
	hud._draw_centered(label.left(34),rect.get_center()+Vector2(0,3.0*ui_scale),roundi(7.5*ui_scale),LIGHT)
	# Family/material/audio/rhythm are presentation identity only; combat values remain authoritative elsewhere.


static func _draw_m285_ship_damage_defeat_presentation(hud: GameHud, layout: Dictionary, ui_scale: float) -> void:
	var view: Dictionary = hud.m285_ship_damage_defeat_state
	if view.is_empty() or str(view.get("source", "")) != "SERVER": return
	var states: Array = view.get("ship_states", []) as Array
	if states.is_empty(): return
	var focus: Dictionary = states[0] as Dictionary
	var damage_state := str(focus.get("damage_state", "INTACT")).to_upper()
	if damage_state in ["INTACT", "LIGHT"] and str(focus.get("shield_state", "NONE")) not in ["LOW", "BROKEN"]: return
	var target_info: Rect2 = layout.target_info
	if not target_info.has_area(): return
	var label := "RUMPF " + damage_state
	var shield_state := str(focus.get("shield_state", "NONE")).to_upper()
	if shield_state in ["LOW", "BROKEN"]: label += " · SCHILD " + shield_state
	var rect := Rect2(Vector2(target_info.position.x, target_info.end.y + 72.0 * ui_scale), Vector2(target_info.size.x, 18.0 * ui_scale))
	var critical := damage_state in ["CRITICAL", "DEFEATED"]
	var border := Color("c65b3f") if critical else Color("8f7040")
	hud.draw_style_box(panel(Color(0.045, 0.025, 0.022, 0.82), border, 5.0), rect)
	hud._draw_centered(label.left(38), rect.get_center() + Vector2(0, 3.0 * ui_scale), roundi(8.0 * ui_scale), Color("f0c37a") if critical else LIGHT)
	# Read-only replicated presentation: this strip cannot infer damage, defeat or cleanup.


static func _draw_m286_ship_damage_escalation(hud: GameHud, layout: Dictionary, ui_scale: float) -> void:
	var view: Dictionary = hud.m286_ship_damage_escalation_state
	if view.is_empty() or str(view.get("source", "")) != "SERVER": return
	var states: Array = view.get("entity_states", []) as Array
	if states.is_empty(): return
	var focus := states[0] as Dictionary
	var segments := focus.get("segment_states", {}) as Dictionary
	var visible_segments: Array[String] = []
	for segment in ["DECK", "MAST", "SAILS", "BOW", "STERN", "PORT_HULL", "STARBOARD_HULL"]:
		var state := str(segments.get(segment, "INTACT")).to_upper()
		if state in ["BREACHED", "DESTROYED"]: visible_segments.append(segment.replace("_HULL", ""))
	var phase := str(focus.get("defeat_phase", "NONE")).to_upper()
	if visible_segments.is_empty() and phase == "NONE": return
	var target_info: Rect2 = layout.target_info
	if not target_info.has_area(): return
	var label := "SEGMENT " + (" / ".join(visible_segments.slice(0, 3)) if not visible_segments.is_empty() else "STABIL")
	if phase != "NONE": label += " · " + phase
	var rect := Rect2(Vector2(target_info.position.x, target_info.end.y + 92.0 * ui_scale), Vector2(target_info.size.x, 17.0 * ui_scale))
	var danger := phase in ["FLOODING", "BREAKUP", "SUBMERGED", "CLEANUP_PENDING"]
	hud.draw_style_box(panel(Color(0.035, 0.025, 0.02, 0.8), Color("b9533c") if danger else Color("725c45"), 5.0), rect)
	hud._draw_centered(label.left(42), rect.get_center() + Vector2(0, 3.0 * ui_scale), roundi(7.5 * ui_scale), Color("efb37b") if danger else LIGHT)
	# Presentation only: segment decals and defeat phase cannot drive combat, transform or cleanup.


static func _draw_m287_ship_motion_identity(hud: GameHud, layout: Dictionary, ui_scale: float) -> void:
	var view: Dictionary = hud.m287_ship_motion_identity_state
	if view.is_empty() or str(view.get("source", "")) != "SERVER": return
	var states: Array = view.get("entity_states", []) as Array
	if states.is_empty(): return
	var focus := states[0] as Dictionary
	var motion_state := str(focus.get("motion_state", "IDLE")).to_upper()
	if motion_state in ["IDLE", "CRUISE"]: return
	var profile := str(focus.get("motion_profile_id", "BALANCED")).to_upper()
	var target_info: Rect2 = layout.target_info
	if not target_info.has_area(): return
	var label := "FAHRT " + motion_state + " · " + profile
	var rect := Rect2(Vector2(target_info.position.x, target_info.end.y + 111.0 * ui_scale), Vector2(target_info.size.x, 16.0 * ui_scale))
	var correction := motion_state == "CORRECTING"
	hud.draw_style_box(panel(Color(0.012, 0.035, 0.045, 0.76), Color("c77a45") if correction else Color("4a8190"), 5.0), rect)
	hud._draw_centered(label.left(38), rect.get_center() + Vector2(0, 3.0 * ui_scale), roundi(7.5 * ui_scale), Color("f1bf86") if correction else LIGHT)
	# Read-only movement presentation: wake length never becomes speed, heading or route truth.


static func _draw_m288_naval_contact_readability(hud: GameHud, layout: Dictionary, ui_scale: float) -> void:
	var view: Dictionary = hud.m288_naval_contact_readability_state
	if view.is_empty() or str(view.get("source", "")) != "SERVER": return
	var contacts: Array = view.get("contacts", []) as Array
	if contacts.is_empty(): return
	var safe := hud._safe_rect().grow(-48.0 * ui_scale)
	var edge_budget := 2 if bool(view.get("compact", false)) else 3
	var edge_count := 0
	for raw in contacts:
		var contact := raw as Dictionary
		if not bool(contact.get("offscreen", false)): continue
		if not bool(contact.get("selected", false)) and str(contact.get("engagement_state", "PASSIVE")) not in ["AGGRO", "TARGETED", "IN_RANGE"] and str(contact.get("contact_class", "NEUTRAL")) not in ["ADMIRAL", "MONSTER", "BOSS"]: continue
		var direction := Vector2(float(contact.get("edge_x", 0.0)), float(contact.get("edge_y", -1.0)))
		if direction.length_squared() < 0.01: direction = Vector2.UP
		direction = direction.normalized()
		var half := safe.size * 0.5
		var tx := half.x / maxf(absf(direction.x), 0.001)
		var ty := half.y / maxf(absf(direction.y), 0.001)
		var marker_position := safe.get_center() + direction * minf(tx, ty)
		if marker_position.y > safe.get_center().y + half.y * 0.55:
			marker_position.y = safe.get_center().y + half.y * 0.55
			marker_position.x = clampf(marker_position.x, safe.position.x + half.x * 0.38, safe.end.x - half.x * 0.38)
		var marker_color := Color("d46655") if str(contact.get("contact_class", "")) in ["HOSTILE", "ELITE", "ADMIRAL", "BOSS"] else Color("a77bca") if str(contact.get("contact_class", "")) == "MONSTER" else Color("6fa993")
		hud.draw_circle(marker_position, 13.0 * ui_scale, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
		hud.draw_arc(marker_position, 13.0 * ui_scale, -2.5, 0.65, 18, marker_color, 2.0 * ui_scale, true)
		var short_label := str(contact.get("contact_class", "CONTACT")).left(3)
		text(hud, short_label, Rect2(marker_position - Vector2(18, 7) * ui_scale, Vector2(36, 14) * ui_scale), roundi(8.0 * ui_scale), marker_color)
		edge_count += 1
		if edge_count >= edge_budget: break
	var focus := contacts[0] as Dictionary
	var selected := bool(focus.get("selected", false))
	var engagement := str(focus.get("engagement_state", "PASSIVE")).to_upper()
	var contact_class := str(focus.get("contact_class", "NEUTRAL")).to_upper()
	if not selected and engagement not in ["AGGRO", "TARGETED", "IN_RANGE", "PROTECTED"]: return
	var target_info: Rect2 = layout.target_info
	if not target_info.has_area(): return
	var state_label := "GESCHÜTZT" if bool(focus.get("protected", false)) else ("IN RANGE" if bool(focus.get("in_range", false)) else "OUT OF RANGE")
	var label := contact_class + " · " + engagement + " · " + state_label
	var rect := Rect2(Vector2(target_info.position.x, target_info.end.y + 129.0 * ui_scale), Vector2(target_info.size.x, 16.0 * ui_scale))
	var danger := contact_class in ["HOSTILE", "ELITE", "ADMIRAL", "MONSTER", "BOSS"] and not bool(focus.get("protected", false))
	hud.draw_style_box(panel(Color(0.028, 0.025, 0.035, 0.78), Color("bc6554") if danger else Color("597f88"), 5.0), rect)
	hud._draw_centered(label.left(42), rect.get_center() + Vector2(0, 3.0 * ui_scale), roundi(7.5 * ui_scale), Color("f0bb82") if danger else LIGHT)
	# Presentation only: this strip cannot select a target or decide range, aggro, protection or attack legality.
