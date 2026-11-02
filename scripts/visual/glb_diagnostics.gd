class_name GlbDiagnostics
extends RefCounted
static func inspect(root:Node3D,id:String)->Dictionary:
	if root==null:return {"id":id,"status":"missing_root"}
	var bounds:Variant=root.get_meta("hud_visual_bounds",AABB())
	var aabb:=bounds as AABB if bounds is AABB else AABB()
	var cls:="ship" if id.begins_with("ship_") or id.begins_with("npc_") else ("monster" if id.begins_with("monster_") else ("island" if id.begins_with("island_") else "world"))
	return {
		"id":id,"asset_class":cls,"bounds":[aabb.size.x,aabb.size.y,aabb.size.z],
		"bounds_nonzero":aabb.size.length()>0.001,
		"forward_axis":"+Z" if cls in ["ship","monster"] else "n/a",
		"waterline":"Y=0" if cls in ["ship","monster"] else "n/a",
		"collision":"wrapper_owned","native_acceptance":"pending"
	}
