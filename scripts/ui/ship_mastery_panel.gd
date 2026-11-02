class_name ShipMasteryPanel
extends Control
## M51 mobile-first ship mastery browser for the 3 starters + 50 main designs.

var hud: GameHud
var body: VBoxContainer
var filter := "owned"

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	theme = NauticalTheme.create()
	mouse_filter = MOUSE_FILTER_STOP
	hide()

func open(owner_hud: GameHud) -> void:
	hud = owner_hud
	_rebuild()
	show()

func close() -> void:
	hide()
	if hud != null: hud.complete_routed_panel(self)
	queue_free()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _rebuild() -> void:
	for child in get_children(): child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color(0.008,0.025,0.04,0.95)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var outer := MarginContainer.new()
	outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: outer.add_theme_constant_override("margin_"+side, 12)
	add_child(outer)
	var column := VBoxContainer.new()
	outer.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "SCHIFFS-MASTERY · 3 STARTER + 50 HAUPTDESIGNS"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header,"Schließen",close)
	var filters := HBoxContainer.new()
	column.add_child(filters)
	for id in ["owned","eligible","all"]:
		_button(filters,id.to_upper(),func(value=id): filter=value; _rebuild())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	_build_cards()

func _build_cards() -> void:
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	var voyage := player.get_node("Voyage") as VoyageProgress
	_add_label("Aktiv: %s · Kartenlevel %d · jedes Design besitzt eigene Mastery 1–10" % [roster.selected_ship().display_name, voyage.map_level()])
	var ids: Array[String] = []
	for starter in ShipCatalog.SHIPS:
		ids.append(str(starter.id))
	for design in MainProgressionFleet.data().get("designs", []):
		ids.append(str(design.id))
	for id in ids:
		var owned := roster.owns_ship(id)
		var definition := MainProgressionFleet.design(id)
		var eligible := owned
		if not definition.is_empty():
			eligible = roster.is_main_design_eligible(id)
		if filter == "owned" and not owned: continue
		if filter == "eligible" and not eligible: continue
		_card(roster, id, owned, eligible)

func _card(roster: PlayerShipRoster, id: String, owned: bool, eligible: bool) -> void:
	var profile := ShipCatalog.profile_by_id(id)
	var level := roster.mastery_level(id) if owned else 1
	var xp := roster.mastery_xp(id) if owned else 0
	var need := ShipMasteryCatalog.xp_to_next(level)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	body.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(72,72) * NauticalTheme.density_scale()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = VisualAssetCatalog.texture(_card_slot(id))
	row.add_child(icon)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(text_column)
	var heading := Label.new()
	heading.text = "%s · %s" % [str(profile.display_name), str(profile.role)]
	text_column.add_child(heading)
	var state := Label.new()
	state.text = ("AKTIV" if roster.selected_ship_id == id else ("IM BESITZ" if owned else ("FREISCHALTBAR" if eligible else "GESPERRT")))
	text_column.add_child(state)
	var mastery := Label.new()
	mastery.text = "Schiffslevel %d / %d%s" % [level, ShipMasteryCatalog.max_level(), " · MAX" if level >= ShipMasteryCatalog.max_level() else " · XP %d/%d" % [xp,need]]
	text_column.add_child(mastery)
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 18 * NauticalTheme.density_scale()
	progress.max_value = 1.0
	progress.value = roster.mastery_progress(id) if owned else 0.0
	progress.show_percentage = false
	text_column.add_child(progress)
	var bonus := 2.0 * float(maxi(0,level-1))
	var stats := Label.new()
	stats.text = "Mastery-Bonus: Hull +%.0f%% · Schaden +%.0f%% · separat für dieses Design" % [bonus,bonus]
	text_column.add_child(stats)
	if not MainProgressionFleet.design(id).is_empty():
		var definition := MainProgressionFleet.design(id)
		var req := int(definition.get("unlock",{}).get("map_level",999))
		var production := str(definition.get("production_status","PREPARED"))
		var meta := Label.new()
		meta.text = "Eligibility: Kartenlevel %d · Visual Slot: %s · %s" % [req,str(definition.get("visual_slot",id)),production]
		text_column.add_child(meta)
	_button(text_column,"3D-Werft / Vergleich",func(ship_id=id): _open_shipyard(ship_id))
	if owned and roster.selected_ship_id != id:
		_button(text_column,"Im Hafen ausrüsten",func(ship_id=id): _equip(roster,ship_id))
	elif not owned:
		var hint := Label.new()
		hint.text = "Eligible – noch erspielen." if eligible else "Noch nicht eligible."
		text_column.add_child(hint)
	var separator := HSeparator.new()
	body.add_child(separator)


func _open_shipyard(id: String) -> void:
	var screen := ShipyardPanel.new()
	get_tree().root.add_child(screen)
	if hud != null: hud.route_panel(screen, hud.routed_return("progress"))
	screen.open(hud,id)

func _equip(roster: PlayerShipRoster, id: String) -> void:
	var ok := roster.equip_owned_ship(id)
	if hud != null: hud.note("Schiff ausgerüstet" if ok else "Schiff nicht verfügbar oder aktuell nicht wechselbar")
	_rebuild()

func _card_slot(id: String) -> String:
	if id.begins_with("ship_main_"): return "ship_card_" + id.trim_prefix("ship_")
	return "ship_card_" + id

func _add_label(value: String) -> void:
	var label := Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_child(label)

func _button(parent: Control, value: String, callback: Callable) -> Button:
	var b:=Button.new()
	b.text=value
	b.custom_minimum_size.y=56*NauticalTheme.density_scale()
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
