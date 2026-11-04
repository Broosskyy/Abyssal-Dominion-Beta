class_name WaterSplash
extends Node3D


func _ready() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.28
	ring.mesh = torus
	ring.rotation_degrees.x = 0.0
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.78, 0.95, 0.98, 0.66)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.45, 0.83, 0.92)
	ring_material.emission_energy_multiplier = 0.92
	ring.material_override = ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.name = "M215WaterImpactRing"
	ring.set_meta("visual_only", true)
	add_child(ring)

	var plume := MeshInstance3D.new()
	var plume_mesh := CylinderMesh.new()
	plume_mesh.top_radius = 0.06
	plume_mesh.bottom_radius = 0.26
	# M215 parity lock: the same visible splash silhouette is used on mobile/web/desktop.
	plume_mesh.height = 0.88
	plume.mesh = plume_mesh
	plume.position.y = 0.35
	plume.material_override = ring_material.duplicate()
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plume)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * 3.6, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(plume, "position:y", 1.05, 0.30)
	tween.tween_property(plume, "scale", Vector3(0.45, 1.7, 0.45), 0.28)
	tween.tween_property(ring_material, "albedo_color", Color(ring_material.albedo_color.r, ring_material.albedo_color.g, ring_material.albedo_color.b, 0.0), 0.34)
	tween.chain().tween_callback(queue_free)
