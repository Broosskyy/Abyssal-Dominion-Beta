class_name ContentRuntimeService
extends GameServiceFacade
func effective_version()->String:
	var tree:=player.get_tree() if player!=null else null
	var registry:=LiveConfigRegistry.current(tree)
	return registry.version if registry!=null else "missing"
func effective_source()->String:
	var tree:=player.get_tree() if player!=null else null
	var registry:=LiveConfigRegistry.current(tree)
	return registry.source if registry!=null else "missing"
func apply_verified_snapshot(snapshot:Dictionary,server_verified:bool)->Dictionary:
	var tree:=player.get_tree() if player!=null else null
	var registry:=LiveConfigRegistry.current(tree)
	if registry==null:return {"ok":false,"error":"live_config_missing"}
	if not server_verified:return {"ok":false,"error":"server_verification_required"}
	var errors:=ContentPublishValidator.validate_snapshot(snapshot)
	if not errors.is_empty():return {"ok":false,"error":"validation_failed","details":errors}
	return {"ok":registry.apply_verified_snapshot(snapshot,true),"version":str(snapshot.get("config_version","")),"authority":"verified_snapshot"}
func request_publish(config_version:String)->Dictionary:
	if local_only():return {"ok":false,"error":"production_publish_backend_required"}
	return {"ok":false,"error":"transport_publish_not_implemented","config_version":config_version}
