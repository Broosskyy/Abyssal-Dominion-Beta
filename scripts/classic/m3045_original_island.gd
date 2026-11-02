extends Node3D
## First-party, deterministic low-poly island meshes. No referenced game artwork.
## Waterline Y=0, footprint remains inside the legacy route-blocking radius.

var biome := "tropical"
var island_radius := 10.0
var _clock := 0.0
var _beacon: MeshInstance3D


func configure(kind: String, radius: float, slot: int) -> void:
	biome = kind
	island_radius = radius
	var random := RandomNumberGenerator.new()
	random.seed = 7151 + slot * 537
	var cliff_tint := Color("545964")
	var soil_tint := Color("a4ad8c")
	var vegetation := Color("40775b")
	match biome:
		"snow":
			cliff_tint = Color("70808b")
			soil_tint = Color("d7e6e8")
			vegetation = Color("477780")
		"rock":
			cliff_tint = Color("6b6d72")
			soil_tint = Color("8d8f7e")
			vegetation = Color("587562")
		"fort":
			cliff_tint = Color("626a70")
			soil_tint = Color("aeaa83")
			vegetation = Color("657b5a")
		"volcanic":
			cliff_tint = Color("453e48")
			soil_tint = Color("605755")
			vegetation = Color("744f40")
	var cliffs := Node3D.new()
	cliffs.name = "OriginalCliffs"
	add_child(cliffs)
	var earth := Node3D.new()
	earth.name = "OriginalTerrain"
	add_child(earth)
	var details := Node3D.new()
	details.name = "OriginalIslandDetails"
	add_child(details)
	var base := CylinderMesh.new()
	base.top_radius = radius * 0.66
	base.bottom_radius = radius * 0.87
	base.height = 3.2
	base.radial_segments = 12
	_mesh(cliffs, base, Vector3(0.0, 0.40, 0.0), _mat(cliff_tint, 0.96))
	var plateau := CylinderMesh.new()
	plateau.top_radius = radius * 0.64
	plateau.bottom_radius = radius * 0.69
	plateau.height = 0.32
	plateau.radial_segments = 14
	_mesh(earth, plateau, Vector3(0.0, 2.14, 0.0), _mat(soil_tint, 0.91))
	# Coastal rock clusters and vegetation read as a volume, not one flat decal.
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var distance := radius * random.randf_range(0.44, 0.71)
		var rock := SphereMesh.new()
		rock.radius = random.randf_range(0.53, 1.28)
		rock.height = random.randf_range(0.95, 1.8)
		var boulder := _mesh(details, rock,
			Vector3(cos(angle) * distance, random.randf_range(0.6, 1.5), sin(angle) * distance),
			_mat(cliff_tint.lightened(random.randf_range(-0.13, 0.18)), 0.96))
		boulder.rotation.y = random.randf_range(0.0, TAU)
	var count := 4 if biome == "rock" or biome == "volcanic" else 7
	for i in count:
		var angle := TAU * (float(i) / float(count) + 0.11)
		var distance := radius * random.randf_range(0.21, 0.46)
		var at := Vector3(cos(angle) * distance, 2.28, sin(angle) * distance)
		if biome == "tropical":
			_palm(details, at, 2.4 + random.randf_range(-0.4, 0.9), vegetation)
		else:
			_pine(details, at, random.randf_range(2.8, 4.2), vegetation,
				biome == "snow")
	if biome == "fort":
		_fortress(details, radius)
	elif biome == "volcanic":
		_volcano(details)
	if slot % 3 == 0:
		_dock(details, radius)
	if slot == 3 or biome == "fort":
		_lighthouse(details, radius)
	# Terrain is deliberately visual-only; gameplay continues using island_radius.
	set_process(true)


