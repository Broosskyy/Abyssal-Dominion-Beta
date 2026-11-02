extends "res://scripts/classic/m3048_user_ship_variants.gd"
## M304.9: Android/Desktop import of CURATED user ship/UI PNG packs.
## Concept sheets and arbitrary ZIPs are intentionally rejected.
const ZIP_LIMIT := 24 * 1024 * 1024
const PNG_LIMIT := 4 * 1024 * 1024
const TOTAL_LIMIT := 48 * 1024 * 1024
const PACK_DIR := "user://abyssal_user_art/"
const INCOMING_ZIP := "user://abyssal_art_import.zip"
var _import_button: Button
var _import_hint: Label
var _native_picker: FileDialog
var _last_import_result := ""

func _find_private_art_pack() -> void:
	_private_art_root = ""
	_private_reference_manifest = {}
	# User-installed art takes priority over an optional resource fixture.
	for root_path in [USER_ART_DATA, USER_ART_RES]:
		if not FileAccess.file_exists(root_path + "pack.json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(root_path + "pack.json"))
		if data is Dictionary and data.has("actors"):
			_private_reference_manifest = data
			_private_art_root = root_path
			return

func _ready() -> void:
	super._ready()
	_hud_header.text = "ABYSSAL DOMINION · M3050 · LOKALE SEEKARTE"
	_build_label.text = "M3050 · LOKALE SEEKARTE & GRAFIKIMPORT"
	_refresh()

func _make_hud() -> void:
	super._make_hud()
	_import_button = _control("GRAFIKPAKET (ZIP) IMPORTIEREN", Callable(self, "_open_art_picker"))
	_import_button.name = "ImportUserArtZip"
	var p := _import_button.get_parent()
	if p != null:
		p.remove_child(_import_button)
	_options.add_child(_import_button)
	_import_button.tooltip_text = "Nur das aufbereitete Grafikpaket mit pack.json und Einzel-PNGs"
	_import_hint = _label(_options, "Original-Collagen benötigen vorherige Aufbereitung.", 10)
	_import_hint.name = "ImportFeedback"
	_native_picker = FileDialog.new()
	_native_picker.name = "NativeArtPackPicker"
	_native_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_native_picker.access = FileDialog.ACCESS_FILESYSTEM
	_native_picker.use_native_dialog = true
	_native_picker.filters = PackedStringArray(["*.zip ; Abyssal Dominion Grafikpaket"])
	_native_picker.file_selected.connect(_on_art_file_selected)
	add_child(_native_picker)

func _layout_hud() -> void:
	super._layout_hud()
	if _import_button == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var width := minf(_options.size.x, screen.x - 12.0)
	var height := minf(402.0, screen.y - 10.0)
	var left := clampf(_options.position.x, 6.0, maxf(6.0, screen.x - width - 6.0))
	var top := clampf(_options.position.y, 5.0, maxf(5.0, screen.y - height - 5.0))
	_place(_options, left, top, width, height)
	# Important: no second overlap with the inherited cosmetics / close buttons.
	var start := maxf(111.0, height - 266.0)
	_place(_art_variants_button, 12.0, start, width - 24.0, 32.0)
	_place(_import_button, 12.0, start + 38.0, width - 24.0, 34.0)
	_place(_options_close, 12.0, start + 81.0, width - 24.0, 34.0)
	_place(_pack_status, 12.0, start + 122.0, width - 24.0, 16.0)
	_place(_import_hint, 12.0, start + 145.0, width - 24.0, 35.0)
	_place(_build_label, 12.0, start + 187.0, width - 24.0, 20.0)

func _open_art_picker() -> void:
	if _native_picker == null:
		return
	_native_picker.popup_centered_ratio(0.75)

func _on_art_file_selected(path: String) -> void:
	var result := _import_zip(path)
	_last_import_result = result
	if _import_hint != null:
		_import_hint.text = result
	_refresh()

func _safe_relative_path(path: String) -> bool:
	if path.is_empty() or path.begins_with("/") or path.contains("\\") or path.contains(":"):
		return false
	for segment in path.split("/"):
		if segment.is_empty() or segment == "." or segment == "..":
			return false
	return true

func _import_zip(source_path: String) -> String:
	var incoming := FileAccess.open(source_path, FileAccess.READ)
	if incoming == null:
		return "Datei nicht lesbar – Dateizugriff prüfen."
	if incoming.get_length() < 100 or incoming.get_length() > ZIP_LIMIT:
		incoming.close()
		return "ZIP ist leer oder über 24 MB. Nur kuratierte Assets."
	var bytes: PackedByteArray = incoming.get_buffer(incoming.get_length())
	incoming.close()
	if source_path != INCOMING_ZIP:
		var write_zip := FileAccess.open(INCOMING_ZIP, FileAccess.WRITE)
		if write_zip == null:
			return "Kein Speicherplatz für ZIP-Import."
		write_zip.store_buffer(bytes)
		write_zip.close()
	var reader := ZIPReader.new()
	if reader.open(INCOMING_ZIP) != OK:
		return "Keine gültige ZIP-Datei."
	var staged: Dictionary = {}
	var total := 0
	var entries := reader.get_files()
	if entries.size() > 160:
		reader.close()
		return "Zu viele Einträge: maximal 160."
	for raw in entries:
		var name := str(raw)
		# ALL untrusted entries, including unused README files, are checked.
		if not _safe_relative_path(name.trim_suffix("/")):
			reader.close()
			return "Unsicherer Pfad im ZIP – Import abgebrochen."
		if name.ends_with("/"):
			continue
		if staged.has(name):
			reader.close()
			return "Doppelter Dateiname im Paket."
		if name != "pack.json" and not (
				(name.begins_with("ships/") or name.begins_with("ship_effect_variants/") or name.begins_with("ui/"))
				and name.ends_with(".png")):
			# Documentation is fine but will not be executed/extracted.
			continue
		var data: PackedByteArray = reader.read_file(name)
		total += data.size()
		if data.is_empty() or data.size() > PNG_LIMIT or total > TOTAL_LIMIT:
			reader.close()
			return "Grafik zu groß oder ZIP enthält ungültige Daten."
		if name.ends_with(".png"):
			var check_image := Image.new()
			if check_image.load_png_from_buffer(data) != OK or check_image.get_width() > 2048 or check_image.get_height() > 2048:
				reader.close()
				return "Ungültige PNG-Grafik: " + name
		staged[name] = data
	reader.close()
	if not staged.has("pack.json"):
		return "Kein pack.json – bitte das AUFBEREITETE Grafikpaket wählen."
	var parsed: Variant = JSON.parse_string((staged["pack.json"] as PackedByteArray).get_string_from_utf8())
	if not (parsed is Dictionary) or not parsed.has("actors") or not (parsed["actors"] is Dictionary):
		return "Paketbeschreibung pack.json ist ungültig."
	var actors: Dictionary = parsed["actors"]
	if not actors.has("PlayerShip") or actors.size() > 64:
		return "Kein Spielerschiff oder zu viele Schiffe."
	for label in actors.keys():
		if str(label) != "PlayerShip" and not str(label).begins_with("NPC_"):
			return "Unbekannter Schiffstyp im Paket."
		var spec: Variant = actors[label]
		if not (spec is Dictionary):
			return "Ungültige Schiffszuordnung."
		var art_path := str(spec.get("path", ""))
		if not art_path.begins_with("ships/") or not staged.has(art_path):
			return "Schiffsgrafik fehlt: " + art_path
		var length := float(spec.get("world_length", 13.5))
		if not is_finite(length) or length < 5.0 or length > 60.0:
			return "Ungültige Schiffsgröße."
	# Fully validate BEFORE writing a single source file.
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PACK_DIR)) != OK:
		return "Speicherordner kann nicht angelegt werden."
	for key in staged.keys():
		if key == "pack.json":
			continue
		var target := PACK_DIR + str(key)
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir())) != OK:
			return "Grafikverzeichnis konnte nicht erstellt werden."
		var file := FileAccess.open(target, FileAccess.WRITE)
		if file == null:
			return "Grafik konnte nicht gespeichert werden."
		file.store_buffer(staged[key])
		file.close()
	# Manifest last: only a fully staged pack becomes active.
	var manifest := FileAccess.open(PACK_DIR + "pack.json", FileAccess.WRITE)
	if manifest == null:
		return "Paketbeschreibung konnte nicht gespeichert werden."
	manifest.store_buffer(staged["pack.json"])
	manifest.close()
	_find_private_art_pack()
	if _private_art_root.is_empty():
		return "Paket konnte nach Import nicht geladen werden."
	_asset_mode = "private_sprite"
	get_tree().root.set_meta("m3035_graphic_mode", "private_sprite")
	_cosmetic_ship_effects = false
	if ship != null:
		_replace_visual(ship, SHIP, 0.9, "PlayerShip", CAPTAIN_ATLAS)
	for i in enemies.size():
		var entry: Dictionary = enemies[i]
		if str(entry.get("kind", "")) != "ship":
			continue
		var actor: Node3D = entry["node"]
		if is_instance_valid(actor):
			_replace_visual(actor, ENEMY, 0.8, "NPC_%d" % i, CORSAIR_ATLAS)
	if _ammo_buttons.size() >= 3:
		var names := ["cannonball", "harpoon", "chain"]
		for i in 3:
			var icon_texture := _private_ui_texture(names[i])
			if icon_texture != null:
				_ammo_buttons[i].icon = icon_texture
				_ammo_buttons[i].expand_icon = true
	_refresh()
	return "%d PNGs importiert. Schiffe/HUD aktiv." % (staged.size() - 1)

func _refresh() -> void:
	super._refresh()
	if _import_hint != null and not _last_import_result.is_empty():
		_import_hint.text = _last_import_result
