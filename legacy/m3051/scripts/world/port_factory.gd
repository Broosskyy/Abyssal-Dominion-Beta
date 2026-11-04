class_name PortFactory
extends RefCounted

const SafeZoneScript = preload("res://scripts/world/safe_zone.gd")
const PortInteractionScript = preload("res://scripts/world/port_interaction.gd")
const ReferencePortAdapterScript = preload("res://scripts/visual/reference_port_adapter.gd")


static func create_port(port_name:String,port_position:Vector3,production_slot:String="")->Node3D:
	var port := Node3D.new()
	port.name = port_name
	port.position = port_position
	port.add_to_group("ports")
	var harbor_id:=port_name.to_lower().replace("'","").replace(" ","_")
	port.set_meta("harbor_id",harbor_id)
	port.set_meta("home_harbor",harbor_id=="havens_reach")
	port.set_meta("guidance_priority",100 if port_name=="Haven's Reach" else 20)
	port.set_meta("production_slot",production_slot)
	port.set_meta("placeholder_replacement_ready",true)
	if not production_slot.is_empty():
		var visual:=AssetVisualLibrary.install(port,production_slot)
		port.set_meta("custom_harbor_visual",visual!=null)

	var dock := StaticBody3D.new()
	dock.name = "Dock"
	port.add_child(dock)
	var dock_mesh := BoxMesh.new()
	dock.add_child(ProceduralFactory.mesh_node("Pier", dock_mesh, Color("6c4a2a"), Vector3(0.0, 0.55, 0.0), Vector3(7.5, 0.35, 2.2)))
	var dock_collision := CollisionShape3D.new()
	var dock_shape := BoxShape3D.new()
	dock_shape.size = Vector3(7.5, 0.7, 2.2)
	dock_collision.shape = dock_shape
	dock_collision.position.y = 0.55
	dock.add_child(dock_collision)

	_create_lighthouse(port, Vector3(-3.0, 1.0, -1.4))
	_create_lighthouse(port, Vector3(3.0, 1.0, -1.4))

	var spawn := Marker3D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector3(0.0, 0.55, 8.0)
	port.add_child(spawn)

	var zone: SafeZone = SafeZoneScript.new()
	zone.name = "SafeZone"
	zone.zone_name = port_name
	zone.spawn_position = port_position + spawn.position
	port.add_child(zone)
	var zone_collision := CollisionShape3D.new()
	var zone_shape := CylinderShape3D.new()
	zone_shape.radius = 10.0
	zone_shape.height = 3.0
	zone_collision.shape = zone_shape
	zone_collision.position = Vector3(0.0, 0.4, 5.0)
	zone.add_child(zone_collision)
	var safe_visual := SafeZoneVisualAdapter.install_if_available(zone, "vfx_safe_zone_ring")
	if safe_visual == null:
		zone.add_child(_safe_zone_ring())
	var beacon_visual := SafeZoneVisualAdapter.install_if_available(zone, "vfx_safe_zone_beacon")
	if beacon_visual == null:
		zone.add_child(_safe_zone_beacon())
	var interaction: PortInteraction = PortInteractionScript.new()
	interaction.name = "PortInteraction"
	interaction.port_name = port_name
	interaction.spawn_position = port_position + spawn.position
	interaction.position = Vector3(0.0, 0.4, 5.0)
	port.add_child(interaction)
	var interaction_collision := CollisionShape3D.new()
	var interaction_shape := CylinderShape3D.new()
	interaction_shape.radius = 7.0
	interaction_shape.height = 3.0
	interaction_collision.shape = interaction_shape
	interaction.add_child(interaction_collision)
	_create_module_socket(port, "WorkshopSocket", "harbor_module_workshop", Vector3(-5.0, 0.2, 2.5), Color("6a5236"))
	_create_module_socket(port, "MerchantSocket", "harbor_module_merchant", Vector3(5.0, 0.2, 2.5), Color("72513d"))
	_create_module_socket(port, "RepairYardSocket", "harbor_module_repair_yard", Vector3(-5.5, 0.2, 7.0), Color("53636c"))
	_create_module_socket(port, "SupportPierSocket", "harbor_module_support_pier", Vector3(5.5, 0.2, 7.0), Color("3d6870"))
	var reference_adapter: ReferencePortAdapter = ReferencePortAdapterScript.new()
	reference_adapter.name = "ReferencePortAdapter"
	port.add_child(reference_adapter)
	var module_adapter := HarborModuleVisualAdapter.new()
	module_adapter.name = "HarborModuleVisualAdapter"
	port.add_child(module_adapter)
	module_adapter.call_deferred("apply_to_port", port)
	HarborContentComposer.apply(port)
	_create_m226_dock_guidance(port)
	_create_m227_service_world_anchors(port)
	if port_name=="Haven's Reach":HavensReachVisualComposer.apply(port)
	return port


