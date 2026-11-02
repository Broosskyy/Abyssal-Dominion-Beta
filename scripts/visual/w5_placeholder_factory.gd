class_name W5PlaceholderFactory
extends RefCounted

static func create(entry: Dictionary, lod: int = 0) -> Node3D:
	var root := LateFleetSilhouetteFactory.create(entry)
	if root == null: return null
	root.name = str(entry.get("id", "W5Ship"))
	root.set_meta("classification", "M153_W5_CLEAN_ROOM_GLB_PLACEHOLDER")
	root.set_meta("counts_as_final_glb", false)
	root.set_meta("lod", lod)
	var class_number := int(entry.get("class_number", 51))
	_apply_macro_shape(root, class_number, entry)
	_add_identity_geometry(root, class_number, entry, lod)
	_add_sockets(root, entry)
	_apply_lod(root, lod)
	return root

static func _apply_macro_shape(root: Node3D, class_number: int, entry: Dictionary) -> void:
	var variant := class_number - 50
	var family := str(entry.get("family", ""))
	if family == "dread_cutter":
		var widths := [0.76,0.88,0.82,1.12,0.94]
		var lengths := [1.22,1.08,1.16,1.02,1.12]
		root.scale = Vector3(widths[(variant-1)%5], 0.88 + 0.04 * ((variant-1)%3), lengths[(variant-1)%5])
	else:
		var widths := [1.04,0.92,1.14,1.25,1.08]
		var heights := [0.94,1.18,0.88,0.82,1.12]
		root.scale = Vector3(widths[(variant-6)%5], heights[(variant-6)%5], 0.94 + 0.05 * ((variant-6)%3))

static func _add_identity_geometry(root: Node3D, class_number: int, entry: Dictionary, lod: int) -> void:
	var recipe := entry.get("recipe", {}) as Dictionary
	var length := float(recipe.get("length", 6.0)); var width := float(recipe.get("width", 2.0)); var height := float(recipe.get("height", 1.0))
	var dark := _material(Color("26323a"), 0.48, 0.68)
	var accent := _material(_accent(class_number), 0.38, 0.34, true)
	match class_number:
		51:
			_box(root,"LongSpearProw",Vector3(width*0.12,height*0.16,length*0.92),Vector3(0,0.06,-length*0.72),dark,Vector3(deg_to_rad(-7),0,0))
		52:
			_box(root,"PortHook",Vector3(width*0.13,height*0.18,length*0.54),Vector3(-width*0.26,0.08,-length*0.64),dark,Vector3(0,deg_to_rad(-12),0))
			_box(root,"StarboardHook",Vector3(width*0.13,height*0.18,length*0.54),Vector3(width*0.26,0.08,-length*0.64),dark,Vector3(0,deg_to_rad(12),0))
		53:
			_box(root,"AsymmetricPortBlade",Vector3(width*0.08,height*0.14,length*0.76),Vector3(-width*0.68,0.14,-length*0.18),accent,Vector3(0,deg_to_rad(-16),0))
		54:
			_box(root,"PortOutrigger",Vector3(width*0.24,height*0.18,length*0.62),Vector3(-width*0.82,-height*0.04,0),dark)
			_box(root,"StarboardOutrigger",Vector3(width*0.24,height*0.18,length*0.62),Vector3(width*0.82,-height*0.04,0),dark)
		55:
			_ring(root,"OpenCrescentProw",width*0.44,Vector3(0,height*0.34,-length*0.54),accent)
		56:
			for side in [-1,1]:
				for rib in range(4 if lod==0 else 2): _box(root,"ArmorRib_%s_%d"%[side,rib],Vector3(width*0.10,height*0.72,length*0.08),Vector3(side*width*0.55,height*0.10,(rib-1.5)*length*0.18),dark)
		57:
			_box(root,"SternTower",Vector3(width*0.62,height*1.65,length*0.24),Vector3(0,height*1.18,length*0.38),dark)
			_box(root,"TowerCap",Vector3(width*0.88,height*0.16,length*0.34),Vector3(0,height*2.02,length*0.38),accent)
		58:
			_box(root,"WedgeRam",Vector3(width*0.78,height*0.62,length*0.52),Vector3(0,-height*0.02,-length*0.64),dark,Vector3(0,deg_to_rad(45),0))
		59:
			_box(root,"MortarTerrace",Vector3(width*0.82,height*0.28,length*0.48),Vector3(0,height*1.02,0),dark)
			for x in [-0.24,0.24]: _cylinder(root,"Mortar_%s"%x,width*0.12,height*0.42,Vector3(x*width,height*1.34,0),accent,Vector3(deg_to_rad(18),0,0))
		60:
			_box(root,"LowerGallery",Vector3(width*0.92,height*0.34,length*0.30),Vector3(0,height*0.88,length*0.40),dark)
			_box(root,"UpperGallery",Vector3(width*0.68,height*0.42,length*0.22),Vector3(0,height*1.28,length*0.43),accent)
			_box(root,"CrownSpire",Vector3(width*0.14,height*1.32,length*0.12),Vector3(0,height*1.78,length*0.34),accent)

