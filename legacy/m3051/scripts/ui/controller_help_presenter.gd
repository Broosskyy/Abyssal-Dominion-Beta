class_name ControllerHelpPresenter
extends RefCounted
const ROWS=[
	{"action":"sail","touch":"Tap/drag sea","desktop":"Click sea / WASD","gamepad":"Left stick","slot":"m88_controller_focus"},
	{"action":"target","touch":"Tap target","desktop":"Click target","gamepad":"Target action","slot":"m86_gamepad_target"},
	{"action":"fire","touch":"Fire button","desktop":"Fire key/button","gamepad":"Fire action","slot":"m84_gamepad_fire"},
	{"action":"help","touch":"HUD settings","desktop":"HUD settings","gamepad":"Help","slot":"m88_controller_help"}]
static func rows(mode:String)->Array:
	var result:Array=[]
	for row in ROWS:result.append({"action":row.action,"label":str(row.get(mode,row.desktop)),"slot":row.slot})
	return result
