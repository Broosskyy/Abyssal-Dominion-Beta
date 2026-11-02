extends "res://scripts/classic/m3039_world_ship_pass.gd"
## M304: A genuinely functional LOCAL shipyard, combat equipment choice and
## introductory quest. Uses existing audited SeaBattles/SeaOfBones ship sprites.
## Player state is local; this does not modify M302's server-authoritative game.

const SHIP_CLASSES: Array[Dictionary] = [
	{"name": "Kapitänssegler", "cost": 0, "description": "Ausgewogen · Startschiff",
		"cannon_bonus": 0, "harpoon_bonus": 0, "armor": 0},
	{"name": "Eisenfregatte", "cost": 45, "description": "Panzerung +2 · Kanonenschaden +3",
		"cannon_bonus": 3, "harpoon_bonus": 0, "armor": 2},
	{"name": "Geistersegler", "cost": 90, "description": "Kanonenschaden +5 · Harpunenschaden +6",
		"cannon_bonus": 5, "harpoon_bonus": 6, "armor": 0}
]
var _ship_class_index: int = 0
var _unlocked_hulls: Array[bool] = [true, false, false]
var _yard_panel: Panel
var _yard_heading: Label
var _yard_description: Label
var _yard_buttons: Array[Button] = []
var _yard_close: Button
var _quest_frame: Panel
var _quest_title: Label
var _quest_progress: Label
var _quest_claim: Button
var _quest_claimed: bool = false

func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M304 · NORDMEER 10/2"
	_coating_button.text = "WERFT · SCHIFFE"
	_refresh()


func _make_hud() -> void:
	super._make_hud()
	# M303.9 coating selector becomes a shipyard entry point. The existing
	# _cycle_player_coating() remains available to legacy regression tests.
	var old_action := Callable(self, "_cycle_player_coating")
	if _coating_button.pressed.is_connected(old_action):
		_coating_button.pressed.disconnect(old_action)
	_coating_button.pressed.connect(Callable(self, "_toggle_shipyard"))
	_coating_button.text = "WERFT · SCHIFFE"
	_coating_button.tooltip_text = "Schiff erwerben oder auf ein freigeschaltetes Schiff wechseln"
	
	_yard_panel = _panel(_ui_root)
	_yard_panel.name = "M304Shipyard"
	_yard_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_yard_panel.visible = false
	var yard_style := _style()
	yard_style.bg_color = Color("081925")
	yard_style.border_color = Color("b99b62")
	yard_style.set_border_width_all(2)
	_yard_panel.add_theme_stylebox_override("panel", yard_style)
	_yard_heading = _label(_yard_panel, "WERFT · SCHIFFSKLASSEN", 20)
	_yard_description = _label(_yard_panel, "Lokale Testwerft: Gold aus Seekämpfen und Beute einsetzen.", 13)
	_yard_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in SHIP_CLASSES.size():
		var action := Callable(self, "_purchase_or_equip").bind(i)
		var button := _control("", action)
		_ui_root.remove_child(button)
		_yard_panel.add_child(button)
		button.name = "HullClass_%d" % i
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 14)
		_yard_buttons.append(button)
	_yard_close = _control("SCHLIESSEN", Callable(self, "_toggle_shipyard"))
	_ui_root.remove_child(_yard_close)
	_yard_panel.add_child(_yard_close)
	_quest_frame = _panel(_ui_root)
	_quest_frame.name = "M304QuestCard"
	_quest_title = _label(_ui_root, "AUFTRAG · NORDMEER", 14)
	_quest_progress = _label(_ui_root, "", 13)
	_quest_claim = _control("BELOHNUNG", Callable(self, "_claim_quest"))
	_quest_claim.name = "ClaimQuestReward"


