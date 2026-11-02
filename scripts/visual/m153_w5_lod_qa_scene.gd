class_name M153W5LodQaScene
extends Node3D

func _ready() -> void:
	name = "M153W5LodQA"
	set_meta("acceptance_basis", "desktop_hero_lod0_and_mobile_map_lod2")
	_build_environment()
	for index in range(10):
		var id := "ship_main_%02d" % (51 + index)
		_add_ship(id, 0, Vector3((index % 5 - 2) * 9.0, 0, -10.0 + (index / 5) * 11.0))
		_add_ship(id, 2, Vector3((index % 5 - 2) * 9.0, 0, 15.0 + (index / 5) * 11.0))

func _build_environment() -> void:
	var world := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("122f3d"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("a9bbc0"); env.ambient_light_energy = 0.92; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; world.environment = env; add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-54,-32,0); sun.light_color = Color("ffe4bd"); sun.light_energy = 1.24; sun.shadow_enabled = true; add_child(sun)
	var camera := Camera3D.new(); camera.position = Vector3(0,66,70); camera.fov = 44; camera.current = true; add_child(camera); camera.look_at(Vector3(0,0,8))
	var sea := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(62,62); sea.mesh = plane; sea.position.y = -0.75; var material := StandardMaterial3D.new(); material.albedo_color = Color("07546b"); material.roughness = 0.24; sea.material_override = material; add_child(sea)

func _add_ship(id: String, lod: int, position_value: Vector3) -> void:
	var row := W5ProductionBatch.entry(id); var path := str(row.get("lod%d_path" % lod, "")); var packed := load(path) as PackedScene
	if packed == null: return
	var holder := Node3D.new(); holder.name = "%s_LOD%d" % [id,lod]; holder.position = position_value; holder.rotation_degrees.y = -20; holder.scale = Vector3.ONE * (0.70 if lod == 0 else 0.76); add_child(holder)
	var model := packed.instantiate() as Node3D; holder.add_child(model)
	var label := Label3D.new(); label.text = "%s · LOD%d" % [id.replace("ship_main_", "CLASS "),lod]; label.position = Vector3(0,5.0,0); label.font_size = 26; label.outline_size = 7; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; holder.add_child(label)
