class_name IslandCompositionCatalog
extends RefCounted
const PATH := "res://data/m71_island_composition_profiles.json"
static var _data: Dictionary = {}

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"profiles":{}}
	return _data

static func profile(id: String) -> Dictionary:
	return (data().get("profiles",{}) as Dictionary).get(id,{})

static func apply_meta(island: Node3D, id: String) -> void:
	var p:=profile(id)
	if p.is_empty(): return
	var aspect:Array=p.get("aspect",[1.0,1.0])
	island.set_meta("m71_composition_profile",id)
	island.set_meta("production_slot",str(p.get("slot","")))
	island.set_meta("island_aspect",Vector2(float(aspect[0]),float(aspect[1])))
	island.set_meta("island_prop_density",float(p.get("prop_density",1.0)))
