class_name LateFleetSilhouetteFactory
extends RefCounted

static func create(entry: Dictionary) -> Node3D:
	if entry.is_empty(): return null
	var recipe := entry.get("recipe", {}) as Dictionary
	var root := Node3D.new(); root.name = "M151SilhouetteFallback"
	root.set_meta("visual_only", true); root.set_meta("collision_authority", false); root.set_meta("final_glb", false)
	var length := float(recipe.get("length", 7.0)); var width := float(recipe.get("width", 2.0)); var height := float(recipe.get("height", 1.0))
	var variant := int(recipe.get("variant", 3)); var twin := bool(recipe.get("twin_hull", false))
	var hull_mat := _material(_color_for(entry), 0.62, 0.08)
	if twin:
		_box(root, "PortHull", Vector3(width * 0.34, height, length), Vector3(-width * 0.34, 0, 0), hull_mat)
		_box(root, "StarboardHull", Vector3(width * 0.34, height, length), Vector3(width * 0.34, 0, 0), hull_mat)
		_box(root, "BridgeDeck", Vector3(width * 0.82, height * 0.22, length * 0.48), Vector3(0, height * 0.62, 0), hull_mat)
	else:
		_box(root, "Hull", Vector3(width, height, length), Vector3.ZERO, hull_mat)
		_box(root, "Bow", Vector3(width * (0.54 + variant * 0.035), height * 0.72, length * 0.26), Vector3(0, 0.02, -length * 0.56), hull_mat, Vector3(0, deg_to_rad(45), 0))
	var deck_mat := _material(_color_for(entry).lightened(0.18), 0.78, 0.02)
	for deck in range(int(recipe.get("deck_count", 1))):
		_box(root, "Deck_%d" % deck, Vector3(width * (0.76 - deck * 0.08), height * 0.30, length * (0.52 - deck * 0.06)), Vector3(0, height * (0.64 + deck * 0.28), length * (0.08 + deck * 0.08)), deck_mat)
	var mast_count := int(recipe.get("masts", 2)); var mast_mat := _material(Color("4a3027"), 0.90, 0.0); var sail_mat := _material(_sail_color(entry), 0.72, 0.0)
	for mast in range(mast_count):
		var z := (float(mast) - float(mast_count - 1) * 0.5) * minf(float(recipe.get("mast_spacing", 1.8)), length / maxf(mast_count, 1))
		_cylinder(root, "Mast_%d" % mast, 0.065 + variant * 0.006, height * (2.2 + 0.13 * mast), Vector3(0, height * 1.52, z), mast_mat)
		_box(root, "Sail_%d" % mast, Vector3(width * (0.52 + 0.05 * ((mast + variant) % 3)), height * (0.92 + 0.10 * variant), 0.055), Vector3((0.12 if mast % 2 == 0 else -0.12) * variant, height * 2.0, z), sail_mat, Vector3(0, 0, deg_to_rad(float((variant - 3) * 3))))
	for side in [-1, 1]:
		for gun in range(2 + variant % 3):
			_cylinder(root, "Gun_%s_%d" % ["P" if side < 0 else "S", gun], 0.09, 0.42, Vector3(side * width * 0.56, height * 0.38, (gun - 1.5) * length * 0.16), _material(Color("20262b"), 0.36, 0.72), Vector3(0, 0, PI * 0.5))
	_add_special(root, entry, Vector3(width, height, length))
	return root

static func _add_special(root: Node3D, entry: Dictionary, size: Vector3) -> void:
	var family := str(entry.get("family", "")); var glow := _material(Color("3ed2c0") if "void" in family or "abyss" in family else Color("c7582e"), 0.30, 0.18, true)
	if "catamaran" in family or "void" in family:
		var ring := MeshInstance3D.new(); ring.name = "NegativeSpaceHalo"; var torus := TorusMesh.new(); torus.inner_radius = size.x * 0.34; torus.outer_radius = size.x * 0.42; ring.mesh = torus; ring.rotation_degrees.x = 90; ring.position = Vector3(0, size.y * 1.25, size.z * 0.22); ring.material_override = glow; root.add_child(ring)
	elif "cathedral" in family or "dominion" in family or "prestige" in str(entry.get("kind", "")):
		_box(root, "CrownSpine", Vector3(size.x * 0.22, size.y * 1.75, size.z * 0.12), Vector3(0, size.y * 1.65, size.z * 0.24), glow)
	else:
		_box(root, "ProwIdentity", Vector3(size.x * 0.18, size.y * 0.18, size.z * 0.52), Vector3(0, size.y * 0.18, -size.z * 0.66), glow, Vector3(deg_to_rad(-18), 0, 0))

static func _box(parent: Node3D, name_value: String, size: Vector3, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var node := MeshInstance3D.new(); node.name = name_value; var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.position = position; node.rotation = rotation; node.material_override = material; parent.add_child(node)

static func _cylinder(parent: Node3D, name_value: String, radius: float, height: float, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> void:
	var node := MeshInstance3D.new(); node.name = name_value; var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius * 1.08; mesh.height = height; mesh.radial_segments = 8; node.mesh = mesh; node.position = position; node.rotation = rotation; node.material_override = material; parent.add_child(node)

static func _material(color: Color, roughness: float, metallic: float, emission: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new(); result.albedo_color = color; result.roughness = roughness; result.metallic = metallic
	if emission: result.emission_enabled = true; result.emission = color; result.emission_energy_multiplier = 0.42
	return result

static func _color_for(entry: Dictionary) -> Color:
	var index := int(entry.get("class_number", 100)); var colors := [Color("6b2d2d"),Color("495866"),Color("674b37"),Color("3d6261"),Color("55466d"),Color("303f52"),Color("593e48"),Color("35555a"),Color("292b45"),Color("3c2734")]
	return colors[clampi(int((index - 51) / 5), 0, colors.size() - 1)] if str(entry.get("kind", "regular")) == "regular" else Color("403052").lightened(float(int(str(entry.get("rank", "P1")).trim_prefix("P"))) * 0.04)

static func _sail_color(entry: Dictionary) -> Color:
	return _color_for(entry).lightened(0.32)
