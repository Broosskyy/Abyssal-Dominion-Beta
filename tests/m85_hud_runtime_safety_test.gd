extends Node
func _ready()->void:
	var c:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m85_hud_runtime_safety.json"))
	assert(c.features.size()>=6)
	var store:=HudLayoutStore.new()
	store.memory_only=true
	add_child(store)
	var safe:=Rect2(Vector2.ZERO,Vector2(960,540))
	store.set_offset("mobile_landscape","combat",Vector2(120,40),safe)
	store.toggle_lock("mobile_landscape","combat")
	var locked_before:=store.offset("mobile_landscape","combat",safe)
	store.set_offset("mobile_landscape","combat",Vector2(300,200),safe)
	assert(store.offset("mobile_landscape","combat",safe).distance_to(locked_before)<0.5)
	store.toggle_lock("mobile_landscape","combat")
	store.set_scale("mobile_landscape","combat",1.2)
	assert(abs(float(store.row("mobile_landscape","combat").scale)-1.2)<0.001)
	store.reset_all()
	assert(store.layouts.is_empty())
	print("M85_HUD_RUNTIME_SAFETY_PASS")
