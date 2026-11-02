class_name EntryScreen
extends Control

signal action_requested(action: String, value: String)
const INK := Color("061620")
const GOLD := Color("e8c784")
const MUTED := Color("adc7cf")
var screen := "splash"
var session: LocalSession
var settings: ClientSettings
var controls := {}
var panel: PanelContainer
var body: VBoxContainer
var name_field: LineEdit
var error_label: Label
var loading_bar: ProgressBar
var split: BoxContainer
var compact := false
var _layout_pending := false
var home_data := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = NauticalTheme.create()
	theme.default_font_size = 17
	for type in ["LineEdit"]:
		theme.set_stylebox("normal", type, _box(Color("123543"), Color("386070")))
		theme.set_stylebox("hover", type, _box(Color("204c5e"), GOLD))
		theme.set_stylebox("focus", type, _box(Color(0, 0, 0, 0), GOLD, 2))
		theme.set_stylebox("pressed", type, _box(Color("2a6172"), GOLD))
	theme.set_color("font_color", "LineEdit", Color.WHITE)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_constant("separation", "VBoxContainer", 12)
	theme.set_constant("separation", "HBoxContainer", 12)
	resized.connect(_layout)
	show_screen("splash")


func _box(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func show_screen(value: String) -> void:
	screen = value
	compact = get_viewport_rect().size.y < 520
	controls.clear()
	name_field = null
	error_label = null
	loading_bar = null
	split = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := ColorRect.new()
	background.color = INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var artwork := TextureRect.new()
	artwork.texture = VisualAssetCatalog.texture("harbor_backdrop")
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(artwork)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var outer := MarginContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		outer.add_theme_constant_override("margin_" + side, 20)
	scroll.add_child(outer)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(Color("08232e"), Color("365363")))
	center.add_child(panel)
	body = VBoxContainer.new()
	if compact:
		body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	_label(body, "SEE FIGHT 3D" + ("  /  M57" if compact else ""), 20 if compact else 30, GOLD)
	if not compact:
		_label(body, "REKONSTRUKTION  /  M57  /  LOKALER TEST", 12, MUTED)
	body.add_child(HSeparator.new())
	match screen:
		"splash": _splash()
		"login", "register": _auth()
		"home": _home()
		"settings": _settings()
		"loading": _loading()
	_layout()


func _layout() -> void:
	if not is_instance_valid(panel):
		return
	if compact != (size.y < 520) and not _layout_pending:
		_layout_pending = true
		_refresh_layout.call_deferred()
	panel.custom_minimum_size.x = minf(1000 if screen == "home" else 510, maxf(250, size.x - 40))
	if split != null:
		split.vertical = size.x < 760


func _refresh_layout() -> void:
	_layout_pending = false
	var typed := name_field.text if is_instance_valid(name_field) else ""
	var had_focus := is_instance_valid(name_field) and name_field.has_focus()
	var message := error_label.text if is_instance_valid(error_label) and error_label.visible else ""
	show_screen(screen)
	if is_instance_valid(name_field):
		name_field.text = typed
		if had_focus:
			name_field.grab_focus()
			name_field.caret_column = typed.length()
	if not message.is_empty():
		show_error(message)


