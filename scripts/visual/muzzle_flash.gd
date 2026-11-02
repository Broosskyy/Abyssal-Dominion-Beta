class_name MuzzleFlash
extends Node3D


func _ready() -> void:
	name = "M216BroadsideMuzzleFlash"
	set_meta("visual_only", true)
	var settings := ClientSettings.current(get_tree())
	if settings != null and settings.values.reduced_flashes:
		queue_free()
		return
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.36
	sphere.height = 0.72
	flash.mesh = sphere
	var flash_material := StandardMaterial3D.new()
	flash_material.albedo_color = Color("ffe1a0")
	flash_material.emission_enabled = true
	flash_material.emission = Color("ff7f22")
	flash_material.emission_energy_multiplier = 4.8
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.material_override = flash_material
	add_child(flash)

	var smoke := MeshInstance3D.new()
	var smoke_mesh := SphereMesh.new()
	smoke_mesh.radius = 0.34
	smoke_mesh.height = 0.54
	smoke.mesh = smoke_mesh
	smoke.position = Vector3(0.0, 0.16, 0.22)
	var smoke_material := StandardMaterial3D.new()
	smoke_material.albedo_color = Color(0.20, 0.19, 0.18, 0.44)
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.material_override = smoke_material
	add_child(smoke)

	var blast := MeshInstance3D.new()
	blast.name = "M216MuzzleBlastCone"
	var blast_mesh := CylinderMesh.new()
	blast_mesh.top_radius = 0.06
	blast_mesh.bottom_radius = 0.30
	blast_mesh.height = 0.78
	blast.mesh = blast_mesh
	blast.rotation_degrees.x = 90.0
	blast.position = Vector3(0.0, 0.02, 0.42)
	var blast_material := StandardMaterial3D.new()
	blast_material.albedo_color = Color(1.0, 0.76, 0.32, 0.88)
	blast_material.emission_enabled = true
	blast_material.emission = Color("ff8c2f")
	blast_material.emission_energy_multiplier = 3.5
	blast_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blast.material_override = blast_material
	add_child(blast)

	var light := OmniLight3D.new()
	light.light_color = Color("ff9a38")
	light.light_energy = 4.0
	light.omni_range = 5.4
	light.shadow_enabled = false
	add_child(light)

	scale = Vector3.ONE * 0.20
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ONE * 1.52, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(smoke, "position:y", 0.72, 0.30)
	tween.tween_property(smoke, "scale", Vector3.ONE * 1.85, 0.30)
	tween.tween_property(smoke_material, "albedo_color", Color(smoke_material.albedo_color.r, smoke_material.albedo_color.g, smoke_material.albedo_color.b, 0.0), 0.30)
	tween.tween_property(light, "light_energy", 0.0, 0.16)
	tween.tween_property(blast, "scale", Vector3(0.55, 1.8, 0.55), 0.16)
	tween.tween_property(blast_material, "albedo_color", Color(1.0, 0.76, 0.32, 0.0), 0.16)
	tween.chain().tween_callback(queue_free)
