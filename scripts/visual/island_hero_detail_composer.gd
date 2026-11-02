class_name IslandHeroDetailComposer
extends RefCounted
## M90-fixed one-slot silhouette accent for P0 procedural islands. Visual only.

const PROFILE_SLOT={
	"cliff_cove":"nature_island_small_cliff_01",
	"thin_spit":"nature_island_long_hook_01",
	"long_shoal":"nature_island_split_rock_01"
}

static func apply(island:Node3D,profile_id:String)->void:
	if profile_id not in PROFILE_SLOT:return
	var old:=island.get_node_or_null("M88HeroDetail")
	if old!=null:old.queue_free()
	var root:=Node3D.new()
	root.name="M88HeroDetail"
	root.set_meta("visual_only",true)
	root.set_meta("context_cap",1)
	island.add_child(root)
	var slot:=str(PROFILE_SLOT[profile_id])
	var socket:=Node3D.new()
	socket.name="Slot_"+slot
	socket.set_meta("production_slot",slot)
	root.add_child(socket)
	var visual:=AssetVisualLibrary.install(socket,slot)
	if visual==null:_fallback(socket,slot)
	var radius:=float(island.get_meta("island_radius",5.0))
	match profile_id:
		"cliff_cove":
			socket.position=Vector3(-radius*0.42,0.78,radius*0.30)
			socket.rotation_degrees.y=-18.0
			socket.scale=Vector3.ONE*maxf(0.75,radius*0.18)
		"thin_spit":
			socket.position=Vector3(radius*0.64,0.34,-radius*0.10)
			socket.rotation_degrees.y=31.0
			socket.scale=Vector3.ONE*maxf(0.65,radius*0.15)
		"long_shoal":
			socket.position=Vector3(-radius*0.60,0.42,radius*0.16)
			socket.rotation_degrees.y=-22.0
			socket.scale=Vector3.ONE*maxf(0.68,radius*0.16)

static func _fallback(parent:Node3D,slot:String)->void:
	var node:=MeshInstance3D.new()
	node.name=slot+"_Fallback"
	if slot in ["nature_island_cliff_face_01","nature_island_cliff_bridge_01","nature_island_small_cliff_01"]:
		node.mesh=FallbackPrimitiveLibrary.box(Vector3(2.35,1.35,0.68))
		node.rotation_degrees.z=-11.0
	elif slot in ["nature_island_sharp_reef_01","nature_island_split_rock_01"]:
		node.mesh=FallbackPrimitiveLibrary.sphere(0.58,0.92)
		node.scale=Vector3(1.55,1.05,0.58)
		node.rotation_degrees.y=18.0
	elif slot=="nature_island_long_hook_01":
		node.mesh=FallbackPrimitiveLibrary.sphere(0.72,0.42)
		node.scale=Vector3(2.45,0.32,0.48)
		node.rotation_degrees.y=-16.0
	elif slot=="nature_island_sand_spit_01":
		node.mesh=FallbackPrimitiveLibrary.sphere(0.72,0.42)
		node.scale=Vector3(2.1,0.34,0.58)
	else:
		node.mesh=FallbackPrimitiveLibrary.sphere(0.64,0.82)
		node.scale=Vector3(1.5,0.70,0.82)
	node.material_override=EnvironmentMaterialCatalog.sand() if slot in ["nature_island_sand_spit_01","nature_island_long_hook_01"] else EnvironmentMaterialCatalog.rock()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
