class_name ImpactFx
extends Node3D


func _ready() -> void:
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.23
	sphere.height = 0.46
	core.mesh = sphere
	var core_material := StandardMaterial3D.new()
	core_material.albedo_color = Color("ffd27a")
	core_material.emission_enabled = true
	core_material.emission = Color("ff5d1e")
	core_material.emission_energy_multiplier = 3.8
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.material_override = core_material
	add_child(core)

	var spark_material := StandardMaterial3D.new()
	spark_material.albedo_color = Color("ffbc65")
	spark_material.emission_enabled = true
	spark_material.emission = Color("ff7b2c")
	spark_material.emission_energy_multiplier = 2.8
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in 4:
		var spark := MeshInstance3D.new()
		var spark_mesh := BoxMesh.new()
		spark_mesh.size = Vector3(0.05, 0.05, 0.42)
		spark.mesh = spark_mesh
		spark.material_override = spark_material
		spark.rotation_degrees.y = index * 90.0 + 45.0
		spark.position.y = 0.12
		add_child(spark)
		var direction := Vector3(sin(index * PI * 0.5 + 0.7), 0.55, cos(index * PI * 0.5 + 0.7))
		create_tween().tween_property(spark, "position", direction * 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var smoke := MeshInstance3D.new()
	var smoke_sphere := SphereMesh.new()
	smoke_sphere.radius = 0.38
	smoke_sphere.height = 0.76
	smoke.mesh = smoke_sphere
	var smoke_material := StandardMaterial3D.new()
	smoke_material.albedo_color = Color(0.16, 0.15, 0.14, 0.58)
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.material_override = smoke_material
	smoke.position.y = 0.25
	add_child(smoke)

	var ring := MeshInstance3D.new()
	ring.name = "M200ImpactRing" # retained M200 regression token
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.30
	ring_mesh.outer_radius = 0.38
	ring.mesh = ring_mesh
	ring.position.y = -0.05
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(1.0, 0.63, 0.22, 0.72)
	ring_material.emission_enabled = true
	ring_material.emission = Color("ff7b2c")
	ring_material.emission_energy_multiplier = 2.5
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.set_meta("visual_only", true)
	add_child(ring)

	var water_shock := MeshInstance3D.new()
	water_shock.name = "M215ImpactWaterShock"
	var shock_mesh := TorusMesh.new()
	shock_mesh.inner_radius = 0.52
	shock_mesh.outer_radius = 0.60
	shock_mesh.rings = 20
	shock_mesh.ring_segments = 5
	water_shock.mesh = shock_mesh
	water_shock.position.y = -0.09
	var shock_material := StandardMaterial3D.new()
	shock_material.albedo_color = Color(0.74, 0.94, 0.98, 0.52)
	shock_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shock_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water_shock.material_override = shock_material
	water_shock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_shock.set_meta("visual_only", true)
	add_child(water_shock)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(core, "scale", Vector3.ONE * 2.0, 0.15)
	tween.tween_property(ring, "scale", Vector3.ONE * 3.1, 0.30)
	tween.tween_property(ring_material, "albedo_color", Color(1.0, 0.63, 0.22, 0.0), 0.30)
	tween.tween_property(water_shock, "scale", Vector3.ONE * 4.2, 0.36)
	tween.tween_property(shock_material, "albedo_color", Color(0.74, 0.94, 0.98, 0.0), 0.36)
	tween.tween_property(smoke, "position:y", 1.2, 0.44)
	tween.tween_property(smoke, "scale", Vector3.ONE * 2.35, 0.44)
	tween.tween_property(smoke_material, "albedo_color", Color(smoke_material.albedo_color.r, smoke_material.albedo_color.g, smoke_material.albedo_color.b, 0.0), 0.44)
	tween.chain().tween_callback(queue_free)
