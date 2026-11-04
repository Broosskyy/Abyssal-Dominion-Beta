class_name CaptainJournal
extends Control
## Read-only contracts plus existing harbor actions; no duplicate reward-claim path.
const TITLES := {"sink": "Korsarenjagd", "loot": "Bergung auf See", "dock": "Hafenroute"}
const DETAILS := {"sink": "Versenke feindliche Schiffe. Nur dir zugerechnete Abschüsse zählen.", "loot": "Sammle treibende Beute ein. Jede Kiste zählt einmal.", "dock": "Lege bei Hafenbesuchen an. Wiederholtes Anklicken während desselben Besuchs zählt nicht erneut."}

var player: ShipMotor
var opener: Button
var shade: ColorRect
var panel: PanelContainer
var close_button: Button
var mission_tab: Button
var harbor_tab: Button
var mission_page: VBoxContainer
var harbor_page: VBoxContainer
var mission_rows: Array[Dictionary] = []
var completed: Label
var harbor_summary: Label
var dock_button: Button
var supplies_button: Button
var elapsed := 0.0
var page := "missions"

func _ready() -> void:
	theme = NauticalTheme.create()
	add_to_group("captain_journal")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	opener = Button.new()
	opener.name = "MissionOpener"
	opener.flat = true
	opener.tooltip_text = "Auftragsbuch öffnen"
	opener.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	opener.pressed.connect(show_page.bind("missions"))
	add_child(opener)
	shade = ColorRect.new()
	shade.color = Color(0.008, 0.025, 0.04, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", NauticalHud.box_style())
	shade.add_child(panel)
	var margin := _margin(panel, 12)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	close_button = _button("KAPITÄNSBUCH  ·  SCHLIESSEN [ESC]", close)
	column.add_child(close_button)
	var tabs := HBoxContainer.new()
	column.add_child(tabs)
	mission_tab = _button("AUFTRÄGE", show_page.bind("missions"))
	harbor_tab = _button("HAFEN", show_page.bind("harbor"))
	tabs.add_child(mission_tab)
	tabs.add_child(harbor_tab)
	var scroll := ScrollContainer.new()
	scroll.name = "PagesScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var pages := VBoxContainer.new()
	pages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pages)
	mission_page = VBoxContainer.new()
	mission_page.add_theme_constant_override("separation", 12)
	pages.add_child(mission_page)
	_label(mission_page, "AUFTRÄGE AUF SEE", 22, NauticalHud.LIGHT)
	_label(mission_page, "Belohnungen werden bei Abschluss automatisch gutgeschrieben. Die nächsten Aufgaben starten der Reihe nach.")
	for index in MissionSystem.MISSIONS.size():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", NauticalHud.box_style())
		mission_page.add_child(card)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 7)
		_margin(card, 10).add_child(inner)
		var title := _label(inner, "", 18, NauticalHud.LIGHT)
		var detail := _label(inner, "")
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 18
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = NauticalHud.GREEN
		bar.add_theme_stylebox_override("fill", fill)
		inner.add_child(bar)
		var reward := _label(inner, "", 14, NauticalHud.LIGHT)
		mission_rows.append({"title": title, "detail": detail, "bar": bar, "reward": reward})
	completed = _label(mission_page, "", 14, NauticalHud.GREEN)
	harbor_page = VBoxContainer.new()
	harbor_page.add_theme_constant_override("separation", 12)
	pages.add_child(harbor_page)
	_label(harbor_page, "LOKALER HAFEN", 22, NauticalHud.LIGHT)
	harbor_summary = _label(harbor_page, "", 16)
	dock_button = _button("ANLEGEN · LOKALE HAFENDIENSTE", dock)
	harbor_page.add_child(dock_button)
	supplies_button = _button("ARSENAL / VERSORGUNG ÖFFNEN", supplies)
	harbor_page.add_child(supplies_button)
	_label(harbor_page, "Anlegen setzt den Wiederkehrpunkt und aktiviert ausschließlich lokale Hafendienste. Werft, Ausrüstung, normale Quests und globale Metasysteme bleiben unabhängig vom Hafen erreichbar.")
	_label(harbor_page, "Lokaler Teststand. Die Seewelt läuft im Hintergrund weiter. Kein Onlinehandel, keine Gildenverwaltung und kein gemeinsamer Server.", 13, NauticalHud.GOLD)
	shade.hide()
	resized.connect(_layout)
	_layout()
	_refresh()

func _margin(parent: Node, amount: int) -> MarginContainer:
	var result := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		result.add_theme_constant_override("margin_" + side, amount)
	parent.add_child(result)
	return result

