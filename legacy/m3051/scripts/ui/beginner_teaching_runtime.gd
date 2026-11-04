class_name BeginnerTeachingRuntime
extends RefCounted
static func primary_mode(player:ShipMotor)->String:
	if player==null:return "none"
	var voyage:=player.get_node_or_null("Voyage") as VoyageProgress
	if voyage!=null and not voyage.beginner_complete() and voyage.trial_active:return "objective_strip"
	if not FirstSessionGuide.state(player).is_empty():return "first_session"
	return "none"
static func show_objective_strip(player:ShipMotor)->bool:return primary_mode(player)=="objective_strip"
static func show_first_session(player:ShipMotor)->bool:return primary_mode(player)=="first_session"
static func diagnostics(player:ShipMotor)->Dictionary:
	return {"mode":primary_mode(player),"max_primary_cards":1,"safe_area_required":true,"custom_hud_preserved":true}
