class_name M183CommandDeckCatalog
extends Node
## Data-driven destination copy and mobile command-deck policy.

const PATH := "res://data/m183_unified_command_deck.json"
var data: Dictionary = {}

func _ready() -> void:
	add_to_group("m183_command_deck_catalog")
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null: return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary: data = parsed

func context(id: String) -> String:
	for section in data.get("sections", []):
		for destination in section.get("destinations", []):
			if str(destination.get("id", "")) == id:
				return str(destination.get("context", ""))
	return ""

func destination_ids() -> Array[String]:
	var result: Array[String] = []
	for section in data.get("sections", []):
		for destination in section.get("destinations", []):
			var id := str(destination.get("id", ""))
			if not id.is_empty() and id not in result: result.append(id)
	return result

