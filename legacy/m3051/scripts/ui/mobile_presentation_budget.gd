class_name MobilePresentationBudget
extends RefCounted
const PATH := "res://data/m75_mobile_presentation_budget.json"
static var _data:Dictionary={}

static func data()->Dictionary:
	if _data.is_empty():
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data=parsed if parsed is Dictionary else {"profiles":{}}
	return _data

static func profile(viewport_size:Vector2,dpi:float)->Dictionary:
	var compact:bool=viewport_size.y<600.0 or viewport_size.x<1050.0 or (dpi>180.0 and viewport_size.y<760.0)
	var key:String="compact_phone" if compact else ("phone" if dpi>180.0 else "tablet_desktop")
	return ((data().get("profiles",{}) as Dictionary).get(key,{}) as Dictionary).duplicate(true)

static func int_value(viewport_size:Vector2,dpi:float,key:String,fallback:int)->int:
	return int(profile(viewport_size,dpi).get(key,fallback))

static func float_value(viewport_size:Vector2,dpi:float,key:String,fallback:float)->float:
	return float(profile(viewport_size,dpi).get(key,fallback))


static func dressing_visibility_end_for_node(node:Node,fallback:float=38.0)->float:
	if node==null:
		return fallback
	var viewport:Viewport=node.get_viewport()
	if viewport==null:
		return fallback
	var viewport_size:Vector2=viewport.get_visible_rect().size
	var dpi:float=float(DisplayServer.screen_get_dpi())
	return float_value(viewport_size,dpi,"dressing_visibility_end",fallback)

static func apply_geometry_visibility(root:Node,fallback:float=38.0,margin:float=4.0)->void:
	if root==null:
		return
	var end_distance:float=dressing_visibility_end_for_node(root,fallback)
	var stack:Array[Node]=[root]
	while not stack.is_empty():
		var node:Node=stack.pop_back()
		if node is GeometryInstance3D:
			var geometry:=node as GeometryInstance3D
			geometry.visibility_range_end=end_distance
			geometry.visibility_range_end_margin=margin
			geometry.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		for child in node.get_children():
			if child is Node:
				stack.append(child)
