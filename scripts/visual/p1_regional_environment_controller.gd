class_name P1RegionalEnvironmentController
extends Node

var active_region := ""

func _ready() -> void:
	add_to_group("p1_regional_environment_controller")

func apply_region(region_id: String) -> void:
	var profile := P1RegionalVisualAcceptanceCatalog.region(region_id)
	if profile.is_empty(): profile = P1RegionalVisualAcceptanceCatalog.default_profile()
	active_region = region_id
	var world := get_tree().get_first_node_in_group("regional_world_environment") as WorldEnvironment
	if world != null and world.environment != null:
		var env := world.environment
		env.background_color = Color(str(profile.get("background", "4d91ae")))
		env.ambient_light_color = Color(str(profile.get("ambient", "91a6ad")))
		env.ambient_light_energy = float(profile.get("ambient_energy", 0.85))
		var density := float(profile.get("fog_density", 0.0))
		env.fog_enabled = density > 0.0
		env.fog_light_color = Color(str(profile.get("fog_color", "91a6ad")))
		env.fog_density = density
	var sun := get_tree().get_first_node_in_group("quality_directional_lights") as DirectionalLight3D
	if sun != null:
		sun.light_color = Color(str(profile.get("sun_color", "ffe8c2")))
		sun.light_energy = float(profile.get("sun_energy", 1.25))
	var water := profile.get("water", {}) as Dictionary
	for surface in get_tree().get_nodes_in_group("regional_water_surface"):
		if surface.has_method("apply_region_profile"): surface.apply_region_profile(water)
	get_tree().root.set_meta("m150_active_visual_region", region_id)
