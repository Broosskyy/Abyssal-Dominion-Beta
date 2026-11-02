class_name M184PanelRoutingCatalog
extends Node
## Data-driven contracts for full-screen panel ownership and return destinations.

const PATH := "res://data/m184_panel_routing.json"
var data: Dictionary = {}

func _ready() -> void:
	add_to_group("m184_panel_routing_catalog")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary: data = parsed

func return_page(panel_id: String, fallback := "home") -> String:
	for route in data.get("routes", []):
		if str(route.get("panel", "")) == panel_id:
			return str(route.get("default_return", fallback))
	return fallback

func route_ids() -> Array[String]:
	var result: Array[String] = []
	for route in data.get("routes", []): result.append(str(route.get("panel", "")))
	return result

