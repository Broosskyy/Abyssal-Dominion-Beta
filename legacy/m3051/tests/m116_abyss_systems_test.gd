extends Node
func _ready()->void:
	var h:=SupportPayloadCatalog.harpoon_payloads();var ids:Array=[]
	for row in h:ids.append(row.id)
	assert(ids.has("abyssal_spike"));assert(ids.has("rift_piercer"));assert(ids.has("leviathan_chain"))
	var c:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m115_corruption.json"));assert(c.opt_in)
	var a:=AbyssBonusMapProgress.new();assert(a.KILLS.size()==6)
	var eq:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m116_abyss_equipment.json"));assert(eq.advanced_castle_hooks.size()==3)
	print("M116_ABYSS_SYSTEMS_PASS")
