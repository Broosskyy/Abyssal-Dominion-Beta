class_name ClientSettings
extends Node
## Device-local preferences, separate from captain profiles and game saves.
## ShowMapChangeTransition is backed by recovered IL2CPP field names;
## audio/quality behaviour is new reconstruction code, not recovered C# bodies.

signal changed
const DEFAULTS := {"volume": 0.8, "muted": false, "quality": "auto", "map_transition": true,
	"only_own_damage": false, "single_visual_ball": false, "effect_texts": true,
	"fps_limit": 60, "render_scale": 1.0, "shadows": true, "vsync": true,
	"fullscreen": false, "camera_sensitivity": 1.0, "camera_smoothing": true,
	"reduced_motion": false, "reduced_flashes": false, "show_names": true,
	"show_health": true, "show_damage": true, "visual_assets": "placeholder",
	"ambience_volume": 0.7, "combat_volume": 0.8, "effect_intensity": 1.0}
const QUALITIES := ["auto", "low", "balanced", "high"]
var values: Dictionary = DEFAULTS.duplicate()
var path := "user://client_settings_m14.json"
var memory_only := false
var error := ""
var _corrupt := false


func _ready() -> void:
	add_to_group("client_settings")
	memory_only = memory_only or bool(get_tree().root.get_meta("reconstruction_test_mode", false))
	load_settings()
	apply_audio()


static func current(tree: SceneTree) -> ClientSettings:
	return tree.get_first_node_in_group("client_settings") as ClientSettings


static func validate(data: Variant) -> Dictionary:
	var result: Dictionary = DEFAULTS.duplicate()
	if not data is Dictionary:
		return result
	for key in DEFAULTS:
		if DEFAULTS[key] is bool and data.get(key) is bool:
			result[key] = data[key]
	for key in ["volume", "ambience_volume", "combat_volume", "render_scale", "camera_sensitivity", "effect_intensity"]:
		var value: Variant = data.get(key)
		if (value is float or value is int) and is_finite(float(value)):
			var bounds := Vector2(0, 1)
			if key == "render_scale": bounds = Vector2(0.6, 1.25)
			if key == "camera_sensitivity": bounds = Vector2(0.5, 2.0)
			result[key] = clampf(float(value), bounds.x, bounds.y)
	if data.get("fps_limit") is float or data.get("fps_limit") is int:
		if float(data.fps_limit) in [30.0, 60.0, 120.0]: result.fps_limit = int(data.fps_limit)
	if data.get("visual_assets") in ["placeholder", "recovered"]:
		result.visual_assets = data.visual_assets
	if data.get("quality") is String and QUALITIES.has(data.quality):
		result.quality = data.quality
	return result


func load_settings() -> void:
	values = DEFAULTS.duplicate()
	error = ""
	_corrupt = false
	if memory_only or not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	var status := parser.parse(FileAccess.get_file_as_string(path))
	if status != OK or not parser.data is Dictionary or parser.data.get("schema") != 1:
		_corrupt = true
		error = "Einstellungsdatei beschädigt oder unbekannt. Standardwerte aktiv; Datei bleibt erhalten."
		return
	if not parser.data.get("values") is Dictionary:
		_corrupt = true
		error = "Einstellungsdatei beschädigt. Standardwerte aktiv; Datei bleibt erhalten."
		return
	values = validate(parser.data.values)


func update_value(key: String, value: Variant) -> bool:
	if not DEFAULTS.has(key):
		return false
	var candidate := values.duplicate()
	candidate[key] = value
	return _commit(validate(candidate))


func reset_defaults() -> bool:
	return _commit(DEFAULTS.duplicate())


func _commit(candidate: Dictionary) -> bool:
	if _corrupt:
		error = "Beschädigte Einstellungsdatei geschützt. Bitte zuerst sichern und entfernen; Spielstände bleiben unverändert."
		return false
	if not memory_only:
		var writer := GameState.new()
		var success := writer._write_text(path, JSON.stringify({"schema": 1, "values": candidate}))
		writer.free()
		if not success:
			error = "Einstellungen konnten nicht gespeichert werden. Bisherige Werte bleiben aktiv."
			return false
	values = candidate
	error = ""
	apply_audio()
	changed.emit()
	return true


func apply_audio() -> void:
	for channel in ["Ambience", "Combat"]:
		var index := AudioServer.get_bus_index(channel)
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, channel)
			AudioServer.set_bus_send(index, "Master")
		var level := float(values[channel.to_lower() + "_volume"])
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
		AudioServer.set_bus_mute(index, level <= 0.0)
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(values.volume), 0.0001)))
		AudioServer.set_bus_mute(bus, bool(values.muted) or float(values.volume) <= 0.0)


static func show_map_transition(tree: SceneTree) -> bool:
	var settings := current(tree)
	return settings == null or bool(settings.values.map_transition)
