class_name IslandSecondaryDetailComposer
extends RefCounted
## M90 one additional visual-only world detail under strict cap.

const SLOT_BY_PROFILE={
	"cliff_cove":"nature_island_cove_rock_spur_01",
	"tropical_small":"nature_island_beach_notch_01",
	"long_shoal":"nature_island_low_reef_01",
	"thin_spit":"nature_island_spit_rocks_01"
}
static func apply(island:Node3D,profile_id:String)->void:
	if profile_id not in SLOT_BY_PROFILE:return
	var root:=Node3D.new()
	root.name="M90SecondaryDetail"
	root.set_meta("visual_only",true)
	root.set_meta("context_cap",1)
	island.add_child(root)
	var slot:=str(SLOT_BY_PROFILE[profile_id])
	var socket:=Node3D.new()
	socket.name="Slot_"+slot
	socket.set_meta("production_slot",slot)
	socket.position=Vector3(float(island.get_meta("island_radius",5.0))*0.72,0.18,-float(island.get_meta("island_radius",5.0))*0.38)
	root.add_child(socket)
	if AssetVisualLibrary.install(socket,slot)==null:
		var mesh:=MeshInstance3D.new()
		mesh.name="Fallback"
		if slot=="nature_island_cove_rock_spur_01":
			mesh.mesh=FallbackPrimitiveLibrary.box(Vector3(1.65,1.25,0.62));mesh.rotation_degrees.y=-28.0;mesh.scale=Vector3(1.15,1.0,0.72)
		elif slot=="nature_island_spit_rocks_01":
			mesh.mesh=FallbackPrimitiveLibrary.sphere(0.42,0.62);mesh.scale=Vector3(1.55,0.72,0.62)
		elif slot=="nature_island_low_reef_01":
			mesh.mesh=FallbackPrimitiveLibrary.sphere(0.52,0.32);mesh.scale=Vector3(1.8,0.28,0.75)
		elif slot=="nature_island_beach_notch_01":
			mesh.mesh=FallbackPrimitiveLibrary.sphere(0.58,0.36);mesh.scale=Vector3(1.5,0.22,0.82)
		else:
			mesh.mesh=FallbackPrimitiveLibrary.sphere(0.42,1.10);mesh.scale=Vector3(0.8,1.4,0.8)
		mesh.material_override=EnvironmentMaterialCatalog.sand() if slot=="nature_island_beach_notch_01" else EnvironmentMaterialCatalog.rock()
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		socket.add_child(mesh)