func _layout_hud() -> void:
	super._layout_hud()
	if _yard_panel == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var compact := viewport.x < 1024.0 or viewport.y < 540.0
	var margin := 10.0 if compact else 16.0
	var card_top := (36.0 if compact else 42.0) + margin + 107.0
	var card_width := 242.0 if compact else 268.0
	_place(_quest_frame, margin, card_top, card_width, 113.0)
	_place(_quest_title, margin + 10.0, card_top + 7.0, card_width - 20.0, 21.0)
	_place(_quest_progress, margin + 10.0, card_top + 35.0, card_width - 20.0, 20.0)
	_place(_quest_claim, margin + 10.0, card_top + 66.0, card_width - 20.0, 39.0)
	var width := minf(560.0, viewport.x - margin * 2.0)
	var height := minf(390.0, viewport.y - 2.0 * margin)
	var left := (viewport.x - width) * 0.5
	var top := (viewport.y - height) * 0.5
	_place(_yard_panel, left, top, width, height)
	_place(_yard_heading, 16.0, 13.0, width - 32.0, 33.0)
	_place(_yard_description, 16.0, 49.0, width - 32.0, 39.0)
	var row_height := clampf((height - 144.0) / 3.0, 55.0, 70.0)
	for i in _yard_buttons.size():
		_place(_yard_buttons[i], 16.0, 90.0 + i * (row_height + 4.0), width - 32.0, row_height)
	_place(_yard_close, 16.0, height - 50.0, width - 32.0, 38.0)


func _toggle_shipyard() -> void:
	if _yard_panel == null:
		return
	var opening := not _yard_panel.visible
	_yard_panel.visible = opening
	if opening and _options != null:
		_options.visible = false
	_refresh()


func _purchase_or_equip(index: int) -> void:
	if index < 0 or index >= SHIP_CLASSES.size():
		return
	var blueprint: Dictionary = SHIP_CLASSES[index]
	var price: int = int(blueprint["cost"])
	if not _unlocked_hulls[index]:
		if gold < price:
			hint = "%s benötigt %d Gold · aktuell %d" % [str(blueprint["name"]), price, gold]
			_refresh()
			return
		gold -= price
		_unlocked_hulls[index] = true
	_ship_class_index = index
	_coating_index = index
	# Replace only the visual and preserve Node3D ship identity, location, HP,
	# cooldowns, active target, inventory and waypoints.
	if ship != null:
		_replace_visual(ship, SHIP, 0.9, "PlayerShip", CAPTAIN_ATLAS)
		_apply_player_coating()
		_coating_button.text = "WERFT · SCHIFFE"
		_portrait_pack = ""
	hint = "%s ausgerüstet" % str(blueprint["name"])
	_refresh()


func _claim_quest() -> void:
	if _quest_claimed:
		hint = "Auftragsbelohnung bereits abgeholt"
	elif kills < 3:
		hint = "Noch %d Schiffe für den Auftrag versenken" % (3 - kills)
	else:
		_quest_claimed = true
		gold += 90
		hint = "Nordmeer-Auftrag abgeschlossen · +90 Gold"
	_refresh()


func _refresh() -> void:
	super._refresh()
	if _quest_claim == null or _yard_panel == null:
		return
	var stage := mini(kills, 3)
	_quest_progress.text = "Schiffe versenken: %d / 3" % stage
	_quest_claim.text = "BELOHNUNG ABGEHOLT" if _quest_claimed else "90 GOLD EINLÖSEN"
	_quest_claim.disabled = _quest_claimed or kills < 3
	var selected: Dictionary = SHIP_CLASSES[_ship_class_index]
	_captain_title.text = str(selected["name"]).to_upper()
	for i in _yard_buttons.size():
		var definition: Dictionary = SHIP_CLASSES[i]
		var title := str(definition["name"])
		var suffix := "AUSGERÜSTET" if i == _ship_class_index else (
			"AUSRÜSTEN" if _unlocked_hulls[i] else "%d GOLD" % int(definition["cost"]))
		_yard_buttons[i].text = "%s  ·  %s\n%s" % [
			title, suffix, str(definition["description"])]


func _player_impact(index: int, actor: Node3D, damage: int) -> void:
	# Class upgrades materially change local-game damage, not just appearance.
	var upgrade: Dictionary = SHIP_CLASSES[_ship_class_index]
	var bonus: int = int(upgrade["harpoon_bonus"]) if (
		index >= 0 and index < enemies.size() and
		str(enemies[index].get("kind", "ship")) == "monster"
	) else int(upgrade["cannon_bonus"])
	super._player_impact(index, actor, damage + bonus)


func _enemy_impact(damage: int) -> void:
	var upgrade: Dictionary = SHIP_CLASSES[_ship_class_index]
	var protected_damage := maxi(1, damage - int(upgrade["armor"]))
	super._enemy_impact(protected_damage)


func _switch_graphics() -> void:
	super._switch_graphics()
	if _coating_button != null:
		_coating_button.text = "WERFT · SCHIFFE"
