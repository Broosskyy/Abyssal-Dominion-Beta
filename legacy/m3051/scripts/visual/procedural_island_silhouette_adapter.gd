class_name ProceduralIslandSilhouetteAdapter
extends RefCounted
const PATH:="res://data/m139_island_silhouette_profiles.json"
static var _data:Dictionary={}
static func profiles()->Array:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"profiles":[]}
	return _data.get("profiles",[])
static func profile(id:String)->Dictionary:
	for row in profiles():
		if str(row.get("slot_id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
static func slot_for_index(index:int)->String:return "ISLAND-BASE-%03d"%(posmod(index,20)+1)
static func apply(island:Node3D,slot_id:String)->void:
	if island==null:return
	var p:=profile(slot_id)
	if p.is_empty():return
	var silhouette:=str(p.get("silhouette","long_crescent"))
	var scale2:=Vector2.ONE
	var offset:=Vector3.ZERO
	match silhouette:
		"long_crescent":scale2=Vector2(1.55,0.62)
		"split_cove":scale2=Vector2(1.20,0.82)
		"high_cliff":scale2=Vector2(0.88,1.05)
		"low_sandbar":scale2=Vector2(1.72,0.48)
		"hook_bay":scale2=Vector2(1.32,0.72)
		"needle_reef":scale2=Vector2(0.55,1.55)
		"wide_lagoon":scale2=Vector2(1.48,0.92)
		"broken_ring":scale2=Vector2(1.18,1.08)
		"twin_islet":scale2=Vector2(1.28,0.76)
		"stepped_cliff":scale2=Vector2(1.04,1.18)
		"thin_spit":scale2=Vector2(1.78,0.42)
		"triangular_rock":scale2=Vector2(0.94,1.22)
		"horseshoe":scale2=Vector2(1.28,0.86)
		"jagged_fjord":scale2=Vector2(0.78,1.48)
		"flat_palm":scale2=Vector2(1.38,0.72)
		"volcanic_ridge":scale2=Vector2(0.76,1.34)
		"swamp_delta":scale2=Vector2(1.46,0.78)
		"abyss_shard":scale2=Vector2(0.68,1.42)
		"fortress_shelf":scale2=Vector2(1.36,0.88)
		"hidden_cove":scale2=Vector2(1.12,0.84)
	for node_name in ["Underside","Coast","Ground"]:
		var node:=island.get_node_or_null(node_name) as Node3D
		if node!=null:
			node.scale.x*=scale2.x
			node.scale.z*=scale2.y
	# Visual-only secondary masses make coves/splits/twins readable without changing gameplay collision.
	if silhouette in ["split_cove","hook_bay","broken_ring","twin_islet","hidden_cove","swamp_delta"]:
		var secondary:=MeshInstance3D.new()
		secondary.name="SilhouetteSecondary"
		var mesh:=CylinderMesh.new();mesh.top_radius=0.85;mesh.bottom_radius=1.0;mesh.height=0.28
		secondary.mesh=mesh
		var radius:=float(island.get_meta("island_radius",5.0))
		secondary.scale=Vector3(radius*0.42,1.0,radius*0.28)
		secondary.position=Vector3(radius*0.46,0.95,-radius*0.22)
		secondary.material_override=EnvironmentMaterialCatalog.vegetation()
		secondary.set_meta("visual_only",true)
		island.add_child(secondary)
	island.set_meta("production_slot",slot_id)
	island.set_meta("procedural_island_silhouette",silhouette)
	island.set_meta("placeholder_replacement_ready",true)
