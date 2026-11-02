extends Node
func _ready()->void:
	var d:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m119_ancient_equipment.json"));assert(d.items.size()==4)
	var p:=WorldBossPrep.new();p.guardian_mechanic_seen=true;p.titan_mechanic_seen=true;p.guardian_clear=true;p.titan_clear=true;p.ancient_admiral_clear=true;p.relic_core_ready=true;assert(p.ready())
	print("M119_PASS")
