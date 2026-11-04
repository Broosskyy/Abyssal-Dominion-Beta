class_name M215LootCollectionFx
extends Node3D

func _ready() -> void:
	var ring := MeshInstance3D.new()
	ring.name = "M215LootCollectionRing"
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.55
	mesh.outer_radius = 0.68
	mesh.rings = 18
	mesh.ring_segments = 5
	ring.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.78, 0.34, 0.72)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.70, 0.25)
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.set_meta("visual_only", true)
	add_child(ring)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * 3.2, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "position:y", 0.42, 0.32)
	tween.tween_property(mat, "albedo_color", Color(0.95, 0.78, 0.34, 0.0), 0.32)
	tween.chain().tween_callback(queue_free)
