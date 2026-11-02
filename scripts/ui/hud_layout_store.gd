class_name HudLayoutStore
extends Node
## M84 device-local HUD layout persistence.
## Positions are normalized to safe area; scale/visibility remain presentation-only.

signal changed
const SCHEMA:=3
const GROUPS:=["profile_status","mission","objective","minimap","movement","combat","quickbar","target","currency"]
const HIDEABLE:=["mission","objective","minimap","quickbar","target","currency"]
const SCALE_MIN:=0.80
const SCALE_MAX:=1.35
const PRESETS:={
	"standard":{},
	"combat":{
		"mission":{"x":-0.02,"y":0.03,"scale":0.90,"visible":true},
		"objective":{"x":0.0,"y":0.03,"scale":0.95,"visible":true},
		"minimap":{"x":-0.02,"y":0.02,"scale":0.92,"visible":true},
		"movement":{"x":0.0,"y":0.0,"scale":0.95,"visible":true},
		"combat":{"x":-0.02,"y":-0.02,"scale":1.12,"visible":true},
		"quickbar":{"x":0.0,"y":-0.01,"scale":1.08,"visible":true},
		"target":{"x":0.0,"y":0.02,"scale":1.05,"visible":true},
		"currency":{"x":0.0,"y":0.0,"scale":0.90,"visible":true}
	},
	"minimal":{
		"mission":{"x":0.0,"y":0.0,"scale":0.85,"visible":false},
		"objective":{"x":0.0,"y":0.0,"scale":0.90,"visible":true},
		"minimap":{"x":0.0,"y":0.0,"scale":0.88,"visible":true},
		"movement":{"x":0.0,"y":0.0,"scale":0.92,"visible":true},
		"combat":{"x":0.0,"y":0.0,"scale":1.05,"visible":true},
		"quickbar":{"x":0.0,"y":0.0,"scale":0.94,"visible":true},
		"target":{"x":0.0,"y":0.0,"scale":0.95,"visible":true},
		"currency":{"x":0.0,"y":0.0,"scale":0.85,"visible":false}
	}
}
var path:="user://hud_layout_m83.json"
var layouts:Dictionary={}
var memory_only:=false

func _ready()->void:
	add_to_group("hud_layout_store")
	memory_only=bool(get_tree().root.get_meta("reconstruction_test_mode",false))
	load_layouts()

static func current(tree:SceneTree)->HudLayoutStore:
	return tree.get_first_node_in_group("hud_layout_store") as HudLayoutStore

func load_layouts()->void:
	layouts={}
	if memory_only or not FileAccess.file_exists(path):return
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return
	var schema:int=int(parsed.get("schema",0))
	if parsed.get("layouts") is Dictionary:
		layouts=parsed.layouts.duplicate(true)
		if schema==1:_migrate_v1()
		elif schema==2:_migrate_v2()

func _migrate_v1()->void:
	for profile in layouts:
		for group in (layouts[profile] as Dictionary).keys():
			var row:Variant=layouts[profile][group]
			if row is Dictionary:
				row["scale"]=1.0
				row["visible"]=true
				row["locked"]=false
	_save()

func _migrate_v2()->void:
	for profile in layouts:
		for group in (layouts[profile] as Dictionary).keys():
			var value:Variant=layouts[profile][group]
			if value is Dictionary:
				value["locked"]=false
	_save()

func row(profile:String,group:String)->Dictionary:
	var value:Variant=layouts.get(profile,{}).get(group,{})
	var result:Dictionary={"x":0.0,"y":0.0,"scale":1.0,"visible":true,"locked":false}
	if value is Dictionary:
		result.x=clampf(float(value.get("x",0.0)),-0.85,0.85)
		result.y=clampf(float(value.get("y",0.0)),-0.85,0.85)
		result.scale=clampf(float(value.get("scale",1.0)),SCALE_MIN,SCALE_MAX)
		result.visible=bool(value.get("visible",true))
		result.locked=bool(value.get("locked",false))
	if group not in HIDEABLE:result.visible=true
	return result

func offset(profile:String,group:String,safe:Rect2)->Vector2:
	var r:=row(profile,group)
	return Vector2(float(r.x)*safe.size.x,float(r.y)*safe.size.y)

func set_offset(profile:String,group:String,offset_px:Vector2,safe:Rect2)->void:
	if group not in GROUPS or safe.size.x<=0 or safe.size.y<=0:return
	var r:=row(profile,group)
	if bool(r.locked):return
	r.x=clampf(offset_px.x/safe.size.x,-0.85,0.85)
	r.y=clampf(offset_px.y/safe.size.y,-0.85,0.85)
	_set_row(profile,group,r)

func set_scale(profile:String,group:String,value:float)->void:
	if group not in GROUPS:return
	var r:=row(profile,group)
	if bool(r.locked):return
	r.scale=clampf(value,SCALE_MIN,SCALE_MAX)
	_set_row(profile,group,r)

func toggle_visible(profile:String,group:String)->void:
	if group not in HIDEABLE:return
	var r:=row(profile,group)
	if bool(r.locked):return
	r.visible=not bool(r.visible)
	_set_row(profile,group,r)

func toggle_lock(profile:String,group:String)->void:
	if group not in GROUPS:return
	var r:=row(profile,group)
	r.locked=not bool(r.locked)
	_set_row(profile,group,r)

func apply_preset(profile:String,id:String)->void:
	if not PRESETS.has(id):return
	if id=="standard":
		layouts.erase(profile)
	else:
		layouts[profile]=(PRESETS[id] as Dictionary).duplicate(true)
	_save()
	changed.emit()

func reset_profile(profile:String)->void:
	layouts.erase(profile)
	_save()
	changed.emit()

func reset_all()->void:
	layouts.clear()
	_save()
	changed.emit()

func _set_row(profile:String,group:String,r:Dictionary)->void:
	if not layouts.has(profile):layouts[profile]={}
	layouts[profile][group]=r.duplicate(true)
	_save()
	changed.emit()

func _save()->void:
	if memory_only:return
	var writer:=GameState.new()
	writer._write_text(path,JSON.stringify({"schema":SCHEMA,"layouts":layouts}))
	writer.free()
