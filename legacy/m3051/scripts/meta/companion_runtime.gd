class_name CompanionRuntime
extends Node3D

var player: Node3D
var equipped_id := "COMPANION-COMPASS-GULL"
var visual_holder: Node3D
var follow_offset := Vector3(-2.8,0.35,2.4)

func _ready() -> void:
	add_to_group("companion_runtime"); set_meta("authority","LOCAL_PREVIEW_ONLY"); _rebuild_visual()

func configure(player_node: Node3D) -> void:
	player = player_node

func equip(id: String) -> Dictionary:
	if CompanionCatalog.by_id(id).is_empty(): return {"ok":false,"error":"unknown_companion"}
	equipped_id = id; _rebuild_visual(); return {"ok":true,"id":id,"authority":"LOCAL_PREVIEW_ONLY"}

func cycle() -> Dictionary:
	var rows := CompanionCatalog.all(); var index := 0
	for i in rows.size():
		if str(rows[i].get("id", "")) == equipped_id: index = i; break
	return equip(str(rows[(index+1)%rows.size()].get("id", "")))

func _process(delta: float) -> void:
	if player == null: return
	var target := player.global_position + player.global_transform.basis * follow_offset
	global_position = global_position.lerp(target,clampf(delta*4.5,0.0,1.0)); rotation.y = lerp_angle(rotation.y,player.rotation.y,clampf(delta*3.0,0.0,1.0))
	if visual_holder != null: visual_holder.position.y = 0.16 + sin(Time.get_ticks_msec()*0.0025)*0.10

func _rebuild_visual() -> void:
	if visual_holder != null: visual_holder.queue_free()
	visual_holder = Node3D.new(); visual_holder.name = "CompanionVisual"; add_child(visual_holder)
	var definition := CompanionCatalog.by_id(equipped_id); if definition.is_empty(): return
	var assets := definition.get("assets", {}) as Dictionary; var model_slot := str(assets.get("model", ""))
	var visual := AssetVisualLibrary.install(visual_holder,model_slot,Vector3.ONE*0.82)
	if visual == null:
		var fallback := CompanionVisualFactory.create(definition); fallback.set_meta("classification","M152_COMPANION_PROCEDURAL_FALLBACK"); visual_holder.add_child(fallback)
	visual_holder.set_meta("companion_id",equipped_id); visual_holder.set_meta("model_slot",model_slot); visual_holder.set_meta("gameplay_authority",false)
