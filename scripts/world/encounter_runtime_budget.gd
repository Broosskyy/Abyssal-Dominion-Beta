class_name EncounterRuntimeBudget
extends RefCounted
static func can_spawn(current_count:int,is_boss:bool)->bool:
	if is_boss:return current_count<RuntimeQualityBudget.max_npcs()+2
	return current_count<RuntimeQualityBudget.max_npcs()
static func should_simulate(ship:ShipMotor,player:ShipMotor)->bool:
	if ship==null or player==null:return false
	if bool(ship.get_meta("is_admiral",false)) or bool(ship.get_meta("encounter_kind","")=="monster"):return true
	return ship.global_position.distance_to(player.global_position)<=RuntimeQualityBudget.simulation_distance()
