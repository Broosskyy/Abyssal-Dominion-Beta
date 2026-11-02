class_name HarborVisualBudget
extends RefCounted
const PATH:="res://data/m88_havens_reach_visual_budget.json"

static func data()->Dictionary:
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

static func visible_dressing_target(port:Node)->int:
	var parsed:=data()
	if port==null:return 12
	var viewport:=port.get_viewport().get_visible_rect().size
	var touch:=bool(port.get_tree().root.get_meta("touch_ui",false))
	var mobile:=touch or viewport.x<1100.0 or viewport.y<650.0
	var row:Dictionary=parsed.get("mobile" if mobile else "desktop",{})
	var target:=int(row.get("dressing_visible_target",12 if mobile else 18))
	var settings:=ClientSettings.current(port.get_tree())
	if settings!=null:
		var quality:=str(settings.values.get("graphics_quality","balanced")).to_lower()
		if quality=="low":target=maxi(7,roundi(target*0.62))
		elif quality=="high":target=int(row.get("dressing_hard_max",target))
	return target

static func apply(root:Node3D,port:Node)->void:
	if root==null:return
	var dressing_target:=visible_dressing_target(port)
	var dressing_seen:=0
	for socket in root.get_children():
		if not socket is Node3D:continue
		var tier:=str(socket.get_meta("visual_tier","dressing"))
		if tier=="dressing":
			dressing_seen+=1
			socket.visible=dressing_seen<=dressing_target
		else:
			socket.visible=true
	root.set_meta("dressing_visible_target",dressing_target)
	root.set_meta("landmark_preservation",true)
