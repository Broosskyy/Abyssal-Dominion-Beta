class_name LocalProfileStore
extends RefCounted
## Passwordless offline slots. Never use as network authentication.

const DEFAULT_PATH := "user://seefight_profiles_v1.json"
const MAX_PROFILES := 8
var path := DEFAULT_PATH
var memory_only := false
var profiles: Array[Dictionary] = []
var error := ""
var _read_failed := false


func load_profiles() -> void:
	profiles.clear()
	error = ""
	_read_failed = false
	if memory_only or not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	var status := parser.parse(FileAccess.get_file_as_string(path))
	var data = parser.data if status == OK else null
	if not data is Dictionary or data.get("version") != 1 or not data.get("profiles") is Array:
		_read_failed = true
		error = "Profil-Datei nicht lesbar. Sie bleibt unverändert; Gastmodus ist verfügbar."
		return
	var used_ids := []
	for item in data.profiles:
		if not item is Dictionary or not valid_id(str(item.get("id", ""))) or not valid_name(str(item.get("name", ""))):
			_read_failed = true
			continue
		if used_ids.has(item.id) or not find_profile(item.name).is_empty() or profiles.size() >= MAX_PROFILES:
			_read_failed = true
			continue
		profiles.append({"id": str(item.id), "name": str(item.name)})
		used_ids.append(item.id)
	if _read_failed:
		error = "Ungültige Profileinträge. Neue Profile sind zum Schutz gesperrt."


static func valid_name(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9][A-Za-z0-9 _-]{2,19}$")
	return value == value.strip_edges() and regex.search(value) != null


static func valid_id(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9a-f]{32}$")
	return regex.search(value) != null


func find_profile(display_name: String) -> Dictionary:
	for profile in profiles:
		if str(profile.name).to_lower() == display_name.strip_edges().to_lower():
			return profile.duplicate()
	return {}


func register_profile(display_name: String) -> Dictionary:
	error = ""
	var clean := display_name.strip_edges()
	if _read_failed:
		error = "Beschädigte Profil-Datei bleibt unverändert. Bitte Gastmodus verwenden."
	elif not valid_name(clean):
		error = "3–20 Zeichen: A–Z, 0–9, Leerzeichen, _ oder -. Beginn mit Buchstabe/Zahl."
	elif not find_profile(clean).is_empty():
		error = "Dieses lokale Profil existiert bereits. Bitte über Login öffnen."
	elif profiles.size() >= MAX_PROFILES:
		error = "Maximal acht lokale Profile. Bitte ein vorhandenes Profil öffnen."
	if not error.is_empty():
		return {}
	var profile := {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "name": clean}
	profiles.append(profile)
	if not _persist():
		profiles.pop_back()
		error = "Speichern nicht möglich. Kein Profil angelegt; Gastmodus ist verfügbar."
		return {}
	return profile.duplicate()


func _persist() -> bool:
	if memory_only:
		return true
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "profiles": profiles}, "  "))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok and DirAccess.rename_absolute(path + ".tmp", path) == OK


static func save_path(profile: Dictionary) -> String:
	var id := str(profile.get("id", ""))
	return "user://seefight_profile_%s_save.json" % id if valid_id(id) else ""
