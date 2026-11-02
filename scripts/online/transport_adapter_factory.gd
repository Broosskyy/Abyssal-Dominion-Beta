class_name TransportAdapterFactory
extends RefCounted
static func create(tree:SceneTree)->TransportGateway:
	var env:=EnvironmentContract.current_id(tree)
	if env=="LOCAL_DEVELOPMENT":return OfflineTransportAdapter.new()
	return TransportGateway.new() # fail-closed until a real server adapter exists
static func status(tree:SceneTree)->Dictionary:
	var env:=EnvironmentContract.current_id(tree)
	return {"environment":env,"adapter":"offline_local" if env=="LOCAL_DEVELOPMENT" else "unavailable_server_required",
		"server_authoritative":false}
