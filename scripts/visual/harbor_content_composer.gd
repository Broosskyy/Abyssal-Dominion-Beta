class_name HarborContentComposer
extends RefCounted
const PATH := "res://data/m71_havens_reach_composition.json"

static func apply(port: Node3D) -> void:
	if port == null:
		return
	var harbor_id:=str(port.get_meta("harbor_id",""))
	if harbor_id.is_empty():
		harbor_id=str(port.name).to_lower().replace("'","").replace(" ","_")
	if harbor_id not in ["havens_reach","havens_reach_harbor"]:
		return
	var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary: return
	var old:=port.get_node_or_null("M71HarborContent")
	if old != null: old.queue_free()
	var root:=Node3D.new()
	root.name="M71HarborContent"
	root.set_meta("classification","REPLACEABLE_VISUAL_COMPOSITION")
	root.set_meta("harbor_id",harbor_id)
	root.set_meta("milestone","M97")
	port.add_child(root)
	for row in parsed.get("modules",[]):
		var d:Dictionary=row
		var socket:=Node3D.new()
		socket.name="Slot_"+str(d.get("slot",""))
		var pos:Array=d.get("position",[0,0,0])
		socket.position=Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
		socket.rotation_degrees.y=float(d.get("yaw",0))
		socket.scale=Vector3.ONE*float(d.get("scale",1.0))
		socket.set_meta("production_slot",str(d.get("slot","")))
		socket.set_meta("visual_tier",str(d.get("visual_tier","dressing")))
		root.add_child(socket)
		var visual:=AssetVisualLibrary.install(socket,str(d.get("slot","")))
		if visual == null:
			_add_fallback(socket,str(d.get("slot","")))
	HarborVisualBudget.apply(root,port)

static func _add_fallback(parent: Node3D, slot: String) -> void:
	var mesh_node:=MeshInstance3D.new()
	mesh_node.name="Fallback"
	var size:=Vector3(1.4,1.0,1.4)
	if slot=="prop_dock_wood_01": size=Vector3(6.0,0.28,1.5)
	elif slot=="prop_lighthouse_01": size=Vector3(1.0,4.2,1.0)
	elif slot=="prop_warehouse_01": size=Vector3(3.4,2.0,2.6)
	elif slot=="prop_market_stall_01": size=Vector3(2.2,1.5,1.8)
	elif slot=="prop_quest_board_01": size=Vector3(1.4,1.6,0.25)
	elif slot=="prop_crate_stack_01": size=Vector3(1.6,1.1,1.4)
	elif slot=="prop_buoy_navigation_01": size=Vector3(0.45,1.0,0.45)
	elif slot=="prop_harbor_crane_01": size=Vector3(1.6,3.2,1.0)
	elif slot=="prop_rope_bundle_01": size=Vector3(0.8,0.35,0.8)
	elif slot=="prop_fish_crates_01": size=Vector3(1.6,0.9,1.2)
	elif slot=="prop_harbor_wayfinder_01": size=Vector3(0.35,1.8,0.35)
	elif slot=="prop_salvage_hook_01": size=Vector3(0.45,1.6,0.45)
	elif slot=="prop_harbor_net_rack_01": size=Vector3(1.8,1.4,0.55)
	elif slot=="prop_harbor_lantern_post_01": size=Vector3(0.28,2.1,0.28)
	elif slot=="prop_harbor_signpost_01": size=Vector3(0.35,1.8,0.35)
	elif slot=="prop_harbor_canvas_awning_01": size=Vector3(2.4,1.5,1.8)
	elif slot=="prop_harbor_mooring_post_01": size=Vector3(0.32,0.85,0.32)
	elif slot=="prop_harbor_bell_01": size=Vector3(0.75,1.45,0.75)
	elif slot=="prop_harbor_barrel_rack_01": size=Vector3(1.4,0.8,0.75)
	elif slot=="prop_harbor_small_boat_01": size=Vector3(2.6,0.55,1.0)
	elif slot=="prop_harbor_sailcloth_bundle_01": size=Vector3(1.25,0.45,0.8)
	elif slot=="prop_harbor_cart_01": size=Vector3(1.8,0.8,1.0)
	elif slot=="prop_harbor_dock_stairs_01": size=Vector3(1.65,0.35,1.1)
	elif slot=="prop_harbor_fish_drying_rack_01": size=Vector3(1.45,1.1,0.55)
	elif slot=="prop_harbor_pirate_arch_01": size=Vector3(2.4,1.9,0.42)
	elif slot=="prop_harbor_hanging_net_01": size=Vector3(1.6,1.05,0.16)
	elif slot=="prop_harbor_pirate_sign_01": size=Vector3(1.05,1.55,0.18)
	elif slot=="prop_harbor_rope_gantry_01": size=Vector3(2.1,1.65,0.42)
	elif slot=="prop_harbor_pirate_lantern_02": size=Vector3(0.34,2.25,0.34)
	elif slot=="prop_harbor_skull_sign_01": size=Vector3(0.52,1.72,0.28)
	elif slot=="prop_harbor_pirate_rope_post_01": size=Vector3(0.42,1.15,0.42)
	mesh_node.mesh=FallbackPrimitiveLibrary.box(size)
	mesh_node.position.y=size.y*0.5
	mesh_node.material_override=EnvironmentMaterialCatalog.harbor_wood() if slot in ["prop_dock_wood_01","prop_market_stall_01","prop_quest_board_01","prop_crate_stack_01","prop_harbor_crane_01","prop_rope_bundle_01","prop_fish_crates_01","prop_harbor_wayfinder_01","prop_salvage_hook_01","prop_harbor_net_rack_01","prop_harbor_lantern_post_01","prop_harbor_signpost_01","prop_harbor_mooring_post_01","prop_harbor_bell_01","prop_harbor_barrel_rack_01","prop_harbor_small_boat_01","prop_harbor_sailcloth_bundle_01","prop_harbor_cart_01","prop_harbor_dock_stairs_01","prop_harbor_fish_drying_rack_01","prop_harbor_pirate_arch_01","prop_harbor_hanging_net_01","prop_harbor_pirate_sign_01","prop_harbor_rope_gantry_01","prop_harbor_pirate_lantern_02","prop_harbor_skull_sign_01","prop_harbor_pirate_rope_post_01"] else EnvironmentMaterialCatalog.harbor_stone()
	parent.add_child(mesh_node)
