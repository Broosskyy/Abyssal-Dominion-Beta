extends Control
var address: LineEdit
var notice: Label
func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("081e2b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 500
	box.add_theme_constant_override("separation",14)
	center.add_child(box)
	var title := Label.new()
	title.text = "ABYSSAL DOMINION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",Color("e8c789"))
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "KLASSISCHE SEEKARTEN · M3051 ANDROID TEST"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var local := Button.new()
	local.text = "LOKALE SEEKARTE SPIELEN"
	local.custom_minimum_size.y = 54
	local.pressed.connect(func():get_tree().change_scene_to_file("res://scenes/classic/classic_sea_map.tscn"))
	box.add_child(local)
	address = LineEdit.new()
	address.text = "ws://127.0.0.1:9080"
	address.placeholder_text = "wss://dein-spielserver.example"
	address.custom_minimum_size.y = 48
	box.add_child(address)
	var online := Button.new()
	online.text = "GEMEINSAME TESTKARTE BETRETEN"
	online.custom_minimum_size.y = 54
	online.pressed.connect(_connect_zone)
	box.add_child(online)
	notice = Label.new()
	notice.text = "Testserver separat starten. Gastfortschritt wird nicht gespeichert.\nHandy: Querformat · Tippen zum Fahren · Ziele antippen"
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(notice)
func _connect_zone() -> void:
	var url := address.text.strip_edges()
	if not (url.begins_with("ws://") or url.begins_with("wss://")):
		notice.text = "Bitte eine ws:// oder wss:// Serveradresse eingeben."
		return
	if OS.has_feature("web") and JavaScriptBridge.eval("window.location.protocol") == "https:" and not url.begins_with("wss://"):
		notice.text = "Diese HTTPS-Seite benötigt einen sicheren wss:// Spielserver."
		return
	get_tree().root.set_meta("zone_url",url)
	get_tree().change_scene_to_file("res://scenes/network/crossplay_chart.tscn")
