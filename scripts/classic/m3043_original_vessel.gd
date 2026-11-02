extends Node3D
## M304.3 original runtime 3D ship graphics. Built from meshes, not APK art.
## Every vessel uses an intact hull until actual HP crosses a damage threshold.
## Ship coordinates: bow = -Z, starboard = +X. Gameplay collider stays parent.

var profile: String = "brig"
var _rig: Node3D
var _damage_marks: Node3D
var _hull_ratio: float = 1.0
var _motion: float = 0.0
var _sailing: bool = false
var _wave_seed: float = 0.0


func configure(ship_profile: String, visual_scale: float) -> void:
	profile = ship_profile
	_wave_seed = float(abs(ship_profile.hash()) % 51) * 0.13
	var ghost := ship_profile == "ghost"
	var heavy := ship_profile == "frigate"
	var raider := ship_profile == "raider"
	var scout := ship_profile == "sloop"
	var hull_color := Color("364e5d") if heavy else (Color("213f46") if ghost else (Color("574030") if raider else Color("674b36")))
	var trim := Color("d6ad64") if heavy else (Color("89c8b1") if ghost else (Color("bf8662") if raider else Color("d0b17d")))
	var canvas := Color("c9d8c5") if heavy else (Color("a3dcd0") if ghost else (Color("a98973") if raider else Color("e3d8b9")))
	var hull_mat := _mat(hull_color, 0.0, 0.85)
	var trim_mat := _mat(trim, 0.35, 0.44)
	var deck_mat := _mat(Color("a18460") if not ghost else Color("4b7775"), 0.0, 0.88)
	var dark_mat := _mat(Color("18232b"), 0.35, 0.43)
	var sail_mat := _mat(canvas, 0.0, 0.92)
	sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ghost:
		sail_mat.emission_enabled = true
		sail_mat.emission = Color("347f78")
		sail_mat.emission_energy_multiplier = 0.25
	var metal_mat := _mat(Color("6a7780") if heavy else Color("3d4447"), 0.68, 0.3)
	var hull_root := Node3D.new()
	hull_root.name = "ArtHull"
	add_child(hull_root)
	_build_hull(hull_root, hull_mat, deck_mat)
	# A visible keel, two side rails and brass bow detail outline the silhouette.
	_beam(hull_root, Vector3(0.0, -0.64, -4.6), Vector3(0.0, -0.64, 4.0), 0.17, dark_mat)
	for side in [-1.0, 1.0]:
		_beam(hull_root, Vector3(side * 0.30, 1.16, -4.4), Vector3(side * 1.17, 1.2, -3.0), 0.09, trim_mat)
		_beam(hull_root, Vector3(side * 1.17, 1.2, -3.0), Vector3(side * 1.70, 1.2, -0.35), 0.09, trim_mat)
		_beam(hull_root, Vector3(side * 1.70, 1.2, -0.35), Vector3(side * 1.15, 1.2, 3.0), 0.09, trim_mat)
		_beam(hull_root, Vector3(side * 1.15, 1.2, 3.0), Vector3(side * 0.64, 1.2, 4.1), 0.09, trim_mat)
		for i in 4:
			var z := -2.25 + float(i) * 1.38
			var x: float = float(side) * 1.61
			_beam(hull_root, Vector3(x, 0.91, z), Vector3(x, 1.41, z), 0.055, trim_mat)
	var cabin := BoxMesh.new()
	cabin.size = Vector3(2.3 if heavy else 1.95, 0.72, 1.48)
	_mesh(hull_root, cabin, Vector3(0, 1.53, 2.25), deck_mat)
	var cabin_roof := BoxMesh.new()
	cabin_roof.size = Vector3(2.65 if heavy else 2.2, 0.19, 1.8)
	_mesh(hull_root, cabin_roof, Vector3(0, 1.96, 2.25), hull_mat)
	for side in [-1.0, 1.0]:
		var z_positions := [-2.25, -0.8, 0.75, 1.75] if heavy else [-1.95, -0.2, 1.5]
		for z in z_positions:
			var cannon := CylinderMesh.new()
			cannon.top_radius = 0.16 if heavy else 0.13
			cannon.bottom_radius = 0.21 if heavy else 0.17
			cannon.height = 1.05
			var barrel := _mesh(hull_root, cannon, Vector3(side * 1.48, 0.92, z), metal_mat)
			barrel.rotation.z = PI * 0.5
	_rig = Node3D.new()
	_rig.name = "ArtRigging"
	add_child(_rig)
	var masts: Array[float] = [-1.55, 1.05]
	if heavy:
		masts.assign([-2.25, 0.0, 2.2])
	elif scout:
		masts.assign([-0.6])
	for mast_index in masts.size():
		var mast_z: float = masts[mast_index]
		var mast_height := 7.4 if heavy else (6.45 if scout else 6.9)
		_beam(_rig, Vector3(0, 1.2, mast_z), Vector3(0, mast_height, mast_z), 0.16, deck_mat)
		var sail_w := 2.95 if heavy else (2.5 if scout else 2.76)
		var upper := mast_height - 0.9
		var lower := 2.45
		_beam(_rig, Vector3(-sail_w * 0.55, upper, mast_z), Vector3(sail_w * 0.55, upper, mast_z), 0.10, dark_mat)
		_beam(_rig, Vector3(-sail_w * 0.67, lower, mast_z), Vector3(sail_w * 0.67, lower, mast_z), 0.085, dark_mat)
		_add_sail(_rig, mast_z + 0.07, sail_w, lower, upper, sail_mat)
		for side in [-1.0, 1.0]:
			_beam(_rig, Vector3(0, mast_height - 0.1, mast_z), Vector3(side * 1.43, 1.2, mast_z + 1.95), 0.026, dark_mat)
	# Bowsprit: visible forward spar differentiates ships from generic blocks.
	_beam(_rig, Vector3(0, 1.55, -3.1), Vector3(0, 2.4, -6.5 if heavy else -5.9), 0.12, deck_mat)
	var pennant := _mat(trim.lightened(0.16), 0.04, 0.82)
	_add_flag(_rig, masts[0], 7.6 if heavy else (6.65 if scout else 7.12), pennant)
	_damage_marks = Node3D.new()
	_damage_marks.name = "DamageVisuals"
	add_child(_damage_marks)
	for side in [-1.0, 1.0]:
		var mark := SphereMesh.new()
		mark.radius = 0.47
		mark.height = 0.95
		var mark_material := _mat(Color("1b1b1a"), 0.0, 1.0)
		_mesh(_damage_marks, mark, Vector3(side * 1.2, 1.3, 0.8), mark_material)
	_damage_marks.visible = false
	_add_surface_details(hull_root, heavy, ghost, trim, deck_mat, sail_mat)
	scale = Vector3.ONE * visual_scale
	set_hull_ratio(1.0)


