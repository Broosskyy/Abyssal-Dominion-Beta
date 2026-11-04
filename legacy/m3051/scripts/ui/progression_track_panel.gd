class_name ProgressionTrackPanel
extends Control
## M57 mobile-first separation of map level, eligibility, earned ownership and local reward audit.

var hud: GameHud
var body: VBoxContainer
var filter := "next"

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
	shade.color = Color(0.006,0.02,0.035,0.96)
	shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side, 10)
	add_child(margin)
	var page := VBoxContainer.new()
	margin.add_child(page)
	var header := HBoxContainer.new()
	page.add_child(header)
	var title := Label.new()
	title.text = "HAUPTPROGRESSION · KARTENLEVEL ≠ BESITZ"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_button(header,"Schließen",close)
	var filters := HBoxContainer.new()
	page.add_child(filters)
	for id in ["next","eligible","owned","all","history"]:
		_button(filters,id.to_upper(),func(value=id): filter=value; _rebuild())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(body)
	_build_content()

func _build_content() -> void:
	var player := get_tree().get_first_node_in_group("player") as ShipMotor
	if player == null: return
	var voyage := player.get_node("Voyage") as VoyageProgress
	var roster := player.get_node("ShipRoster") as PlayerShipRoster
	_label(body,"Aktuelles Kartenlevel: %d" % voyage.map_level())
	_label(body,"Regel: Kartenlevel erzeugt Eligibility. Besitz entsteht erst durch den vorgesehenen erspielten Meilenstein.")
	if filter == "history":
		_build_history(roster)
		return
	var rows := ProgressionTrackCatalog.rows(voyage.map_level(),roster)
	var shown := 0
	for row in rows:
		if filter == "owned" and not bool(row.owned): continue
		if filter == "eligible" and (not bool(row.eligible) or bool(row.owned)): continue
		if filter == "next":
			if bool(row.owned): continue
			if int(row.eligibility_map_level) > voyage.map_level() + 4: continue
		_track_card(row, roster)
		shown += 1
		if filter == "next" and shown >= 6: break
	if shown == 0:
		_label(body,"Keine Einträge für diesen Filter.")

func _track_card(row: Dictionary, roster: PlayerShipRoster) -> void:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation",4)
	body.add_child(card)
	var top := HBoxContainer.new()
	card.add_child(top)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(64,64) * NauticalTheme.density_scale()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = VisualAssetCatalog.texture(ShipyardVisualResolver.card_slot_for(str(row.ship_id)))
	top.add_child(icon)
	var state_icon := TextureRect.new()
	state_icon.custom_minimum_size = Vector2(42,42) * NauticalTheme.density_scale()
	state_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	state_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var state_slot := "progression_track_owned" if bool(row.owned) else ("progression_track_eligible" if bool(row.eligible) else "progression_track_locked")
	state_icon.texture = VisualAssetCatalog.texture(state_slot)
	top.add_child(state_icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(text)
	_label(text,"%s · %s" % [str(row.display_name),str(row.role)])
	_label(text,"STATUS · %s" % _state_label(str(row.state)))
	_label(text,"Eligibility ab Kartenlevel %d" % int(row.eligibility_map_level))
	if int(row.reward_boss_level) >= 0:
		var boss_line := HBoxContainer.new()
		text.add_child(boss_line)
		var boss_icon := TextureRect.new()
		boss_icon.custom_minimum_size = Vector2(34,34) * NauticalTheme.density_scale()
		boss_icon.texture = VisualAssetCatalog.texture("progression_track_boss")
		boss_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		boss_line.add_child(boss_icon)
		_label(boss_line,"Ersparter Design-Meilenstein · Boss Kartenlevel %d · %s" % [int(row.reward_boss_level),str(row.reward_source)])
	else:
		_label(text,"Erwerbsweg für diesen späteren Design-Slot noch nicht in PL6–15 gebunden.")
	if bool(row.reward_recorded):
		_label(text,"Lokaler Reward-Audit vorhanden.")
	if bool(row.owned):
		_button(text,"3D-Werft / Mastery",func(id=str(row.ship_id)): _open_shipyard(id))
	var separator := HSeparator.new()
	body.add_child(separator)

func _build_history(roster: PlayerShipRoster) -> void:
	var history := roster.reward_history_rows()
	_label(body,"LOKALE REWARD-HISTORIE · kein Server-/Online-Audit")
	if history.is_empty():
		_label(body,"Noch kein Hauptdesign-Meilenstein protokolliert.")
		return
	for row in history:
		var profile := ShipCatalog.profile_by_id(str(row.get("ship_id","")))
		_label(body,"#%d · %s · Boss KL %d · %s" % [int(row.get("local_sequence",0)),str(profile.display_name),int(row.get("defeated_map_level",-1)),str(row.get("label",""))])

func _state_label(state: String) -> String:
	match state:
		"OWNED": return "IM BESITZ / ERSPIELT"
		"ELIGIBLE": return "FREISCHALTBAR / NOCH ERSPIELEN"
		_: return "GESPERRT"

func _open_shipyard(id: String) -> void:
	var screen := ShipyardPanel.new()
	get_tree().root.add_child(screen)
	if hud != null: hud.route_panel(screen, hud.routed_return("progress"))
	screen.open(hud,id)

func _label(parent: Control, value: String) -> Label:
	var label := Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Control, value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text=value
	b.custom_minimum_size.y=56*NauticalTheme.density_scale()
	b.size_flags_horizontal=SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
