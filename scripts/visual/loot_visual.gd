class_name LootVisual
extends RefCounted
## Small native meshes, not a newly recovered Unity treasure asset.
static var cube: BoxMesh
static var halo: TorusMesh
static var wood: StandardMaterial3D
static var materials: Dictionary = {}

static func build(parent: Node3D, repair: bool, admiral: bool = false, tier: String = "common", loot_type: String = "coins") -> Node3D:
	if cube == null:
		cube = BoxMesh.new()
		cube.size = Vector3.ONE
		halo = TorusMesh.new()
		halo.inner_radius = 0.98
		halo.outer_radius = 1.10
		halo.rings = 16
		halo.ring_segments = 6
		wood = _material(Color("75482a"), false)
	var root := Node3D.new()
	root.name = "LootVisual"
	parent.add_child(root)
	var metal := _tier_material("repair" if repair else tier)
	var scale_factor := 1.45 if admiral else (1.16 if tier in ["rare", "epic", "legendary"] else 1.0)
	root.scale = Vector3.ONE * scale_factor
	if loot_type == "coins":
		_part(root, Vector3(0.82,0.24,0.82),Vector3(0,-0.18,0),metal)
		_part(root, Vector3(0.62,0.18,0.62),Vector3(0,0.08,0),metal)
	elif loot_type == "salvage_chest":
		_part(root,Vector3(1.25,0.34,0.72),Vector3.ZERO,wood)
		_part(root,Vector3(0.18,0.82,0.78),Vector3(-0.38,0.05,0),metal)
	else:
		_part(root, Vector3(1.15, 0.65, 0.78), Vector3.ZERO, wood)
	_part(root, Vector3(1.2, 0.18, 0.84), Vector3(0, 0.39, 0), metal)
	for x in [-0.4, 0.4]:
		_part(root, Vector3(0.09, 0.67, 0.82), Vector3(x, 0, 0), metal)
	_part(root, Vector3(0.19, 0.25, 0.06), Vector3(0, 0.12, 0.43), metal)
	if admiral or tier in ["epic", "legendary"]:
		_part(root, Vector3(0.62, 0.10, 0.88), Vector3(0, 0.55, 0), metal)
		_part(root, Vector3(0.12, 0.78, 0.88), Vector3(0, 0.08, 0), metal)
	if repair:
		_part(root, Vector3(0.38, 0.1, 0.065), Vector3(0, -0.1, 0.45), metal)
		_part(root, Vector3(0.1, 0.38, 0.065), Vector3(0, -0.1, 0.45), metal)
	var ring := MeshInstance3D.new()
	ring.name = "PickupHalo"
	ring.mesh = halo
	ring.material_override = metal
	ring.position.y = -0.52
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.set_meta("visual_only", true)
	root.add_child(ring)
	_add_m200_water_beacon(root, metal, admiral or tier in ["epic", "legendary"])
	var visual_slot := "repair_crate" if repair else ("loot_coin_cache" if loot_type=="coins" else ("loot_salvage_bundle" if loot_type=="salvage_chest" else ("loot_admiral_vault" if loot_type=="admiral_chest" else ("loot_chest_%s" % tier))))
	if not repair and tier == "common": visual_slot = "loot_chest"
	if AssetVisualLibrary.placeholders(parent.get_tree()) and AssetVisualLibrary.install(root, visual_slot) != null:
		for child in root.get_children():
			if child is MeshInstance3D and child != ring: child.hide()
	if not repair:
		SalvageDressing.decorate(root,tier)
	return root

static func _add_m200_water_beacon(root: Node3D, material: Material, high_value: bool) -> void:
	# M200 Visual Master convergence: loot must read at sea-chart zoom without becoming HUD.
	# This is visual-only and never changes pickup radius, lifetime, rewards, or navigation.
	var beacon := MeshInstance3D.new()
	beacon.name = "M200LootBeacon"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.045 if not high_value else 0.065
	mesh.bottom_radius = 0.20 if not high_value else 0.28
	mesh.height = 1.9 if not high_value else 2.6
	beacon.mesh = mesh
	beacon.position = Vector3(0.0, 0.82 if not high_value else 1.15, 0.0)
	beacon.material_override = material
	beacon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beacon.set_meta("visual_only", true)
	root.add_child(beacon)

static func _tier_material(tier: String) -> StandardMaterial3D:
	if materials.has(tier):
		return materials[tier]
	var colors := {
		"repair": Color("68d7a1"),
		"common": Color("e4c271"),
		"uncommon": Color("6fda9d"),
		"rare": Color("56bfff"),
		"epic": Color("bd75ff"),
		"legendary": Color("ffcb55"),
	}
	var value := _material(colors.get(tier, colors.common), true)
	materials[tier] = value
	return value

static func _part(root: Node3D, size: Vector3, position: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.mesh = cube
	part.scale = size
	part.position = position
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(part)

static func _material(color: Color, glow: bool) -> StandardMaterial3D:
	var value := StandardMaterial3D.new()
	value.albedo_color = color
	value.roughness = 0.65
	value.emission_enabled = glow
	value.emission = color
	value.emission_energy_multiplier = 0.5
	return value