static func _create_m226_dock_guidance(port:Node3D)->void:
	# M226: visual-only pier approach read. Collision/navigation remain owned by the existing dock/interaction shapes.
	var root:=Node3D.new()
	root.name="M226DockApproachRead"
	root.set_meta("visual_only",true)
	root.set_meta("master_camera_read","pier_edge_twin_beacons_and_mooring_line")
	port.add_child(root)
	for x in [-3.35,3.35]:
		var beacon:=MeshInstance3D.new()
		beacon.name="ApproachBeacon"
		var mesh:=CylinderMesh.new(); mesh.top_radius=0.14; mesh.bottom_radius=0.20; mesh.height=1.25
		beacon.mesh=mesh; beacon.position=Vector3(x,0.72,5.7)
		beacon.material_override=ProceduralFactory.material(Color("d5b45f"))
		beacon.set_meta("visual_only",true); root.add_child(beacon)
	var lane:=MeshInstance3D.new()
	lane.name="M226ApproachLane"
	var lane_mesh:=BoxMesh.new(); lane_mesh.size=Vector3(5.9,0.035,2.8)
	lane.mesh=lane_mesh; lane.position=Vector3(0,0.08,5.7)
	lane.material_override=ProceduralFactory.material(Color(0.34,0.78,0.88,0.18))
	lane.set_meta("visual_only",true); root.add_child(lane)
	var mooring:=MeshInstance3D.new()
	mooring.name="M226MooringRead"
	var mooring_mesh:=BoxMesh.new(); mooring_mesh.size=Vector3(6.2,0.06,0.16)
	mooring.mesh=mooring_mesh; mooring.position=Vector3(0,0.10,3.95)
	mooring.material_override=ProceduralFactory.material(Color("f1c75b"))
	mooring.set_meta("visual_only",true); root.add_child(mooring)


static func _create_m227_service_world_anchors(port:Node3D)->void:
	# M227: service identity is visual-only. Existing M226 HUD/economy/menu authorities remain unchanged.
	var root:=Node3D.new()
	root.name="M227HarborServiceWorldAnchors"
	root.set_meta("visual_only",true)
	root.set_meta("collision_changed",false)
	root.set_meta("navigation_changed",false)
	port.add_child(root)
	var installed:Array[String]=[]
	for service_id in M227HarborWorldAnchorCatalog.ordered_ids():
		var d:=M227HarborWorldAnchorCatalog.descriptor(service_id)
		var socket:=port.get_node_or_null(str(d.get("socket",""))) as Node3D
		if socket==null: continue
		socket.set_meta("harbor_service_id",service_id)
		socket.set_meta("m227_world_anchor_slot",str(d.get("slot","")))
		var anchor:=Node3D.new()
		anchor.name="M227_%s" % service_id.capitalize()
		anchor.position=socket.position+Vector3(0,0.02,0)
		anchor.set_meta("harbor_service_id",service_id)
		anchor.set_meta("production_slot",str(d.get("slot","")))
		anchor.set_meta("placeholder_replacement_ready",true)
		anchor.set_meta("visual_only",true)
		root.add_child(anchor)
		_add_m227_service_silhouette(anchor,str(d.get("shape","gantry")),d.get("accent",Color.WHITE))
		installed.append(service_id)
	port.set_meta("m227_service_anchor_ids",installed)


static func _add_m227_service_silhouette(parent:Node3D, shape_id:String, accent:Color)->void:
	# Forms differ before color so the four services remain readable in the high/wide master camera.
	match shape_id:
		"awning":
			_add_m227_box(parent,"Canopy",Vector3(2.9,0.16,2.2),Vector3(0,2.05,0),accent)
			_add_m227_box(parent,"PostL",Vector3(0.14,1.8,0.14),Vector3(-1.15,1.05,0),Color("6b5237"))
			_add_m227_box(parent,"PostR",Vector3(0.14,1.8,0.14),Vector3(1.15,1.05,0),Color("6b5237"))
		"repair_frame":
			_add_m227_box(parent,"FrameL",Vector3(0.22,2.6,0.22),Vector3(-1.15,1.35,0),accent)
			_add_m227_box(parent,"FrameR",Vector3(0.22,2.6,0.22),Vector3(1.15,1.35,0),accent)
			_add_m227_box(parent,"FrameTop",Vector3(2.55,0.20,0.28),Vector3(0,2.58,0),accent)
		"battery":
			for x in [-0.72,0.0,0.72]:
				var barrel:=MeshInstance3D.new()
				barrel.name="BatteryBarrel"
				var mesh:=CylinderMesh.new(); mesh.top_radius=0.16; mesh.bottom_radius=0.20; mesh.height=1.5
				barrel.mesh=mesh; barrel.position=Vector3(x,1.0,0); barrel.rotation_degrees.z=90.0
				barrel.material_override=ProceduralFactory.material(accent); barrel.set_meta("visual_only",true); parent.add_child(barrel)
		_:
			_add_m227_box(parent,"GantryL",Vector3(0.22,2.7,0.22),Vector3(-1.0,1.4,0),Color("745234"))
			_add_m227_box(parent,"GantryR",Vector3(0.22,2.7,0.22),Vector3(1.0,1.4,0),Color("745234"))
			_add_m227_box(parent,"GantryBeam",Vector3(2.4,0.22,0.26),Vector3(0,2.62,0),accent)
			_add_m227_box(parent,"CraneArm",Vector3(1.5,0.14,0.18),Vector3(0.55,3.0,0),accent)


