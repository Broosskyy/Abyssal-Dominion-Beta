class_name ShallowCoastDressing
extends RefCounted
## Visual-only coastline readability layer. No collision/navigation authority.
## M191 keeps the coast readable from the gameplay camera without turning every island into a bright ring.

static func decorate(island:Node3D,quality:String)->void:
	if island==null:return
	var radius:=float(island.get_meta("island_radius",5.0))
	var root:=Node3D.new()
	root.name="M82ShallowCoast"
	root.set_meta("visual_only",true)
	root.set_meta("batch_candidate",true)
	root.set_meta("m191_coast_readability",true)
	island.add_child(root)
	_add_shallow_shelf(root,radius)
	var slots:=["nature_coast_cliff_spur_01","nature_foam_reef_line_01","nature_coast_tidepool_01"]
	var count:=1 if quality=="low" else (2 if quality=="balanced" else 3)
	for i in range(count):
		var socket:=Node3D.new()
		socket.name="Coast_%02d"%i
		var angle:=0.72+float(i)*TAU/float(maxi(count,1))
		socket.position=Vector3(cos(angle)*radius*0.93,0.04,sin(angle)*radius*0.93)
		socket.rotation.y=angle
		var slot:=str(slots[i%slots.size()])
		socket.set_meta("production_slot",slot)
		socket.set_meta("visual_only",true)
		root.add_child(socket)
		if AssetVisualLibrary.install(socket,slot)==null:
			var node:=MeshInstance3D.new()
			node.name="Fallback"
			if slot=="nature_coast_tidepool_01":
				node.mesh=FallbackPrimitiveLibrary.torus(0.30,0.42)
				node.scale=Vector3(1.8,0.16,1.0)
			else:
				node.mesh=FallbackPrimitiveLibrary.sphere(0.45,0.55)
				node.scale=Vector3(1.8,0.3,0.7)
			node.material_override=EnvironmentMaterialCatalog.rock()
			socket.add_child(node)
	MobilePresentationBudget.apply_geometry_visibility(root,42.0,4.0)

static func _add_shallow_shelf(root:Node3D,radius:float)->void:
	var shelf:=MeshInstance3D.new()
	shelf.name="M191ShallowWaterShelf"
	var mesh:=CylinderMesh.new()
	mesh.top_radius=1.0
	mesh.bottom_radius=1.0
	mesh.height=0.025
	shelf.mesh=mesh
	shelf.position.y=-0.10
	shelf.scale=Vector3(radius*1.08,1.0,radius*0.92)
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(0.26,0.66,0.70,0.13)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	shelf.material_override=material
	shelf.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shelf.set_meta("visual_only",true)
	root.add_child(shelf)
