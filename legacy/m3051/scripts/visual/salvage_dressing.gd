class_name SalvageDressing
extends RefCounted
static func decorate(root:Node3D,tier:String)->void:
	if root==null:return
	var count:=1 if tier in ["common","uncommon"] else (2 if tier in ["rare","epic"] else 3)
	var debris:=Node3D.new()
	debris.name="M76SalvageDressing"
	debris.set_meta("visual_only",true)
	root.add_child(debris)
	for i in count:
		var socket:=Node3D.new()
		socket.name="Debris_%02d"%i
		var angle:=TAU*float(i)/float(maxi(count,1))+0.55
		socket.position=Vector3(cos(angle)*0.75,0.06,sin(angle)*0.75)
		socket.rotation.y=angle
		debris.add_child(socket)
		var salvage_slots:=["prop_loot_float_debris_01","prop_wreck_plank_cluster_01","prop_floating_barrel_01","prop_salvage_hook_01"]
		var slot:=str(salvage_slots[i%salvage_slots.size()])
		socket.set_meta("production_slot",slot)
		socket.set_meta("visual_only",true)
		if AssetVisualLibrary.install(socket,slot)==null:
			var mesh_node:=MeshInstance3D.new()
			var fallback_size:=Vector3(0.55,0.08,0.16) if i%2==0 else Vector3(0.75,0.07,0.12)
			if slot=="prop_floating_barrel_01":
				fallback_size=Vector3(0.38,0.22,0.38)
			elif slot=="prop_salvage_hook_01":
				fallback_size=Vector3(0.18,0.55,0.18)
			mesh_node.mesh=FallbackPrimitiveLibrary.box(fallback_size)
			mesh_node.material_override=EnvironmentMaterialCatalog.harbor_wood()
			socket.add_child(mesh_node)
