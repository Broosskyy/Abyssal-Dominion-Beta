class_name HudGestureSafety
extends RefCounted
const EDGE:=18.0
const CRITICAL={
	"movement":["wheel","zoom_in","zoom_out","recenter","auto_fire"],
	"combat":["fire","repair","boost","target","ammo_menu","items_menu"]
}

static func inner_safe(layout:Dictionary)->Rect2:
	var safe:Rect2=layout.safe
	if not bool(layout.get("touch_density",false)):return safe
	return safe.grow(-EDGE*float(layout.get("ui_scale",1.0)))

static func near_edge(layout:Dictionary,group_id:String)->bool:
	if group_id not in CRITICAL:return false
	var inner:=inner_safe(layout)
	for id in CRITICAL[group_id]:
		var r:Rect2=layout.actions.get(id,Rect2())
		if r.has_area() and not inner.encloses(r):return true
	return false

static func clamp_critical(layout:Dictionary)->Dictionary:
	if not bool(layout.get("touch_density",false)):return layout
	var inner:=inner_safe(layout)
	for group_id in CRITICAL:
		for id in CRITICAL[group_id]:
			var r:Rect2=layout.actions.get(id,Rect2())
			if not r.has_area():continue
			if r.size.x<=inner.size.x:r.position.x=clampf(r.position.x,inner.position.x,inner.end.x-r.size.x)
			if r.size.y<=inner.size.y:r.position.y=clampf(r.position.y,inner.position.y,inner.end.y-r.size.y)
			layout.actions[id]=r
	return layout
