class_name LocalGameStateRepository
extends RepositoryGateway
## Compatibility adapter around current local save ownership. Not a future server repository.
var game_state:GameState
func _init(value:GameState=null)->void:game_state=value
func load_snapshot(_account_id:String)->Dictionary:
	if game_state==null:return {"ok":false,"error":"no_game_state"}
	return {"ok":true,"snapshot":game_state._loaded_payload.duplicate(true),"authority":"local_only"}
func save_snapshot(_account_id:String,_snapshot:Dictionary,_transaction_id:String)->Dictionary:
	if game_state==null:return {"ok":false,"error":"no_game_state"}
	return {"ok":game_state.save_now(),"authority":"local_only"}

func capabilities()->Dictionary:
	return {"available":true,"mode":"local_preview","authoritative":false,"load":true,"save":true,"revision_guard":false,"environment_isolated":true,"reason":"local_save_is_not_server_persistence"}
