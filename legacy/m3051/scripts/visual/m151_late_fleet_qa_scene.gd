class_name M151LateFleetQaScene
extends Node3D

const REGULAR := [53,58,63,68,73,78,83,88,93,98]

func _ready() -> void:
	name = "M151LateFleetSilhouetteQA"
	set_meta("acceptance_basis", "oblique_mobile_map_and_desktop_hero_inspection")
	_build_environment()
	for i in REGULAR.size(): _add_ship("ship_main_%02d" % REGULAR[i], Vector3((i % 5 - 2) * 9.0, 0, (i / 5) * 12.0 - 7.0), 0.72)
	for rank in range(1, 6): _add_ship("prestige_p%d" % rank, Vector3((rank - 3) * 10.0, 0, 18.0), 0.64)

func _build_environment() -> void:
	var world := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("163a4b"); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("9fb8bd"); env.ambient_light_energy = 0.82; env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; world.environment = env; add_child(world)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52,-34,0); sun.light_color = Color("ffe0bb"); sun.light_energy = 1.18; sun.shadow_enabled = true; add_child(sun)
	var camera := Camera3D.new(); camera.position = Vector3(0,52,58); camera.fov = 44; camera.current = true; add_child(camera); camera.look_at(Vector3(0,0,6))
	var floor := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(62,48); floor.mesh = plane; floor.position.y = -0.7; var mat := StandardMaterial3D.new(); mat.albedo_color = Color("07516a"); mat.roughness = 0.28; floor.material_override = mat; add_child(floor)

func _add_ship(id: String, position_value: Vector3, scale_value: float) -> void:
	var holder := Node3D.new(); holder.name = id; holder.position = position_value; holder.rotation_degrees.y = -18; add_child(holder)
	var visual := AssetVisualLibrary.install(holder, id, Vector3.ONE * scale_value)
	var label := Label3D.new(); label.text = id.replace("ship_main_", "CLASS ").replace("prestige_", "PRESTIGE ").to_upper(); label.position = Vector3(0,4.8,0); label.font_size = 28; label.outline_size = 7; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; holder.add_child(label)
	if visual != null: visual.set_meta("m151_qa", true)
