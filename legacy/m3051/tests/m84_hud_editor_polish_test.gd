extends Node
func _ready()->void:
	var d:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m84_hud_editor_polish.json"))
	assert(d.presets.size()==3)
	assert(float(d.scale_range[0])==0.80)
	assert(float(d.scale_range[1])==1.35)
	var store:=HudLayoutStore.new()
	store.memory_only=true
	add_child(store)
	var safe:=Rect2(Vector2.ZERO,Vector2(1200,700))
	store.set_offset("desktop_wide","combat",Vector2(120,70),safe)
	store.set_scale("desktop_wide","combat",1.20)
	assert(abs(float(store.row("desktop_wide","combat").scale)-1.20)<0.001)
	store.apply_preset("desktop_wide","minimal")
	assert(not bool(store.row("desktop_wide","mission").visible))
	assert(bool(store.row("desktop_wide","combat").visible))
	print("M84_HUD_EDITOR_POLISH_PASS")
