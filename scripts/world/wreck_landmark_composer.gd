class_name WreckLandmarkComposer
extends RefCounted
## M80 visual-only wreck silhouette. It never grants loot or quest credit.

static func decorate(poi:Node3D,kind:String)->void:
	if poi==null or kind not in ["wreck","wreck_beacon"]:return
	var root:=Node3D.new()
	root.name="M80WreckLandmark"
	root.set_meta("visual_only",true)
	root.set_meta("batch_candidate",true)
	poi.add_child(root)
	var slots:=["prop_wreck_broken_deck_01","prop_wreck_sunken_cannon_01","prop_wreck_half_mast_01"] if kind=="wreck" else ["prop_wreck_hull_section_01","prop_wreck_lantern_01","prop_wreck_anchor_chain_01"]
	var count:=3
	for i in range(count):
		var socket:=Node3D.new()
		socket.name="Wreck_%02d"%i
		var angle:=0.45+float(i)*1.22
		socket.position=Vector3(cos(angle)*(0.7+0.24*i),0.04,sin(angle)*(0.7+0.24*i))
		socket.rotation.y=angle
		socket.scale=Vector3.ONE*(0.9+0.06*i)
		var slot:=str(slots[i%slots.size()])
		socket.set_meta("production_slot",slot)
		socket.set_meta("visual_only",true)
		root.add_child(socket)
		if AssetVisualLibrary.install(socket,slot)==null:
			_fallback(socket,slot,i)
	MobilePresentationBudget.apply_geometry_visibility(root,38.0,4.0)

static func _fallback(parent:Node3D,slot:String,index:int)->void:
	var node:=MeshInstance3D.new()
	node.name="Fallback"
	if slot in ["prop_wreck_hull_section_01","prop_wreck_keel_section_01"]:
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(1.35,0.28,0.55))
		node.rotation_degrees.y=12.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_rudder_01":
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(0.18,0.75,0.5))
		node.rotation_degrees.z=18.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_mast_broken_02":
		node.mesh=FallbackPrimitiveLibrary.cylinder(0.08,0.12,1.5)
		node.rotation_degrees.z=24.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_rope_tangle_01":
		node.mesh=FallbackPrimitiveLibrary.torus(0.24,0.31)
		node.scale=Vector3(1.1,0.35,0.85)
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_broken_deck_01":
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(1.55,0.18,1.15))
		node.position.y=0.18
		node.rotation_degrees.y=-22.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_sunken_cannon_01":
		node.mesh=FallbackPrimitiveLibrary.cylinder(0.13,0.18,1.15)
		node.position=Vector3(0,0.18,0)
		node.rotation_degrees=Vector3(0,18,82)
		node.material_override=EnvironmentMaterialCatalog.harbor_stone()
	elif slot=="prop_wreck_stern_gallery_01":
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(1.25,0.72,0.42))
		node.position.y=0.34
		node.rotation_degrees.y=-16.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_half_mast_01":
		node.mesh=FallbackPrimitiveLibrary.cylinder(0.07,0.11,1.65)
		node.position.y=0.55
		node.rotation_degrees.z=24.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_torn_flag_01":
		node.mesh=FallbackPrimitiveLibrary.quad(Vector2(0.82,0.46))
		node.position.y=0.72
		node.rotation_degrees.y=22.0
		var flag_mat:=StandardMaterial3D.new()
		flag_mat.albedo_color=Color("6a3028")
		flag_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		flag_mat.roughness=0.9
		node.material_override=flag_mat
	elif slot=="prop_wreck_spar_cluster_01":
		node.mesh=FallbackPrimitiveLibrary.cylinder(0.08,0.11,1.8);node.rotation_degrees.z=68.0;node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_bow_ornament_01":
		node.mesh=FallbackPrimitiveLibrary.sphere(0.22,0.52);node.scale=Vector3(0.7,1.35,0.7);node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_wreck_lantern_01":
		node.mesh=FallbackPrimitiveLibrary.sphere(0.10,0.18)
		var glow:=StandardMaterial3D.new()
		glow.albedo_color=Color("c8933f")
		glow.emission_enabled=true
		glow.emission=Color("c8933f")
		glow.emission_energy_multiplier=1.2
		node.material_override=glow
	elif slot=="prop_wreck_cannon_01":
		node.mesh=FallbackPrimitiveLibrary.cylinder(0.10,0.16,0.9)
		node.rotation_degrees.z=88.0
		node.material_override=EnvironmentMaterialCatalog.harbor_stone()
	elif slot=="prop_wreck_anchor_chain_01":
		node.mesh=FallbackPrimitiveLibrary.torus(0.25,0.32)
		node.scale=Vector3(1.1,0.35,0.8)
		node.material_override=EnvironmentMaterialCatalog.harbor_stone()
	elif slot=="prop_wreck_sail_torn_01":
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(0.08,1.1,0.9))
		node.rotation_degrees.z=18.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	else:
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(0.55,0.16,0.36))
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	node.position.y=0.16+0.03*index
	parent.add_child(node)