func _label(parent: Node, text: String, font_size: int = 17, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", roundi(font_size * NauticalTheme.density_scale()))
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label


func _button(parent: Node, title: String, id: String, primary := false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 50 * NauticalTheme.density_scale()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if primary:
		button.add_theme_stylebox_override("normal", NauticalTheme.graphic_style("button_hover"))
		button.add_theme_color_override("font_color", GOLD)
		button.add_theme_color_override("font_focus_color", GOLD)
	button.pressed.connect(func(): action_requested.emit(id, name_field.text if is_instance_valid(name_field) else ""))
	parent.add_child(button)
	controls[id] = button
	return button


func _splash() -> void:
	var icon := TextureRect.new()
	icon.texture = VisualAssetCatalog.texture("captain_crest")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size.y = 130
	body.add_child(icon)
	_label(body, "Dein Kurs beginnt hier.", 26)
	_label(body, "Schiffe, Inseln und Seeschlachten aus den vorhandenen Spieldateien rekonstruiert.", 17, MUTED)
	_button(body, "Weiter", "continue", true).grab_focus()
	_label(body, "Testprojekt · Kein offizieller Server · Nicht mit Abyssal Dominion verbunden", 12, MUTED)


func _auth() -> void:
	var tabs := HBoxContainer.new()
	body.add_child(tabs)
	_button(tabs, "Login", "login_tab", screen == "login")
	_button(tabs, "Registrieren", "register_tab", screen == "register")
	_label(body, "Willkommen zurück." if screen == "login" else "Dein Kapitänsprofil", 24)
	_label(body, "Lokaler Testzugang — kein Onlinekonto, kein Passwort. Profile sind auf diesem Gerät frei zugänglich.", 14, MUTED)
	_label(body, "Kapitänsname", 15)
	name_field = LineEdit.new()
	name_field.placeholder_text = "z. B. Corsair"
	name_field.max_length = 20
	name_field.custom_minimum_size.y = 50 * NauticalTheme.density_scale()
	name_field.text_submitted.connect(func(_text): action_requested.emit("submit", name_field.text))
	body.add_child(name_field)
	controls["name"] = name_field
	if screen == "login" and not session.store.profiles.is_empty():
		name_field.text = str(session.store.profiles[0].name)
		var picker := OptionButton.new()
		picker.custom_minimum_size.y = 48 * NauticalTheme.density_scale()
		for profile in session.store.profiles:
			picker.add_item(str(profile.name))
		picker.item_selected.connect(func(index): name_field.text = str(session.store.profiles[index].name))
		body.add_child(picker)
		controls["profiles"] = picker
	error_label = _label(body, session.store.error, 14, Color("ffbeaa"))
	error_label.visible = not error_label.text.is_empty()
	_button(body, "Profil öffnen" if screen == "login" else "Lokal registrieren", "submit", true)
	_button(body, "Als Gast testen", "guest")
	_label(body, "Profil: lokaler Spielstand. Gast: ohne Speicherung. Keine E-Mail, keine Cloud-Synchronisierung.", 12, MUTED)


func _home() -> void:
	if not compact:
		var portrait := TextureRect.new()
		portrait.texture = VisualAssetCatalog.texture("captain_portrait")
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size.y = 80
		body.add_child(portrait)
	_label(body, "Willkommen an Bord, %s." % session.display_name(), 20 if compact else 26)
	_label(body, "Gastmodus · Fortschritt wird nicht gespeichert." if session.guest else "Lokales Kapitänsprofil · Spielstand nur auf diesem Gerät/Browser.", 12 if compact else 14, MUTED)
	split = BoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	body.add_child(split)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(info)
	var saved := session.saved_summary()
	home_data = HomeSummary.from_save(saved)
	if saved.is_empty():
		_label(info, "STARTSCHIFF · Swift Barco", 14, GOLD)
		if not compact:
			_label(info, "Du startest klein. Clipper und Iron Chalupa erspielst du durch Anfängeraufträge auf Kartenlevel 1–5.", 13, MUTED)
	var progress: Dictionary = saved.get("progression", {})
	if not compact:
		_label(info, "DEIN NÄCHSTER TÖRN", 13, GOLD)
	_label(info, str(home_data.sector_name), 20 if compact else 24)
	_label(info, "Piratenlevel %d  ·  %d Münzen" % [int(progress.get("level", 1)), int(progress.get("coins", 250))])
	if not compact:
		_label(info, "Inseln erkunden, Gegner bekämpfen und im Hafen ausrüsten.", 16, MUTED)
	_button(info, "ZUR SEE  ›", "play", true)
	var actions := HBoxContainer.new()
	info.add_child(actions)
	_button(actions, "Optionen", "settings")
	_button(actions, "Abmelden", "logout")
	if session.can_import_legacy():
		_button(info, "M12-Spielstand kopieren", "import_legacy")
	var showcase := VBoxContainer.new()
	showcase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(showcase)
	var preview := EntryShipPreview.new()
	preview.ship_id = str(home_data.ship_id)
	showcase.add_child(preview)
	if compact:
		preview.custom_minimum_size.y = 120
	_label(showcase, str(home_data.ship_name).to_upper() + "  /  3D-VORSCHAU", 13, GOLD)
	_label(showcase, "Austauschbarer GLB-Platzhalter" if settings.values.visual_assets == "placeholder" else "Rekonstruierte Original-Meshes · Texturen teils unvollständig", 12, MUTED)
	if not compact:
		body.add_child(HSeparator.new())
		_label(body, "NEU IN M57", 13, GOLD)
		_label(body, "Kleines Startschiff · Anfängeraufträge · Kartenlevel 1–6", 15, MUTED)
	error_label = _label(body, "", 14, Color("ffbeaa"))
	error_label.hide()


func _settings() -> void:
	_label(body, "Einstellungen", 24)
	_label(body, "Für dieses Gerät / diesen Browser. Unabhängig vom Kapitänsprofil.", 14, MUTED)
	var volume_label := _label(body, "Lautstärke: %d %%" % roundi(float(settings.values.volume) * 100), 16)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.value = float(settings.values.volume) * 100.0
	volume.custom_minimum_size.y = 48 * NauticalTheme.density_scale()
	body.add_child(volume)
	controls["volume"] = volume
	volume.value_changed.connect(func(value):
		if not settings.update_value("volume", value / 100.0):
			volume.set_value_no_signal(float(settings.values.volume) * 100.0)
		volume_label.text = "Lautstärke: %d %%" % roundi(float(settings.values.volume) * 100)
		show_error(settings.error))
	_setting_toggle("Stumm", "muted")
	_setting_slider("Meeresatmosphäre", "ambience_volume", 0, 1, 0.05)
	_setting_slider("Kampfgeräusche", "combat_volume", 0, 1, 0.05)
	_label(body, "Grafikqualität", 16)
	var quality := OptionButton.new()
	quality.custom_minimum_size.y = 50
	for title in ["Automatisch", "Niedrig", "Ausgewogen", "Hoch"]:
		quality.add_item(title)
	quality.select(ClientSettings.QUALITIES.find(settings.values.quality))
	body.add_child(quality)
	controls["quality"] = quality
	quality.item_selected.connect(func(index):
		if not settings.update_value("quality", ClientSettings.QUALITIES[index]):
			quality.select(ClientSettings.QUALITIES.find(settings.values.quality))
		show_error(settings.error))
	_setting_choice("Bildratenlimit", "fps_limit", [30, 60, 120], ["30 FPS", "60 FPS", "120 FPS"])
	_setting_slider("3D-Auflösung (Faktor des Qualitätsprofils)", "render_scale", 0.6, 1.25, 0.05)
	_setting_toggle("Schatten (ab Ausgewogen)", "shadows")
	if not OS.has_feature("web"):
		_setting_toggle("VSync", "vsync")
		if not OS.has_feature("mobile"): _setting_toggle("Vollbild", "fullscreen")
	_setting_choice("3D-Grafiken (ab nächstem Seestart)", "visual_assets", ["placeholder", "recovered"], ["Austauschbare GLB-Platzhalter", "Rekonstruierte Unity-Referenzen"])
	_setting_slider("Kamera-Empfindlichkeit", "camera_sensitivity", 0.5, 2.0, 0.1)
	_setting_toggle("Kamera weich nachführen", "camera_smoothing")
	_setting_toggle("Weniger Kamerabewegung / Wasseranimation", "reduced_motion")
	_setting_toggle("Mündungsblitze ausblenden", "reduced_flashes")
	_setting_slider("Effektintensität", "effect_intensity", 0.0, 1.0, 0.1)
	_setting_toggle("Schiffsnamen anzeigen", "show_names")
	_setting_toggle("Lebensbalken anzeigen", "show_health")
	_setting_toggle("Schadenszahlen anzeigen", "show_damage")
	_setting_toggle("Kartenwechsel anzeigen", "map_transition")
	_setting_toggle("Nur eigenen Schaden anzeigen", "only_own_damage")
	_label(body, "Eigener Schaden = von deinem Schiff verursachter Schaden.", 12, MUTED)
	_setting_toggle("Eine sichtbare Kugel pro Salve", "single_visual_ball")
	_setting_toggle("Effekttexte anzeigen", "effect_texts")
	_label(body, "HUD / Benutzeroberfläche", 16, GOLD)
	_label(body, "Auf See kannst du HUD-Bereiche per Finger oder Maus verschieben, skalieren und teilweise ausblenden. Standard/Combat/Minimal-Presets sowie getrennte Mobile-/Desktop-Layouts bleiben im sicheren Vollbildbereich.", 13, MUTED)
	_button(body, "HUD / UI ANPASSEN", "hud_layout")
	_label(body, "Weniger sichtbare Kugeln spart Grafikobjekte. Alle Treffer und der Munitionsverbrauch bleiben gleich.", 13, MUTED)
	_label(body, "Grafik verändert Auflösung, Schatten und Schaum-Sichtweite – keine Spielregeln. Automatisch passt die Qualität bei niedriger Bildrate an.", 13, MUTED)
	error_label = _label(body, settings.error, 14, Color("ffbeaa"))
	error_label.visible = not settings.error.is_empty()
	var reset := Button.new()
	reset.text = "Nur Einstellungen zurücksetzen"
	reset.custom_minimum_size.y = 50
	body.add_child(reset)
	controls["settings_reset"] = reset
	reset.pressed.connect(func():
		if settings.reset_defaults():
			show_screen.call_deferred("settings")
		else:
			show_error(settings.error))
	_button(body, "Zurück", "settings_back", true)

func _setting_choice(title: String, key: String, values: Array, titles: Array) -> void:
	_label(body, title, 16)
	var picker := OptionButton.new()
	picker.custom_minimum_size.y = 50
	for item in titles: picker.add_item(item)
	picker.select(maxi(0, values.find(settings.values[key])))
	body.add_child(picker)
	controls[key] = picker
	picker.item_selected.connect(func(index):
		if not settings.update_value(key, values[index]): picker.select(values.find(settings.values[key]))
		show_error(settings.error))

func _setting_slider(title: String, key: String, minimum: float, maximum: float, step_value: float) -> void:
	var label := _label(body, "%s: %.2f" % [title, settings.values[key]], 16)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step_value
	slider.value = float(settings.values[key])
	slider.custom_minimum_size.y = 48
	body.add_child(slider)
	controls[key] = slider
	slider.value_changed.connect(func(value):
		if not settings.update_value(key, value): slider.set_value_no_signal(float(settings.values[key]))
		label.text = "%s: %.2f" % [title, settings.values[key]]
		show_error(settings.error))


func _setting_toggle(title: String, key: String) -> void:
	var toggle := CheckButton.new()
	toggle.text = title
	toggle.custom_minimum_size.y = 50
	toggle.button_pressed = bool(settings.values[key])
	body.add_child(toggle)
	controls[key] = toggle
	toggle.toggled.connect(func(value):
		if not settings.update_value(key, value):
			toggle.set_pressed_no_signal(bool(settings.values[key]))
		show_error(settings.error))


func _loading() -> void:
	_label(body, "Kurs setzen …", 26)
	_label(body, "Die Spielszene wird geladen. Der erste Start kann etwas länger dauern.", 16, MUTED)
	loading_bar = ProgressBar.new()
	loading_bar.custom_minimum_size.y = 18
	body.add_child(loading_bar)
	error_label = _label(body, "", 14, Color("ffbeaa"))
	error_label.hide()


func show_error(message: String) -> void:
	if is_instance_valid(error_label):
		error_label.text = message
		error_label.visible = not message.is_empty()


static func control_rect(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	return {"x": rect.get_center().x, "y": rect.get_center().y, "width": rect.size.x, "height": rect.size.y}


func debug_snapshot() -> Dictionary:
	var positions := {}
	for id in controls:
		if is_instance_valid(controls[id]):
			positions[id] = control_rect(controls[id])
	return {"screen": screen, "controls": positions,
		"home": home_data, "settings": settings.values if settings != null else {},
		"name_input": name_field.text if is_instance_valid(name_field) else "",
		"error": error_label.text if is_instance_valid(error_label) and error_label.visible else ""}