static func _add_m227_box(parent:Node3D,node_name:String,size:Vector3,pos:Vector3,color:Color)->void:
	var node:=MeshInstance3D.new()
	node.name=node_name
	var mesh:=BoxMesh.new(); mesh.size=size
	node.mesh=mesh; node.position=pos; node.material_override=ProceduralFactory.material(color)
	node.set_meta("visual_only",true); parent.add_child(node)


static func _create_module_socket(parent: Node3D, node_name: String, stable_slot: String, local_position: Vector3, color: Color) -> void:
	var socket := Marker3D.new()
	socket.name = node_name
	socket.position = local_position
	socket.set_meta("production_slot", stable_slot)
	socket.set_meta("placeholder_replacement_ready", true)
	parent.add_child(socket)
	var placeholder := MeshInstance3D.new()
	placeholder.name = "Placeholder"
	var box := BoxMesh.new()
	box.size = Vector3(2.4, 1.4, 2.0)
	placeholder.mesh = box
	placeholder.position = Vector3(0, 0.7, 0)
	placeholder.material_override = ProceduralFactory.material(color)
	socket.add_child(placeholder)
	# M201 reference-grade placeholder: stronger harbor silhouette without changing interaction/collision.
	var roof := MeshInstance3D.new()
	roof.name = "M201Roof"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(2.75, 0.18, 2.25)
	roof.mesh = roof_mesh
	roof.position = Vector3(0, 1.48, 0)
	roof.material_override = ProceduralFactory.material(Color("263444"))
	roof.set_meta("visual_only", true)
	socket.add_child(roof)
	var accent := MeshInstance3D.new()
	accent.name = "M201GoldAccent"
	var accent_mesh := BoxMesh.new()
	accent_mesh.size = Vector3(1.45, 0.10, 0.12)
	accent.mesh = accent_mesh
	accent.position = Vector3(0, 1.15, 1.04)
	accent.material_override = ProceduralFactory.material(Color("d2ad58"), 0.42, 0.08)
	accent.set_meta("visual_only", true)
	socket.add_child(accent)


static func _create_lighthouse(parent: Node3D, local_position: Vector3) -> void:
	var tower_mesh := CylinderMesh.new()
	tower_mesh.top_radius = 0.42
	tower_mesh.bottom_radius = 0.68
	tower_mesh.height = 3.6
	parent.add_child(ProceduralFactory.mesh_node("Lighthouse", tower_mesh, Color("e8dfc6"), local_position + Vector3.UP * 1.8, Vector3.ONE))
	var light := OmniLight3D.new()
	light.name = "HarborLight"
	light.position = local_position + Vector3.UP * 3.7
	light.light_color = Color("ffd267")
	light.light_energy = 1.8
	light.omni_range = 7.0
	light.shadow_enabled = false
	parent.add_child(light)



static func _safe_zone_beacon() -> Node3D:
	var root := Node3D.new()
	root.name = "SafeZoneBeacon"
	root.position = Vector3(0.0, 0.05, 5.0)
	var column := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.18
	mesh.height = 2.6
	column.mesh = mesh
	column.position.y = 1.3
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.26, 0.86, 0.68, 0.18)
	mat.emission_enabled = true
	mat.emission = Color("4bd7a8")
	mat.emission_energy_multiplier = 0.55
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	column.material_override = mat
	column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(column)
	return root

static func _safe_zone_ring() -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	ring.name = "SafeZoneRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 9.65
	torus.outer_radius = 10.0
	ring.mesh = torus
	ring.position = Vector3(0.0, 0.04, 5.0)
	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.18, 0.82, 0.62, 0.24)
	ring_material.emission_enabled = true
	ring_material.emission = Color("27c981")
	ring_material.emission_energy_multiplier = 0.82
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = ring_material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ring
