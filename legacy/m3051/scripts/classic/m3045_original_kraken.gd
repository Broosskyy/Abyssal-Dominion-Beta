extends Node3D
## Original, animated low-poly kraken. Gameplay HP and attack remain on parent.

var _body: Node3D
var _tentacles: Array[Node3D] = []
var _damage_ratio := 1.0
var _phase := 0.0


func configure(visual_scale: float = 1.0) -> void:
	_body = Node3D.new()
	_body.name = "OriginalKrakenBody"
	add_child(_body)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("35546a")
	skin.roughness = 0.78
	var underside := StandardMaterial3D.new()
	underside.albedo_color = Color("54837b")
	underside.roughness = 0.84
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color("f7c66d")
	eye.emission_enabled = true
	eye.emission = Color("f3a556")
	eye.emission_energy_multiplier = 1.1
	var pupil := StandardMaterial3D.new()
	pupil.albedo_color = Color("151a25")
	var head := SphereMesh.new()
	head.radius = 2.0
	head.height = 3.5
	_mesh(_body, head, Vector3(0, 2.3, 0), skin)
	var jaw := SphereMesh.new()
	jaw.radius = 1.42
	jaw.height = 1.32
	_mesh(_body, jaw, Vector3(0, 1.12, -0.7), underside)
	for side in [-1.0, 1.0]:
		var eyeball := SphereMesh.new()
		eyeball.radius = 0.28
		eyeball.height = 0.55
		_mesh(_body, eyeball, Vector3(side * 1.16, 2.9, -1.25), eye)
		var center := SphereMesh.new()
		center.radius = 0.12
		center.height = 0.24
		_mesh(_body, center, Vector3(side * 1.19, 2.9, -1.50), pupil)
	for i in 7:
		var root := Node3D.new()
		root.name = "Tentacle_%d" % i
		root.position = Vector3(0, 0.25, 0)
		_body.add_child(root)
		_tentacles.append(root)
		var angle := TAU * float(i) / 7.0
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		var start := radial * 1.15 + Vector3(0, 0.65, 0)
		var joint := radial * 3.30 + Vector3(0, 1.1, 0)
		var end := radial * 5.2 + Vector3(0, 2.0 + 0.35 * float(i % 3), 0)
		_segment(root, start, joint, 0.40, skin)
		_segment(root, joint, end, 0.23, underside)
	scale = Vector3.ONE * visual_scale


func _mesh(parent: Node3D, geometry: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = geometry
	item.material_override = material
	item.position = at
	parent.add_child(item)
	return item


func _segment(parent: Node3D, start: Vector3, finish: Vector3, thickness: float, material: Material) -> void:
	var axis := finish - start
	var geometry := CylinderMesh.new()
	geometry.top_radius = thickness * 0.62
	geometry.bottom_radius = thickness
	geometry.height = axis.length()
	geometry.radial_segments = 8
	var part := _mesh(parent, geometry, (start + finish) * 0.5, material)
	part.quaternion = Quaternion(Vector3.UP, axis.normalized())


func set_hull_ratio(value: float) -> void:
	_damage_ratio = clampf(value, 0.0, 1.0)


func _process(delta: float) -> void:
	_phase += delta
	if _body == null:
		return
	_body.position.y = sin(_phase * 1.2) * 0.25
	_body.rotation.y = sin(_phase * 0.21) * 0.14
	for i in _tentacles.size():
		var arm: Node3D = _tentacles[i]
		arm.rotation.y = sin(_phase * 1.5 + float(i) * 0.8) * 0.18
		arm.rotation.x = cos(_phase * 1.1 + float(i) * 1.1) * 0.085
	# Damage controls expressive motion only, not a wreck sprite at full HP.
	_body.scale.y = lerpf(0.83, 1.0, _damage_ratio)