static func _add_sockets(root: Node3D, entry: Dictionary) -> void:
	var recipe := entry.get("recipe", {}) as Dictionary
	var length := float(recipe.get("length", 6.0)); var width := float(recipe.get("width", 2.0)); var height := float(recipe.get("height", 1.0))
	var sockets := {
		"WeaponPort_P0":Vector3(-width*0.58,height*0.34,-length*0.18), "WeaponPort_P1":Vector3(-width*0.58,height*0.34,length*0.18),
		"WeaponPort_S0":Vector3(width*0.58,height*0.34,-length*0.18), "WeaponPort_S1":Vector3(width*0.58,height*0.34,length*0.18),
		"BowWeaponSocket":Vector3(0,height*0.36,-length*0.64), "MastSocket_0":Vector3(0,height*0.78,-length*0.16),
		"MastSocket_1":Vector3(0,height*0.78,length*0.18), "SailSocket_0":Vector3(0,height*1.72,-length*0.16),
		"WakeAnchor":Vector3(0,0,length*0.58), "NameplateAnchor":Vector3(0,height*3.10,0)
	}
	for socket_name in sockets:
		var socket := Node3D.new(); socket.name = socket_name; socket.position = sockets[socket_name]; root.add_child(socket)

static func _apply_lod(root: Node3D, lod: int) -> void:
	if lod <= 0: return
	for child in root.get_children():
		var name_value := str(child.name)
		if lod >= 1 and ("Gun_" in name_value and (name_value.ends_with("_1") or name_value.ends_with("_3"))): child.free()
		elif lod >= 2 and ("Gun_" in name_value or "ArmorRib" in name_value or "Mortar_" in name_value or name_value.begins_with("Deck_1")): child.free()
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.mesh is CylinderMesh: (instance.mesh as CylinderMesh).radial_segments = 6 if lod == 1 else 5

static func _box(parent:Node3D,name_value:String,size:Vector3,position:Vector3,material:Material,rotation:Vector3=Vector3.ZERO)->void:
	var node:=MeshInstance3D.new();node.name=name_value;var mesh:=BoxMesh.new();mesh.size=size;node.mesh=mesh;node.position=position;node.rotation=rotation;node.material_override=material;parent.add_child(node)

static func _cylinder(parent:Node3D,name_value:String,radius:float,height:float,position:Vector3,material:Material,rotation:Vector3=Vector3.ZERO)->void:
	var node:=MeshInstance3D.new();node.name=name_value;var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius*1.18;mesh.height=height;mesh.radial_segments=8;node.mesh=mesh;node.position=position;node.rotation=rotation;node.material_override=material;parent.add_child(node)

static func _ring(parent:Node3D,name_value:String,radius:float,position:Vector3,material:Material)->void:
	var node:=MeshInstance3D.new();node.name=name_value;var mesh:=TorusMesh.new();mesh.inner_radius=radius*0.68;mesh.outer_radius=radius;mesh.rings=16;mesh.ring_segments=8;node.mesh=mesh;node.position=position;node.rotation_degrees.x=90;node.material_override=material;parent.add_child(node)

static func _material(color:Color,roughness:float,metallic:float,emission:bool=false)->StandardMaterial3D:
	var result:=StandardMaterial3D.new();result.albedo_color=color;result.roughness=roughness;result.metallic=metallic
	if emission:result.emission_enabled=true;result.emission=color;result.emission_energy_multiplier=0.32
	return result

static func _accent(class_number:int)->Color:
	return [Color("d1603d"),Color("c49b51"),Color("60b7be"),Color("8a667d"),Color("5ac3ad"),Color("a44737"),Color("d0874c"),Color("bd6046"),Color("788c9b"),Color("c0a45e")][clampi(class_number-51,0,9)]
