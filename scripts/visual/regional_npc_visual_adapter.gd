class_name RegionalNpcVisualAdapter
extends RefCounted
const PATH:="res://data/m140_regional_npc_visual_profiles.json"
static var _data:Dictionary={}
static func profile(region_id:String)->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=(parsed.get("profiles",{}) as Dictionary) if parsed is Dictionary else {}
	return (_data.get(region_id,{}) as Dictionary).duplicate(true)
static func apply(ship:Node3D,region_id:String,role:String="")->void:
	if ship==null:return
	var p:=profile(region_id)
	if p.is_empty():return
	var visual:=ship.get_node_or_null("Visual") as Node3D
	if visual==null:return
	var hull:=Color(str(p.get("hull","6b4b32")))
	var sail:=Color(str(p.get("sail","d5ccb0")))
	var trim:=Color(str(p.get("trim","a37b4d")))
	for child in visual.get_children():
		if not child is MeshInstance3D:continue
		var mesh:=child as MeshInstance3D
		var name:=str(mesh.name)
		if name in ["Hull","Bow","Keel","SternGallery"]:mesh.material_override=ProceduralFactory.material(hull)
		elif name.begins_with("Sail"):mesh.material_override=ProceduralFactory.material(sail)
		elif name=="HullTrim" or name=="CaptainPennant":mesh.material_override=ProceduralFactory.material(trim)
	ship.set_meta("regional_visual_family",str(p.get("family",region_id)))
	ship.set_meta("regional_visual_role",role)