func _mat(tint: Color, metal: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.metallic = metal
	m.roughness = rough
	return m


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.position = at
	item.material_override = mat
	parent.add_child(item)
	return item


func _beam(parent: Node3D, from: Vector3, to: Vector3, width: float, mat: Material) -> void:
	var segment := to - from
	if segment.length_squared() < 0.001:
		return
	var body := CylinderMesh.new()
	body.top_radius = width
	body.bottom_radius = width
	body.height = segment.length()
	var part := _mesh(parent, body, (from + to) * 0.5, mat)
	part.quaternion = Quaternion(Vector3.UP, segment.normalized())


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(surface, a, b, c)
	_triangle(surface, a, c, d)


func _build_hull(parent: Node3D, hull_mat: Material, deck_mat: Material) -> void:
	var stations: Array[float] = [-4.75, -3.3, -1.8, 0.15, 1.9, 3.15, 4.1]
	var widths: Array[float] = [0.12, 1.12, 1.65, 1.83, 1.61, 1.17, 0.58]
	var hull_mesh := SurfaceTool.new()
	hull_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var deck_mesh := SurfaceTool.new()
	deck_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in stations.size() - 1:
		var z0 := stations[i]
		var z1 := stations[i+1]
		for side in [-1.0, 1.0]:
			var w0: float = float(side) * widths[i]
			var w1: float = float(side) * widths[i+1]
			_quad(hull_mesh,
				Vector3(w0, 1.15, z0), Vector3(w1, 1.15, z1),
				Vector3(w1 * 0.86, 0.08, z1), Vector3(w0 * 0.86, 0.08, z0))
			_quad(hull_mesh,
				Vector3(w0 * 0.86, 0.08, z0), Vector3(w1 * 0.86, 0.08, z1),
				Vector3(w1 * 0.19, -0.54, z1), Vector3(w0 * 0.19, -0.54, z0))
			_quad(deck_mesh,
				Vector3(0.0, 1.1, z0), Vector3(w0, 1.1, z0),
				Vector3(w1, 1.1, z1), Vector3(0.0, 1.1, z1))
	hull_mesh.generate_normals()
	deck_mesh.generate_normals()
	_mesh(parent, hull_mesh.commit(), Vector3.ZERO, hull_mat)
	_mesh(parent, deck_mesh.commit(), Vector3.ZERO, deck_mat)


func _add_sail(parent: Node3D, mast_z: float, span: float, low: float, high: float, mat: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left_low := Vector3(-span * 0.55, low, mast_z + 0.17)
	var right_low := Vector3(span * 0.55, low, mast_z + 0.17)
	var left_high := Vector3(-span * 0.42, high, mast_z)
	var right_high := Vector3(span * 0.42, high, mast_z)
	var fold := Vector3(0, (low + high) * 0.5, mast_z + 0.5)
	_triangle(surface, left_low, fold, left_high)
	_triangle(surface, left_high, fold, right_high)
	_triangle(surface, right_high, fold, right_low)
	_triangle(surface, right_low, fold, left_low)
	surface.generate_normals()
	_mesh(parent, surface.commit(), Vector3.ZERO, mat)


func _add_flag(parent: Node3D, mast_z: float, height: float, mat: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_triangle(surface, Vector3(0, height, mast_z), Vector3(1.3, height - 0.32, mast_z + 0.16),
		Vector3(0, height - 0.65, mast_z))
	surface.generate_normals()
	_mesh(parent, surface.commit(), Vector3.ZERO, mat)


func set_hull_ratio(ratio: float) -> void:
	_hull_ratio = clampf(ratio, 0.0, 1.0)
	if _damage_marks != null:
		_damage_marks.visible = _hull_ratio <= 0.32


func set_moving(moving: bool) -> void:
	_sailing = moving


func _process(delta: float) -> void:
	_motion += delta
	if _rig == null:
		return
	var intensity := 1.0 if _sailing else 0.46
	# Local visual heave only. The parent ship remains at the gameplay position.
	position.y = sin(_motion * 1.2 + _wave_seed) * 0.09 * intensity
	rotation.z = sin(_motion * 0.94 + _wave_seed) * 0.021 * intensity
	rotation.x = sin(_motion * 1.18 + _wave_seed * 0.6) * 0.025 * intensity


func _add_surface_details(hull_root: Node3D, heavy: bool, ghost: bool, trim: Color, deck_material: Material, sail_material: Material) -> void:
	# Lightweight first-party timber lines, hull bands and brass cabin windows.
	# These are true 3D meshes, not randomized atlas damage-state images.
	var details := Node3D.new()
	details.name = "OriginalShipSurfaceDetails"
	hull_root.add_child(details)
	var grain := _mat(Color("ab855d") if not ghost else Color("638c87"), 0.0, 0.91)
	var band := _mat(trim.darkened(0.19), 0.34, 0.48)
	var window := _mat(Color("f1d5a3") if not ghost else Color("85ead0"), 0.22, 0.33)
	if ghost:
		window.emission_enabled = true
		window.emission = Color("3e9d8a")
		window.emission_energy_multiplier = 0.35
	for i in 7:
		var z: float = -3.13 + float(i) * 0.98
		var width: float = 2.65 if heavy else 2.35
		var plank := BoxMesh.new()
		plank.size = Vector3(width, 0.025, 0.047)
		_mesh(details, plank, Vector3(0, 1.175, z), grain)
	for side in [-1.0, 1.0]:
		_beam(details, Vector3(side * 1.27, 0.50, -2.7),
			Vector3(side * 1.52, 0.50, 2.25), 0.045, band)
		_beam(details, Vector3(side * 1.42, 0.81, -2.45),
			Vector3(side * 1.45, 0.81, 2.24), 0.038, band)
		for index in 3:
			var port := BoxMesh.new()
			port.size = Vector3(0.045, 0.22, 0.28)
			_mesh(details, port,
				Vector3(side * (1.2 if heavy else 1.13), 1.64, 1.78 + float(index) * 0.28), window)
	# Shallow surface seams define the stern silhouette at close mobile zoom.
	for index in 3:
		var grain_line := BoxMesh.new()
		grain_line.size = Vector3(0.045, 0.025, 0.92)
		_mesh(details, grain_line, Vector3(-0.9 + float(index) * 0.9, 1.177, 1.8), grain)
