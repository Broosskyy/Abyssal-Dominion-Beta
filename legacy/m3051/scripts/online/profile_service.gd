class_name ProfileService
extends GameServiceFacade
func snapshot()->Dictionary:
	if game_state==null:return {}
	return game_state._loaded_payload.duplicate(true)
func save_snapshot()->Dictionary:
	if not local_only():return {"ok":false,"error":"server_profile_repository_required"}
	return {"ok":game_state!=null and game_state.save_now(),"authority":"local_only"}
