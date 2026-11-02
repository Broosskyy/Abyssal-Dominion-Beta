extends Node
func _ready()->void:
	var c:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m83_hud_layout_customization.json"))
	assert(c.editable_groups.size()>=9)
	assert(c.rules.size()>=6)
	var safe:=Rect2(Vector2.ZERO,Vector2(1000,600))
	var store:=HudLayoutStore.new()
	store.memory_only=true
	add_child(store)
	store.set_offset("mobile_landscape","combat",Vector2(100,60),safe)
	var v:=store.offset("mobile_landscape","combat",safe)
	assert(v.distance_to(Vector2(100,60))<0.5)
	store.reset_profile("mobile_landscape")
	assert(store.offset("mobile_landscape","combat",safe)==Vector2.ZERO)
	print("M83_HUD_LAYOUT_PASS")
