extends Node
func _ready()->void:
	assert(WorldMapSystem.GRID_SIZE==Vector2i(5,5))
	assert(int(WorldMapSystem.SECTORS[Vector2i(4,3)].level)==16)
	assert(int(WorldMapSystem.SECTORS[Vector2i(4,4)].level)==17)
	assert(int(WorldMapSystem.SECTORS[Vector2i(3,4)].level)==18)
	assert(int(WorldMapSystem.SECTORS[Vector2i(2,4)].level)==19)
	assert(int(WorldMapSystem.SECTORS[Vector2i(1,4)].level)==20)
	var regions:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m112_regions_pl6_20.json"))
	assert(regions.regions.size()==4)
	var inv:=PlayerInventory.new()
	assert(not inv.grant_silver_bonusmap_fragment(11))
	assert(inv.grant_silver_bonusmap_fragment(12))
	print("M112_PHYSICAL_WORLD_PASS")
