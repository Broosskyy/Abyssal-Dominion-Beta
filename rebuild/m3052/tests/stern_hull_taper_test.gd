extends SceneTree
const TAPER = preload("res://stern_hull_taper.gd")
const FILES = ["base_basic_gameplay_pbr.glb", "base_basic_gameplay_shaded.glb"]
var failures: Array[String] = []
var checks: int = 0

func check(ok: bool, name: String) -> void:
	checks += 1
	if not ok:
		failures.append(name)

func _initialize() -> void:
	var stern := Vector3(0.60, 0.20, -0.92)
	var modified: Vector3 = TAPER.tapered_point(stern)
	check(absf(modified.x - stern.x * 0.86) < 0.00001, "stern narrows by 14 percent")
	check(is_equal_approx(modified.y, stern.y) and is_equal_approx(modified.z, stern.z), "keel height and hull length unchanged")
	check(TAPER.tapered_point(Vector3(0.60, 0.20, 0.40)).is_equal_approx(Vector3(0.60, 0.20, 0.40)), "bow stays untouched")
	check(TAPER.tapered_point(Vector3(0.40, 1.0, -0.92)).is_equal_approx(Vector3(0.40, 1.0, -0.92)), "sails and upper rigging stay untouched")
	check(TAPER.beam_scale(Vector3(0.2, 0.2, -0.40)) > 0.86, "stern blends gradually into midships")
	for filename in FILES:
		var packed: PackedScene = load("res://assets/player/test_ships/" + filename)
		check(packed != null, filename + " loads")
		if packed == null:
			continue
		var model: Node3D = packed.instantiate() as Node3D
		check(model != null, filename + " instantiates")
		if model == null:
			continue
		get_root().add_child(model)
		var original_meshes: Array[Mesh] = []
		var original_positions: Array = []
		var pieces: Array[MeshInstance3D] = []
		var pending: Array[Node] = [model]
		while not pending.is_empty():
			var item: Node = pending.pop_back()
			for child: Node in item.get_children():
				pending.append(child)
			if item is MeshInstance3D and (item as MeshInstance3D).mesh != null:
				var piece: MeshInstance3D = item as MeshInstance3D
				pieces.append(piece)
				original_meshes.append(piece.mesh)
				original_positions.append(piece.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		var transformed: int = TAPER.apply_to_scene(model)
		check(transformed == pieces.size() and transformed > 0, filename + " transforms all live mesh pieces")
		var moved_vertices: int = 0
		for i in range(pieces.size()):
			var source: Mesh = original_meshes[i]
			var output: Mesh = pieces[i].mesh
			check(output != source and output.get_surface_count() == source.get_surface_count(), filename + " copies geometry rather than rewriting shared GLB")
			for surface in range(source.get_surface_count()):
				check(output.surface_get_material(surface) == source.surface_get_material(surface), filename + " retains materials and textures")
			var old_verts: PackedVector3Array = original_positions[i]
			var new_verts: PackedVector3Array = output.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			check(old_verts.size() == new_verts.size(), filename + " keeps vertex topology")
			for j in range(old_verts.size()):
				if old_verts[j].distance_to(new_verts[j]) > 0.00001:
					moved_vertices += 1
		check(moved_vertices > 0, filename + " actually narrows the stern")
		model.free()
	var outcome := {"status": "PASS" if failures.is_empty() else "FAIL", "checks": checks, "failures": failures}
	print(JSON.stringify(outcome))
	quit(0 if failures.is_empty() else 1)
