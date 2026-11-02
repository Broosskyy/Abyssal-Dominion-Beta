class_name LocalSession
extends Node

var store := LocalProfileStore.new()
var profile := {}
var guest := false


func _ready() -> void:
	add_to_group("local_session")
	store.memory_only = bool(get_tree().root.get_meta("reconstruction_test_mode", false))
	store.load_profiles()


func active() -> bool:
	return guest or not profile.is_empty()


func display_name() -> String:
	return "Gastkapitän" if guest else str(profile.get("name", "Kapitän"))


func logout() -> void:
	profile.clear()
	guest = false


func saved_summary() -> Dictionary:
	if guest or profile.is_empty():
		return {}
	var reader := GameState.new()
	var result := reader._read_valid_payload(LocalProfileStore.save_path(profile))
	if result.is_empty():
		result = reader._read_valid_payload(LocalProfileStore.save_path(profile) + ".backup")
	reader.free()
	return result


func can_import_legacy() -> bool:
	if guest or profile.is_empty():
		return false
	var destination := LocalProfileStore.save_path(profile)
	if FileAccess.file_exists(destination) or FileAccess.file_exists(destination + ".backup"):
		return false
	var reader := GameState.new()
	var valid := not reader._read_valid_payload(GameState.SAVE_PATH).is_empty()
	reader.free()
	return valid


func import_legacy() -> bool:
	if not can_import_legacy():
		return false
	var writer := GameState.new()
	var copied := writer._write_text(LocalProfileStore.save_path(profile), FileAccess.get_file_as_string(GameState.SAVE_PATH))
	writer.free()
	return copied