func _mat(color: Color, rough: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	return material


func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.material_override = material
	parent.add_child(part)
	return part


func _box(parent: Node3D, dimensions: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return _mesh(parent, shape, at, material)


func _palm(parent: Node3D, at: Vector3, height: float, leaf: Color) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.10
	trunk.bottom_radius = 0.17
	trunk.height = height
	_mesh(parent, trunk, at + Vector3(0, height * 0.5, 0), _mat(Color("77543c"), 0.92))
	var crown := SphereMesh.new()
	crown.radius = 1.40
	crown.height = 0.68
	var top := _mesh(parent, crown, at + Vector3(0, height + 0.12, 0), _mat(leaf, 0.89))
	top.scale = Vector3(1.2, 0.6, 1.2)


func _pine(parent: Node3D, at: Vector3, height: float, leaf: Color, snow: bool) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.16
	trunk.height = height * 0.64
	_mesh(parent, trunk, at + Vector3(0, height * 0.32, 0), _mat(Color("664833"), 0.9))
	for tier in 2:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.03
		cone.bottom_radius = 1.00 if tier == 0 else 0.69
		cone.height = height * 0.43
		cone.radial_segments = 7
		var tint := Color("c8d9d9") if snow else leaf.lightened(float(tier) * 0.07)
		_mesh(parent, cone, at + Vector3(0, height * (0.63 + 0.19 * float(tier)), 0), _mat(tint, 0.95))


func _dock(parent: Node3D, radius: float) -> void:
	var timber := _mat(Color("82674a"), 0.87)
	for i in 4:
		_box(parent, Vector3(2.8, 0.19, 0.78),
			Vector3(0, 0.9, radius * 0.47 + float(i) * 0.67), timber)
	for side in [-1.0, 1.0]:
		for i in 2:
			_box(parent, Vector3(0.18, 2.0, 0.18),
				Vector3(side * 1.15, 0.10, radius * 0.55 + float(i) * 1.40), timber)


func _fortress(parent: Node3D, radius: float) -> void:
	var stone := _mat(Color("a2aaa4"), 0.94)
	var roof := _mat(Color("4a6870"), 0.84)
	for side in [-1.0, 1.0]:
		var wall := _box(parent, Vector3(1.8, 3.7, 5.0),
			Vector3(side * radius * 0.21, 4.1, 0), stone)
		wall.rotation.y = side * 0.21
		var tower := CylinderMesh.new()
		tower.top_radius = 1.13
		tower.bottom_radius = 1.35
		tower.height = 5.4
		_mesh(parent, tower, Vector3(side * radius * 0.40, 5.1, -1.9), stone)
		var cap := CylinderMesh.new()
		cap.top_radius = 0.1
		cap.bottom_radius = 1.5
		cap.height = 1.6
		_mesh(parent, cap, Vector3(side * radius * 0.40, 8.4, -1.9), roof)


func _volcano(parent: Node3D) -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 1.35
	cone.bottom_radius = island_radius * 0.35
	cone.height = 6.5
	cone.radial_segments = 10
	_mesh(parent, cone, Vector3(0, 5.2, 0), _mat(Color("393039"), 0.96))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.77
	cap.bottom_radius = 0.77
	cap.height = 0.14
	var lava := _mat(Color("fa774c"), 0.3)
	lava.emission_enabled = true
	lava.emission = Color("f74728")
	lava.emission_energy_multiplier = 1.6
	_mesh(parent, cap, Vector3(0, 8.51, 0), lava)


func _lighthouse(parent: Node3D, radius: float) -> void:
	var at := Vector3(radius * 0.13, 0, -radius * 0.16)
	var tower := CylinderMesh.new()
	tower.top_radius = 0.68
	tower.bottom_radius = 1.04
	tower.height = 6.8
	_mesh(parent, tower, at + Vector3(0, 5.6, 0), _mat(Color("d2d2c4"), 0.79))
	var lamp := SphereMesh.new()
	lamp.radius = 0.85
	lamp.height = 1.7
	var glow := _mat(Color("ffe0a2"), 0.3)
	glow.emission_enabled = true
	glow.emission = Color("f5be73")
	glow.emission_energy_multiplier = 1.3
	_beacon = _mesh(parent, lamp, at + Vector3(0, 9.45, 0), glow)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.12
	cap.bottom_radius = 1.12
	cap.height = 1.15
	_mesh(parent, cap, at + Vector3(0, 10.5, 0), _mat(Color("3d5260"), 0.82))


func _process(delta: float) -> void:
	_clock += delta
	if _beacon != null:
		# Lighthouse signal glows softly without costly real-time lighting.
		_beacon.scale = Vector3.ONE * (1.0 + 0.06 * sin(_clock * 2.0))