func _label(parent: Node, value: String, font_size := 15, color := NauticalHud.TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.clip_text = true
	button.custom_minimum_size.y = 52 * NauticalTheme.density_scale()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", NauticalHud.box_style())
	button.add_theme_color_override("font_color", NauticalHud.LIGHT)
	button.add_theme_font_size_override("font_size", roundi(13 * NauticalTheme.density_scale()))
	button.pressed.connect(callback)
	return button

func _layout() -> void:
	if panel == null: return
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	var safe := hud._safe_rect() if hud != null else get_viewport_rect()
	opener.position = NauticalLayout.calculate(safe).mission.position
	opener.size = NauticalLayout.calculate(safe).mission.size
	var sx := NauticalTheme.density_scale()
	panel.size = Vector2(minf(660 * sx, safe.size.x - 24 * sx), safe.size.y - 24 * sx)
	panel.position = safe.get_center() - panel.size * 0.5

func show_page(value: String) -> void:
	if player.get_meta("command_open", false) or player.get_meta("settings_open", false): return
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	if player.get_meta("inventory_open", false) or (player.get_node("Progression") as PlayerProgression).shop_open or (hud != null and hud.global_map_open): return
	if (player.get_node("Health") as ShipHealth).is_sunk: return
	page = value
	shade.show()
	player.set_meta("journal_open", true)
	(player.get_node("PlayerInput") as PlayerShipInput).cancel_navigation()
	player.stop_ship()
	opener.hide()
	_refresh()
	close_button.grab_focus()

func close() -> void:
	shade.hide()
	player.set_meta("journal_open", false)
	# Keyboard activation of the focused close button must not also fire a salvo.
	player.set_meta("ui_action_guard_until", Time.get_ticks_msec() + 150)
	close_button.release_focus()
	opener.show()

func _input(event: InputEvent) -> void:
	if shade.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < 0.2: return
	elapsed = 0
	if shade.visible and (player.get_node("Health") as ShipHealth).is_sunk:
		close()
	var hud := get_tree().get_first_node_in_group("hud") as GameHud
	opener.visible = not shade.visible and not player.get_meta("inventory_open", false) and not player.get_meta("command_open", false) and not player.get_meta("settings_open", false) and not (player.get_node("Progression") as PlayerProgression).shop_open and not (hud != null and hud.global_map_open)
	if shade.visible: _refresh()

func _refresh() -> void:
	mission_page.visible = page == "missions"
	harbor_page.visible = page == "harbor"
	mission_tab.disabled = page == "missions"
	harbor_tab.disabled = page == "harbor"
	var missions := player.get_node("Missions") as MissionSystem
	for offset in mission_rows.size():
		var mission: Dictionary = MissionSystem.MISSIONS[(missions.mission_index + offset) % MissionSystem.MISSIONS.size()]
		var row: Dictionary = mission_rows[offset]
		var progress := missions.progress if offset == 0 else 0
		row.title.text = ("AKTIV  ·  " if offset == 0 else "DANACH  ·  ") + str(TITLES[mission.kind])
		row.detail.text = str(DETAILS[mission.kind]) + "\nFortschritt: %d / %d" % [progress, mission.target]
		row.bar.max_value = mission.target
		row.bar.value = progress
		row.reward.text = "Belohnung: %d Gold · %d EXP" % [mission.coins, mission.xp]
	completed.text = "Abgeschlossene Aufträge: %d" % missions.completed_count
	if not missions.last_completed.is_empty():
		completed.text += "\nZuletzt in dieser Sitzung: %s · +%d Gold / +%d EXP" % [TITLES[missions.last_completed.kind], missions.last_completed.coins, missions.last_completed.xp]
	var port := _nearby_port()
	dock_button.disabled = port == null
	var health := player.get_node("Health") as ShipHealth
	var inventory := player.get_node("Inventory") as PlayerInventory
	var progression := player.get_node("Progression") as PlayerProgression
	harbor_summary.text = (port.port_name if port != null else "Auf See — zum Anlegen in Hafennähe fahren") + "\nRumpf: %.0f / %.0f\nGold: %d · Eisenkugeln: %d · Reparaturen: %d" % [health.current_health, health.max_health, progression.coins, inventory.count("iron"), inventory.count("repair")]

func _nearby_port() -> PortInteraction:
	if not player.has_meta("nearby_port"): return null
	var port = player.get_meta("nearby_port")
	return port if is_instance_valid(port) and port is PortInteraction and port.nearby_player == player and port.is_inside_tree() else null

func dock() -> void:
	var port := _nearby_port()
	if port == null: return
	close()
	port.activate(player)

func supplies() -> void:
	close()
	var arsenal := get_tree().get_first_node_in_group("arsenal_ui") as ArsenalPanel
	if arsenal != null: arsenal.toggle()

func _exit_tree() -> void:
	if is_instance_valid(player): player.set_meta("journal_open", false)
