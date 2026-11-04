class_name GameplayIntentContract
extends RefCounted
## M82 transport-neutral command vocabulary. No network transport is implemented here.

const GAMEPLAY := [
	"sail_target","cancel_sail","target_next","fire","repair","boost","interact",
	"select_weapon_mode","select_ammunition","quick_item"
]
const PRESENTATION := ["camera_pan","camera_zoom","camera_recenter","open_menu","close_menu"]

static func is_gameplay(id:String)->bool:
	return id in GAMEPLAY

static func is_presentation(id:String)->bool:
	return id in PRESENTATION

static func local_envelope(id:String,payload:Dictionary={})->Dictionary:
	return {
		"schema":1,
		"intent":id,
		"payload":payload.duplicate(true),
		"local_only":true,
		"server_validated":false,
	}
