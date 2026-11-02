class_name MonsterAreaDressing
extends RefCounted

static func decorate(poi:Node3D,kind:String)->void:
	if poi==null or kind not in ["monster_warning","monster_nest"]:return
	var root:=Node3D.new()
	root.name="M79MonsterAreaDressing"
	root.set_meta("visual_only",true)
	root.set_meta("batch_candidate",true)
	poi.add_child(root)
	var slots:=["prop_monster_hunter_buoy_01","prop_monster_hunter_totem_01"] if kind=="monster_warning" else ["prop_monster_bone_arch_01","nature_reef_marker_01","prop_monster_bones_01"]
	var count:=2 if kind=="monster_warning" else 3
	for i in count:
		var socket:=Node3D.new()
		socket.name="Context_%02d"%i
		var angle:=TAU*float(i)/float(maxi(1,count))+0.4
		socket.position=Vector3(cos(angle)*(1.6+i*0.25),0.05,sin(angle)*(1.6+i*0.25))
		socket.rotation.y=angle
		socket.scale=Vector3.ONE*(0.85+0.08*i)
		var slot:=str(slots[i%slots.size()])
		socket.set_meta("production_slot",slot)
		socket.set_meta("visual_only",true)
		root.add_child(socket)
		if AssetVisualLibrary.install(socket,slot)==null:
			_fallback(socket,slot)
	MobilePresentationBudget.apply_geometry_visibility(root,38.0,4.0)

static func _fallback(parent:Node3D,slot:String)->void:
	var node:=MeshInstance3D.new()
	node.name="Fallback"
	if slot in ["nature_reef_marker_01","nature_foam_reef_line_01"]:
		node.mesh=FallbackPrimitiveLibrary.sphere(0.45,0.65)
		node.scale=Vector3(1.5,0.45,0.85)
		node.material_override=EnvironmentMaterialCatalog.rock()
	elif slot in ["prop_monster_warning_flag_01","prop_monster_harpoon_post_01"]:
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(0.12,1.7,0.8))
		node.position.y=0.85
		node.rotation_degrees.z=8.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_monster_hunter_buoy_01":
		node.mesh=FallbackPrimitiveLibrary.cylinder(0.18,0.28,1.1);node.position.y=0.42;node.material_override=EnvironmentMaterialCatalog.harbor_wood()
		node.set_meta("teaching_landmark",true);node.set_meta("target_authority",false);node.set_meta("reward_authority",false)
	elif slot=="prop_monster_hunter_totem_01":
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(0.34,1.35,0.34))
		node.position.y=0.68
		node.rotation_degrees.y=-12.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
		node.set_meta("teaching_landmark",true)
		node.set_meta("target_authority",false)
		node.set_meta("reward_authority",false)
	elif slot=="prop_monster_bone_arch_01":
		node.mesh=FallbackPrimitiveLibrary.torus(0.52,0.72)
		node.position.y=0.58
		node.rotation_degrees=Vector3(90,0,18)
		node.material_override=EnvironmentMaterialCatalog.bone()
	elif slot=="prop_monster_hunter_banner_01":
		node.mesh=FallbackPrimitiveLibrary.quad(Vector2(0.92,0.72))
		node.position.y=0.88
		node.rotation_degrees.y=-16.0
		var banner_mat:=StandardMaterial3D.new()
		banner_mat.albedo_color=Color("8a4f2d")
		banner_mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		banner_mat.roughness=0.88
		node.material_override=banner_mat
		node.set_meta("teaching_landmark",true)
		node.set_meta("target_authority",false)
		node.set_meta("reward_authority",false)
	elif slot=="prop_monster_harpoon_rack_01":
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(0.95,0.65,0.35))
		node.position.y=0.32
		node.rotation_degrees.y=18.0
		node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	elif slot=="prop_monster_bone_spine_01":
		node.mesh=FallbackPrimitiveLibrary.torus(0.32,0.40)
		node.scale=Vector3(1.8,0.42,0.75)
		node.rotation_degrees.z=64.0
		node.material_override=EnvironmentMaterialCatalog.harbor_stone()
	elif slot=="prop_monster_warning_chain_01":
		node.mesh=FallbackPrimitiveLibrary.torus(0.28,0.36)
		node.scale=Vector3(1.6,0.25,0.7)
		node.rotation_degrees.z=72.0
		node.material_override=EnvironmentMaterialCatalog.harbor_stone()
	else:
		node.mesh=FallbackPrimitiveLibrary.torus(0.34,0.42)
		node.scale=Vector3(1.25,0.45,0.8)
		node.rotation_degrees.z=68.0
		node.material_override=EnvironmentMaterialCatalog.harbor_stone()
	parent.add_child(node)
