extends RefCounted
## Non-destructive M3096 stern correction for the two M3092 gameplay GLBs.
## The bow points toward +Z. Source GLBs are retained without modification.
const STERN_NARROWING := 0.14
const TAPER_START_Z := -0.80
const TAPER_END_Z := 0.22
const HULL_FULL_HEIGHT := 0.44
const HULL_FADE_HEIGHT := 0.70
const GRADIENT_STEP := 0.002

static func beam_scale(point: Vector3) -> float:
	var aft: float = 1.0 - smoothstep(TAPER_START_Z, TAPER_END_Z, point.z)
	var hull: float = 1.0 - smoothstep(HULL_FULL_HEIGHT, HULL_FADE_HEIGHT, point.y)
	return 1.0 - STERN_NARROWING * aft * hull

static func tapered_point(point: Vector3) -> Vector3:
	return Vector3(point.x * beam_scale(point), point.y, point.z)

static func _derivatives(point: Vector3) -> Vector2:
	var step: float = GRADIENT_STEP
	var dy: float = (beam_scale(point + Vector3(0, step, 0)) - beam_scale(point - Vector3(0, step, 0))) / (2.0 * step)
	var dz: float = (beam_scale(point + Vector3(0, 0, step)) - beam_scale(point - Vector3(0, 0, step))) / (2.0 * step)
	return Vector2(dy, dz)

static func _taper_normal(normal: Vector3, point: Vector3, scale_x: float, gradients: Vector2) -> Vector3:
	# Inverse transpose of the local deformation Jacobian.
	var nx: float = normal.x / scale_x
	return Vector3(nx, normal.y - point.x * gradients.x * nx, normal.z - point.x * gradients.y * nx).normalized()

static func _taper_tangent(tangent: Vector3, point: Vector3, scale_x: float, gradients: Vector2) -> Vector3:
	return Vector3(scale_x * tangent.x + point.x * (gradients.x * tangent.y + gradients.y * tangent.z), tangent.y, tangent.z)

static func apply_to_scene(model: Node3D) -> int:
	var changed: int = 0
	var remaining: Array[Node] = [model]
	while not remaining.is_empty():
		var current: Node = remaining.pop_back()
		for child: Node in current.get_children():
			remaining.append(child)
		if not current is MeshInstance3D:
			continue
		var piece: MeshInstance3D = current as MeshInstance3D
		var source: Mesh = piece.mesh
		if source == null:
			continue
		var adjusted := ArrayMesh.new()
		adjusted.resource_name = source.resource_name + "_narrow_stern"
		var into_model: Transform3D = model.global_transform.affine_inverse() * piece.global_transform
		var out_of_model: Transform3D = into_model.affine_inverse()
		for surface in range(source.get_surface_count()):
			var arrays: Array = source.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var has_normals: bool = arrays[Mesh.ARRAY_NORMAL] != null
			var has_tangents: bool = arrays[Mesh.ARRAY_TANGENT] != null
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if has_normals else PackedVector3Array()
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT] if has_tangents else PackedFloat32Array()
			for i in range(positions.size()):
				var original_point: Vector3 = into_model * positions[i]
				var scale_x: float = beam_scale(original_point)
				if is_equal_approx(scale_x, 1.0):
					continue
				var gradients: Vector2 = _derivatives(original_point)
				if has_normals:
					var model_normal: Vector3 = (into_model.basis.inverse().transposed() * normals[i]).normalized()
					var new_model_normal: Vector3 = _taper_normal(model_normal, original_point, scale_x, gradients)
					normals[i] = (into_model.basis.transposed() * new_model_normal).normalized()
				if has_tangents:
					var offset: int = i * 4
					var model_tangent: Vector3 = into_model.basis * Vector3(tangents[offset], tangents[offset + 1], tangents[offset + 2])
					var new_tangent: Vector3 = (out_of_model.basis * _taper_tangent(model_tangent, original_point, scale_x, gradients)).normalized()
					if has_normals:
						new_tangent = (new_tangent - normals[i] * normals[i].dot(new_tangent)).normalized()
					tangents[offset] = new_tangent.x
					tangents[offset + 1] = new_tangent.y
					tangents[offset + 2] = new_tangent.z
				positions[i] = out_of_model * tapered_point(original_point)
			arrays[Mesh.ARRAY_VERTEX] = positions
			if has_normals:
				arrays[Mesh.ARRAY_NORMAL] = normals
			if has_tangents:
				arrays[Mesh.ARRAY_TANGENT] = tangents
			adjusted.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays, [], {})
			adjusted.surface_set_material(surface, source.surface_get_material(surface))
		piece.mesh = adjusted
		changed += 1
	return changed
