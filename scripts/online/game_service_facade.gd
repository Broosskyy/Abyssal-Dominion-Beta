class_name GameServiceFacade
extends RefCounted
var player:ShipMotor
var game_state:GameState
func _init(player_value:ShipMotor=null,state_value:GameState=null)->void:
	player=player_value;game_state=state_value
func environment_id()->String:
	if player==null:return "LOCAL_DEVELOPMENT"
	return EnvironmentContract.current_id(player.get_tree())
func local_only()->bool:return environment_id()=="LOCAL_DEVELOPMENT"
func server_authoritative()->bool:return false
