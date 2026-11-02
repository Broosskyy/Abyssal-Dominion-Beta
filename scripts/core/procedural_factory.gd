class_name ProceduralFactory
extends RefCounted

const ShipMotorScript = preload("res://scripts/gameplay/ship_motor.gd")
const ShipWakeScript = preload("res://scripts/visual/ship_wake.gd")
const WaterSurfaceScript = preload("res://scripts/visual/water_surface.gd")
const ReferenceVisualAdapterScript = preload("res://scripts/visual/reference_visual_adapter.gd")
const ReferenceIslandAdapterScript = preload("res://scripts/visual/reference_island_adapter.gd")
const ShorelineFoamScript = preload("res://scripts/visual/shoreline_foam.gd")
const M285ShipDamageVisualRigScript = preload("res://scripts/visual/m285_ship_damage_visual_rig.gd")
const M286ShipDamageOverlayRigScript = preload("res://scripts/visual/m286_ship_damage_overlay_rig.gd")
const M287ShipMotionVisualRigScript = preload("res://scripts/visual/m287_ship_motion_visual_rig.gd")
const M288NavalContactVisualRigScript = preload("res://scripts/visual/m288_naval_contact_visual_rig.gd")


static func material(color: Color, roughness: float = 0.55, metallic: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	return result


static func mesh_node(name_value: String, mesh: PrimitiveMesh, color: Color, position: Vector3, scale_value: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_value
	node.mesh = mesh
	node.material_override = material(color)
	node.position = position
	node.scale = scale_value
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node


static func create_ship(display_name: String, spawn_position: Vector3, hull_color: Color, is_player: bool) -> CharacterBody3D:
	var ship := CharacterBody3D.new()
	ship.set_script(ShipMotorScript)
	ship.name = display_name
	ship.position = spawn_position
	# M192: ships/NPCs/monsters share a non-blocking movement layer. They can overlap
	# like classic chart-combat units, while their movement mask only collides with land.
	ship.collision_layer = 1
	ship.collision_mask = 4
	ship.set("is_player", is_player)
	ship.set_meta("motion_profile_id", "BALANCED" if is_player else "LIGHT")
	ship.add_to_group("ships")
	ship.add_to_group("player" if is_player else "enemies")
	M214WorldScaleCatalog.annotate_ship(ship, "player" if is_player else "npc_standard")
	var visual := Node3D.new()
	visual.name = "Visual"
	ship.add_child(visual)

	var hull_mesh := BoxMesh.new()
	visual.add_child(mesh_node("Hull", hull_mesh, hull_color, Vector3.ZERO, Vector3(2.05, 0.65, 4.8)))

	var bow_mesh := SphereMesh.new()
	bow_mesh.height = 1.0
	bow_mesh.radius = 0.5
	visual.add_child(mesh_node("Bow", bow_mesh, hull_color, Vector3(0.0, 0.0, 2.35), Vector3(2.0, 0.7, 1.6)))

	var deck_mesh := BoxMesh.new()
	visual.add_child(mesh_node("Deck", deck_mesh, Color("71401e"), Vector3(0.0, 0.48, -0.1), Vector3(1.75, 0.18, 3.7)))
	_create_ship_detail(visual, hull_color, is_player)
	_create_mast(visual, Vector3(0.0, 1.7, 0.35), 1.0)
	_create_mast(visual, Vector3(0.0, 1.45, -1.45), 0.82)
	_create_railings(visual)
	_create_selection_ring(visual, is_player)
	_create_ship_contract_nodes(ship)
	var damage_visual_rig: M285ShipDamageVisualRig = M285ShipDamageVisualRigScript.new()
	damage_visual_rig.name = "M285ShipDamageVisualRig"
	ship.add_child(damage_visual_rig)
	var destruction_visual_rig: M286ShipDamageOverlayRig = M286ShipDamageOverlayRigScript.new()
	destruction_visual_rig.name = "M286ShipDamageOverlayRig"
	ship.add_child(destruction_visual_rig)
	if is_player:
		var support_telemetry := SupportContributionTelemetry.new()
		support_telemetry.name = "SupportContribution"
		ship.add_child(support_telemetry)
		var crew_officers := M241CrewOfficerRuntime.new()
		crew_officers.name = "CrewOfficers"
		ship.add_child(crew_officers)
		var officer_progression := M242OfficerProgressionRuntime.new()
		officer_progression.name = "OfficerProgression"
		ship.add_child(officer_progression)
		var wanted_bounty := M243WantedBountyRuntime.new()
		wanted_bounty.name = "WantedBounty"
		ship.add_child(wanted_bounty)
		var special_pve_oracle := M245SpecialPveOracleRuntime.new()
		special_pve_oracle.name = "SpecialPveOracle"
		ship.add_child(special_pve_oracle)
		var achievement_collections := M246AchievementCollectionRuntime.new()
		achievement_collections.name = "AchievementCollections"
		ship.add_child(achievement_collections)
		var bazaar_trading := M247BazaarTradingRuntime.new()
		bazaar_trading.name = "BazaarTrading"
		ship.add_child(bazaar_trading)
		var social_runtime := M248SocialRuntime.new()
		social_runtime.name = "SocialRuntime"
		ship.add_child(social_runtime)
		var pvp_honor_ranked := M249PvpHonorRankedRuntime.new()
		pvp_honor_ranked.name = "PvpHonorRanked"
		ship.add_child(pvp_honor_ranked)
		var guild_governance := M250GuildGovernanceRuntime.new()
		guild_governance.name = "GuildGovernance"
		ship.add_child(guild_governance)
		var meta_progression := M251MetaProgressionRuntime.new()
		meta_progression.name = "MetaProgression"
		ship.add_child(meta_progression)
		var sustain := M240SustainSupportRuntime.new()
		sustain.name = "SustainSupport"
		ship.add_child(sustain)

	var collision := CollisionShape3D.new()
	collision.name = "ShipCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.4, 1.5, 7.4)
	collision.shape = shape
	ship.add_child(collision)
	var wake: ShipWake = ShipWakeScript.new()
	wake.name = "WakeVFX"
	ship.add_child(wake)
	var motion_visual_rig: M287ShipMotionVisualRig = M287ShipMotionVisualRigScript.new()
	motion_visual_rig.name = "M287ShipMotionVisualRig"
	ship.add_child(motion_visual_rig)
	var contact_visual_rig: M288NavalContactVisualRig = M288NavalContactVisualRigScript.new()
	contact_visual_rig.name = "M288NavalContactVisualRig"
	ship.add_child(contact_visual_rig)
	var reference_adapter: ReferenceVisualAdapter = ReferenceVisualAdapterScript.new()
	reference_adapter.name = "ReferenceVisualAdapter"
	ship.add_child(reference_adapter)
	return ship


static func _create_ship_detail(parent: Node3D, hull_color: Color, is_player: bool) -> void:
	# M20 silhouette pass: inexpensive primitive detail that remains Compatibility/Web safe.
	var dark_hull := hull_color.darkened(0.32)
	var trim := Color("d4aa55") if is_player else Color("9d7445")
	var keel_mesh := BoxMesh.new()
	parent.add_child(mesh_node("Keel", keel_mesh, dark_hull, Vector3(0.0, -0.36, -0.15), Vector3(1.6, 0.16, 4.35)))

	var stern_mesh := BoxMesh.new()
	parent.add_child(mesh_node("SternGallery", stern_mesh, dark_hull, Vector3(0.0, 0.43, -2.28), Vector3(1.82, 0.78, 0.48)))
	var cabin_mesh := BoxMesh.new()
	parent.add_child(mesh_node("CaptainCabin", cabin_mesh, Color("5b3219"), Vector3(0.0, 1.02, -1.75), Vector3(1.32, 0.62, 0.92)))
	var roof_mesh := BoxMesh.new()
	parent.add_child(mesh_node("CabinRoof", roof_mesh, dark_hull, Vector3(0.0, 1.39, -1.75), Vector3(1.48, 0.12, 1.08)))

	for side in [-1.0, 1.0]:
		var trim_mesh := BoxMesh.new()
		parent.add_child(mesh_node("HullTrim", trim_mesh, trim, Vector3(side * 1.04, 0.22, -0.05), Vector3(0.055, 0.08, 3.95)))
		for z in [-1.15, 0.0, 1.15]:
			var cannon_mesh := CylinderMesh.new()
			cannon_mesh.top_radius = 0.105
			cannon_mesh.bottom_radius = 0.13
			cannon_mesh.height = 0.58
			var cannon := mesh_node("DeckCannon", cannon_mesh, Color("20252a"), Vector3(side * 1.36, 0.52, z), Vector3.ONE)
			cannon.rotation_degrees.z = 90.0
			parent.add_child(cannon)

	var bowsprit_mesh := CylinderMesh.new()
	bowsprit_mesh.top_radius = 0.07
	bowsprit_mesh.bottom_radius = 0.09
	bowsprit_mesh.height = 2.15
	var bowsprit := mesh_node("Bowsprit", bowsprit_mesh, Color("4b2b16"), Vector3(0.0, 0.78, 3.04), Vector3.ONE)
	bowsprit.rotation_degrees.x = 68.0
	parent.add_child(bowsprit)

	if is_player:
		var pennant_mesh := QuadMesh.new()
		pennant_mesh.size = Vector2(0.72, 0.34)
		var pennant := mesh_node("CaptainPennant", pennant_mesh, Color("2ec8ef"), Vector3(0.0, 3.28, 0.35), Vector3.ONE)
		pennant.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
		parent.add_child(pennant)


static func _create_mast(parent: Node3D, local_position: Vector3, size_scale: float) -> void:
	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.11
	mast_mesh.bottom_radius = 0.11
	mast_mesh.height = 2.9 * size_scale
	parent.add_child(mesh_node("Mast", mast_mesh, Color("3b2110"), local_position, Vector3.ONE))

	var sail_mesh := QuadMesh.new()
	sail_mesh.size = Vector2(1.8 * size_scale, 2.0 * size_scale)
	var sail := mesh_node("Sail", sail_mesh, Color("d5ccb0"), local_position + Vector3(0.0, 0.35 * size_scale, 0.0), Vector3.ONE)
	sail.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(sail)


static func _create_railings(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var rail_mesh := BoxMesh.new()
		parent.add_child(mesh_node("Rail", rail_mesh, Color("47270f"), Vector3(side * 1.03, 0.72, -0.1), Vector3(0.08, 0.32, 3.8)))


static func _create_selection_ring(parent: Node3D, is_player: bool) -> void:
	var ring := MeshInstance3D.new()
	ring.name = "SelectionRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 2.48
	torus.outer_radius = 2.80 # M199: stronger target silhouette at gameplay camera distance.
	ring.mesh = torus
	ring.position.y = -0.5
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.16, 0.82, 1.0, 0.62) if is_player else Color(1.0, 0.25, 0.16, 0.36)
	ring_material.emission_enabled = true
	ring_material.emission = ring_material.albedo_color
	ring_material.emission_energy_multiplier = 2.05
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = is_player
	parent.add_child(ring)


static func _create_ship_contract_nodes(ship: Node3D) -> void:
	var sockets := Node3D.new()
	sockets.name = "Sockets"
	ship.add_child(sockets)
	for side_data in [["Port", -1.75], ["Starboard", 1.75]]:
		for index in range(-1, 2):
			var cannon_socket := Marker3D.new()
			cannon_socket.name = "Cannon%s_%d" % [side_data[0], index + 2]
			cannon_socket.position = Vector3(side_data[1], 0.3, index * 1.15)
			sockets.add_child(cannon_socket)
	for vfx_socket in [
		["VFX_Damage_01", Vector3(-0.62, 0.82, -0.65)],
		["VFX_Damage_02", Vector3(0.58, 0.82, 0.72)],
		["VFX_Shield", Vector3(0.0, 0.48, 0.0)],
		["VFX_Sink", Vector3(0.0, -0.18, 0.0)],
		["VFX_Bow", Vector3(0.0, 0.28, 2.52)],
		["VFX_PortHull", Vector3(-1.08, 0.0, 0.0)],
		["VFX_StarboardHull", Vector3(1.08, 0.0, 0.0)],
		["VFX_Deck", Vector3(0.0, 0.68, 0.0)],
		["VFX_Mast", Vector3(0.0, 1.25, 0.28)],
		["VFX_Sails", Vector3(0.0, 2.1, 0.25)],
		["VFX_Stern", Vector3(0.0, 0.42, -2.48)],
		["VFX_Waterline", Vector3(0.0, -0.42, 0.0)],
		["VFX_Wreck", Vector3(0.0, -0.48, 0.0)],
		["MOTION_BowFoam", Vector3(0.0, -0.47, 2.55)],
		["MOTION_SternWake", Vector3(0.0, -0.49, -2.5)],
		["MOTION_TurnWake", Vector3(0.0, -0.5, -1.25)],
		["MOTION_Waterline", Vector3(0.0, -0.46, 0.0)],
		["MOTION_AnchorRipple", Vector3(0.0, -0.51, 0.0)],
		["MOTION_Sails", Vector3(0.0, 2.0, 0.0)],
	]:
		var marker := Marker3D.new()
		marker.name = vfx_socket[0]
		marker.position = vfx_socket[1]
		marker.set_meta("presentation_only", true)
		marker.set_meta("replaceable", true)
		sockets.add_child(marker)
	var anchors := Node3D.new()
	anchors.name = "Anchors"
	ship.add_child(anchors)
	for anchor_data in [["Nameplate", Vector3(0.0, 6.7, 0.0)], ["Selection", Vector3(0.0, -0.45, 0.0)]]:
		var anchor := Marker3D.new()
		anchor.name = anchor_data[0]
		anchor.position = anchor_data[1]
		anchors.add_child(anchor)
	var audio := Node3D.new()
	audio.name = "Audio"
	ship.add_child(audio)


static func create_ocean() -> Node3D:
	var ocean := Node3D.new()
	ocean.name = "Ocean"
	var surface: WaterSurface = WaterSurfaceScript.new()
	surface.name = "WaterSurface"
	ocean.add_child(surface)
	var ambience_path := "res://assets/recovered_test/m8/audio/Oceano_en_Calma_1__1323.wav"
	if ResourceLoader.exists(ambience_path):
		var ambience := AudioStreamPlayer.new()
		ambience.name = "RecoveredOceanAmbience"
		ambience.bus = "Ambience"
		ambience.stream = load(ambience_path) as AudioStream
		ambience.volume_db = -18.0
		ambience.autoplay = true
		ocean.add_child(ambience)
	return ocean


static func create_island(
	spawn_position: Vector3,
	radius: float,
	biome: String = "tropical",
	use_reference_visual: bool = false,
	aspect: Vector2 = Vector2.ONE,
	yaw_degrees: float = 0.0,
	prop_density: float = 1.0,
	composition_profile: String = "",
) -> StaticBody3D:
	var island := StaticBody3D.new()
	island.name = "%s_Island" % biome.capitalize()
	island.position = spawn_position
	# M192: land is authoritative navigation geometry; it blocks ships, unlike units.
	island.collision_layer = 4
	island.collision_mask = 0
	island.rotation_degrees.y = yaw_degrees
	island.add_to_group("islands")
	island.set_meta("island_radius", radius)
	M214WorldScaleCatalog.annotate_island(island, radius)
	island.set_meta("island_aspect", aspect)
	island.set_meta("island_prop_density", prop_density)
	if not composition_profile.is_empty():
		IslandCompositionCatalog.apply_meta(island, composition_profile)
		aspect = island.get_meta("island_aspect", aspect)
		prop_density = float(island.get_meta("island_prop_density", prop_density))
		island.rotation_degrees.y = float(IslandCompositionCatalog.profile(composition_profile).get("yaw", yaw_degrees))
	var recovered_profile := "tropical_04" if use_reference_visual else "tropical_01"
	if biome == "desert":
		recovered_profile = "desert_06"
	elif biome == "snow":
		recovered_profile = "snow_02"
	island.set_meta("island_profile", recovered_profile)
	var palette := _island_palette(biome)
	var sx := maxf(0.55, aspect.x)
	var sz := maxf(0.55, aspect.y)

	var rock_mesh := CylinderMesh.new()
	rock_mesh.top_radius = 0.72
	rock_mesh.bottom_radius = 1.0
	rock_mesh.height = 1.2
	island.add_child(mesh_node("Underside", rock_mesh, palette.underside, Vector3(0.0, 0.35, 0.0), Vector3(radius * sx, 1.0, radius * 0.78 * sz)))

	var coast_mesh := CylinderMesh.new()
	coast_mesh.top_radius = 0.94
	coast_mesh.bottom_radius = 1.0
	coast_mesh.height = 0.22
	island.add_child(mesh_node("Coast", coast_mesh, palette.coast, Vector3(0.0, 0.86, 0.0), Vector3(radius * 0.95 * sx, 1.0, radius * 0.74 * sz)))

	var ground_mesh := CylinderMesh.new()
	ground_mesh.top_radius = 0.92
	ground_mesh.bottom_radius = 1.0
	ground_mesh.height = 0.35
	island.add_child(mesh_node("Ground", ground_mesh, palette.ground, Vector3(0.0, 1.05, 0.0), Vector3(radius * 0.86 * sx, 1.0, radius * 0.66 * sz)))
	_create_island_props(island, radius, biome, palette, aspect, prop_density)
	# M71: procedural fallback uses the same replaceable M64 material families as final world art.
	var underside_node:=island.get_node_or_null("Underside") as MeshInstance3D
	var coast_node:=island.get_node_or_null("Coast") as MeshInstance3D
	var ground_node:=island.get_node_or_null("Ground") as MeshInstance3D
	if underside_node != null: underside_node.material_override=EnvironmentMaterialCatalog.rock()
	if coast_node != null: coast_node.material_override=EnvironmentMaterialCatalog.sand()
	if ground_node != null: ground_node.material_override=EnvironmentMaterialCatalog.vegetation()

	var collision := CollisionShape3D.new()
	collision.name = "IslandCollision"
	var shape := BoxShape3D.new()
	shape.size = Vector3(radius * 1.52 * sx, 2.0, radius * 1.18 * sz)
	collision.shape = shape
	collision.position.y = 0.65
	island.add_child(collision)
	var foam: ShorelineFoam = ShorelineFoamScript.new()
	foam.name = "ShorelineFoam"
	foam.radius = radius
	foam.aspect = Vector2(sx, sz * 0.78)
	island.add_child(foam)
	if not composition_profile.is_empty():
		IslandFallbackComposer.apply(island, composition_profile)
		IslandHeroDetailComposer.apply(island, composition_profile)
		IslandSecondaryDetailComposer.apply(island, composition_profile)
	var reference_adapter: ReferenceIslandAdapter = ReferenceIslandAdapterScript.new()
	reference_adapter.name = "ReferenceIslandAdapter"
	island.add_child(reference_adapter)
	return island


static func _island_palette(biome: String) -> Dictionary:
	match biome:
		"desert":
			return {"underside": Color("60462f"), "coast": Color("d5ad65"), "ground": Color("a87d3f"), "foliage": Color("758044")}
		"snow":
			return {"underside": Color("49535c"), "coast": Color("b9d1db"), "ground": Color("e5eef1"), "foliage": Color("31554c")}
		_:
			return {"underside": Color("3e413c"), "coast": Color("d6ba76"), "ground": Color("3d7435"), "foliage": Color("317544")}


static func _create_island_props(
	island: Node3D,
	radius: float,
	biome: String,
	palette: Dictionary,
	aspect: Vector2 = Vector2.ONE,
	density: float = 1.0,
) -> void:
	var base_positions := [
		Vector3(-0.30, 0.0, 0.06), Vector3(0.27, 0.0, -0.12),
		Vector3(0.02, 0.0, 0.25), Vector3(-0.03, 0.0, -0.27),
		Vector3(0.38, 0.0, 0.16), Vector3(-0.39, 0.0, -0.16),
	]
	var tree_count := clampi(roundi((2.0 + radius * 0.38) * density), 1, base_positions.size())
	for index in tree_count:
		var local: Vector3 = base_positions[index]
		local.x *= aspect.x
		local.z *= aspect.y * 0.78
		var base_position: Vector3 = local * radius
		base_position.y = 1.42
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.07
		trunk_mesh.bottom_radius = 0.11
		trunk_mesh.height = 1.05 + float(index % 3) * 0.17
		island.add_child(mesh_node("TreeTrunk_%02d" % index, trunk_mesh, Color("5f3b1f"), base_position, Vector3.ONE))
		if biome == "snow":
			var conifer_mesh := CylinderMesh.new()
			conifer_mesh.top_radius = 0.05
			conifer_mesh.bottom_radius = 0.64
			conifer_mesh.height = 1.25
			island.add_child(mesh_node("Foliage_%02d" % index, conifer_mesh, palette.foliage, base_position + Vector3.UP * 0.95, Vector3.ONE))
		else:
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 0.56
			crown_mesh.height = 0.88
			island.add_child(mesh_node("Foliage_%02d" % index, crown_mesh, palette.foliage, base_position + Vector3.UP * 0.92, Vector3.ONE))

	# M21 mockup convergence: rocky shoreline breakup and a central landmark silhouette.
	var rock_count := clampi(roundi(radius * 0.55 * density), 3, 10)
	for index in rock_count:
		var angle := TAU * float(index) / float(rock_count) + 0.31 * float(index % 2)
		var edge := Vector3(cos(angle) * radius * 0.72 * aspect.x, 1.05, sin(angle) * radius * 0.58 * aspect.y)
		var rock := SphereMesh.new()
		rock.radius = 0.34 + 0.07 * float(index % 3)
		rock.height = 0.52 + 0.11 * float(index % 2)
		island.add_child(mesh_node("ShoreRock_%02d" % index, rock, palette.underside.lightened(0.12), edge, Vector3(1.25, 0.85, 0.9)))
	if radius >= 7.0:
		var landmark := CylinderMesh.new()
		landmark.top_radius = 0.42
		landmark.bottom_radius = 0.75
		landmark.height = 2.2
		island.add_child(mesh_node("LandmarkRock", landmark, palette.underside.lightened(0.08), Vector3(0.0, 2.05, 0.0), Vector3(1.2, 1.0, 1.2)))
		var coastal_anchor := Node3D.new()
		coastal_anchor.name = "M200CoastalAnchor"
		coastal_anchor.set_meta("visual_only", true)
		island.add_child(coastal_anchor)
		var anchor_rock := SphereMesh.new()
		anchor_rock.radius = 0.72
		anchor_rock.height = 1.05
		var anchor_position := Vector3(radius * 0.48 * aspect.x, 1.52, -radius * 0.34 * aspect.y)
		coastal_anchor.add_child(mesh_node("AnchorRock", anchor_rock, palette.underside.lightened(0.10), anchor_position, Vector3(1.35, 0.92, 1.0)))
		var mast := CylinderMesh.new()
		mast.top_radius = 0.055
		mast.bottom_radius = 0.075
		mast.height = 2.6
		coastal_anchor.add_child(mesh_node("NavigationMast", mast, Color("4b2b16"), anchor_position + Vector3(0.0, 1.6, 0.0), Vector3.ONE))



static func apply_sea_monster_visual(ship: Node3D, body_color: Color = Color("285d68")) -> void:
	ship.set_meta("visual_profile", "procedural_monster")
	var visual := ship.get_node_or_null("Visual") as Node3D
	if visual == null:
		return
	for child in visual.get_children():
		if child is MeshInstance3D and child.name != "SelectionRing":
			child.visible = false
	var body_mesh := SphereMesh.new()
	body_mesh.height = 2.2
	body_mesh.radius = 1.1
	visual.add_child(mesh_node("LeviathanBody", body_mesh, body_color, Vector3(0.0, 0.25, 0.0), Vector3(2.0, 0.9, 2.5)))
	var head_mesh := SphereMesh.new()
	head_mesh.height = 1.4
	head_mesh.radius = 0.7
	visual.add_child(mesh_node("LeviathanHead", head_mesh, body_color.lightened(0.08), Vector3(0.0, 0.72, 2.05), Vector3(1.45, 0.95, 1.5)))
	for side in [-1.0, 1.0]:
		for index in 3:
			var tentacle_mesh := CylinderMesh.new()
			tentacle_mesh.top_radius = 0.16
			tentacle_mesh.bottom_radius = 0.34
			tentacle_mesh.height = 3.4 - index * 0.35
			var tentacle := mesh_node("Tentacle", tentacle_mesh, body_color.darkened(0.08), Vector3(side * (1.35 + index * 0.42), -0.05, 0.65 - index * 1.0), Vector3.ONE)
			tentacle.rotation_degrees.z = side * (56.0 + index * 7.0)
			visual.add_child(tentacle)
	var crest_mesh := BoxMesh.new()
	for index in 4:
		visual.add_child(mesh_node("Crest", crest_mesh, body_color.lightened(0.18), Vector3(0.0, 1.28, 1.0 - index * 0.8), Vector3(0.18, 0.65 - index * 0.08, 0.22)))
	# M75 fallback polish: stronger head read, asymmetric fins and emissive eyes.
	var fin_mesh:=PrismMesh.new()
	for side in [-1.0,1.0]:
		var fin:=mesh_node("LeviathanFin",fin_mesh,body_color.darkened(0.14),Vector3(side*1.65,0.25,0.45),Vector3(0.85,0.22,1.35))
		fin.rotation_degrees.z=side*18.0
		visual.add_child(fin)
	var eye_mesh:=SphereMesh.new()
	eye_mesh.radius=0.10
	eye_mesh.height=0.20
	for side in [-1.0,1.0]:
		var eye:=mesh_node("LeviathanEye",eye_mesh,Color("8ff4d6"),Vector3(side*0.46,0.94,2.62),Vector3.ONE)
		var eye_material:=eye.material_override as StandardMaterial3D
		if eye_material!=null:
			eye_material.emission_enabled=true
			eye_material.emission=Color("8ff4d6")
			eye_material.emission_energy_multiplier=1.8
		visual.add_child(eye)
	# M68 visual-only anchors: final GLB may expose equivalent nodes, but combat never depends on them.
	var anchors := ship.get_node_or_null("MonsterVisualAnchors") as Node3D
	if anchors == null:
		anchors = Node3D.new()
		anchors.name = "MonsterVisualAnchors"
		ship.add_child(anchors)
	for anchor_data in [
		["Head", Vector3(0.0, 1.05, 2.35)],
		["HarpoonCenter", Vector3(0.0, 0.35, 0.15)],
		["VfxMouth", Vector3(0.0, 0.82, 2.72)],
		["VfxBody", Vector3(0.0, 0.55, 0.0)],
	]:
		if anchors.get_node_or_null(str(anchor_data[0])) == null:
			var marker := Marker3D.new()
			marker.name = str(anchor_data[0])
			marker.position = anchor_data[1]
			anchors.add_child(marker)
	ship.set_meta("production_slot", "monster_early_01")
	ship.set_meta("m68_monster_visual_ready", true)
	var bounds := AABB(Vector3(-4.4, -1.0, -4.0), Vector3(8.8, 5.2, 8.4))
	ship.set_meta("hud_visual_bounds", bounds)


static func apply_cursed_monster_visual(ship:Node3D,variant:String)->void:
	var body:=Color("35414a") if variant=="ghost_whale" else Color("294f46")
	apply_sea_monster_visual(ship,body)
	ship.set_meta("monster_variant",variant)
	ship.set_meta("production_slot","monster_ghost_whale_01" if variant=="ghost_whale" else "monster_cursed_serpent_01")
	var visual:=ship.get_node_or_null("Visual") as Node3D
	if visual==null:return
	if variant=="ghost_whale":
		# Wide, whale-like fallback silhouette; presentation only.
		for node in visual.get_children():
			if node is MeshInstance3D and str(node.name).begins_with("Tentacle"):node.visible=false
		var back:=SphereMesh.new();back.radius=1.3;back.height=2.4
		visual.add_child(mesh_node("GhostWhaleBack",back,Color("455665"),Vector3(0,0.35,-0.2),Vector3(2.8,0.9,4.0)))
		var tail:=PrismMesh.new()
		for side in [-1.0,1.0]:
			var fin:=mesh_node("GhostTail",tail,Color("33424d"),Vector3(side*1.15,0,-3.0),Vector3(1.5,0.18,1.5))
			fin.rotation_degrees.y=side*28.0;visual.add_child(fin)
		ship.set_meta("hud_visual_bounds",AABB(Vector3(-5.0,-1.0,-5.0),Vector3(10.0,5.0,10.0)))
	else:
		# Long serpent fallback silhouette with staggered body segments.
		for node in visual.get_children():
			if node is MeshInstance3D and str(node.name).begins_with("Tentacle"):node.visible=false
		var segment:=SphereMesh.new();segment.radius=0.65;segment.height=1.25
		for i in range(6):
			var side:=(-1.0 if i%2==0 else 1.0)*0.55
			visual.add_child(mesh_node("SerpentSegment",segment,Color("315d51"),Vector3(side,0.1,-1.2-i*0.9),Vector3(1.2,0.8,1.6)))
		ship.set_meta("hud_visual_bounds",AABB(Vector3(-3.5,-1.0,-7.5),Vector3(7.0,5.0,11.0)))
