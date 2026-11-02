class_name TrustedTimeService
extends GameServiceFacade

var _server_unix_at_sync:=0.0
var _ticks_at_sync:=0
var _synced:=false
var _source:="device_fallback"

func sync_from_server(server_unix:float,server_verified:bool)->Dictionary:
	if not server_verified:return {"ok":false,"error":"server_verification_required"}
	if server_unix<=0.0:return {"ok":false,"error":"invalid_server_time"}
	_server_unix_at_sync=server_unix
	_ticks_at_sync=Time.get_ticks_msec()
	_synced=true
	_source="verified_server"
	return {"ok":true,"source":_source,"server_unix":server_unix}

func now_unix()->float:
	if _synced:
		return _server_unix_at_sync+float(Time.get_ticks_msec()-_ticks_at_sync)/1000.0
	return Time.get_unix_time_from_system()

func trusted()->bool:
	return _synced

func authority()->String:
	if _synced:return "verified_server"
	return "local_device_fallback" if local_only() else "untrusted_device"

static func current(tree:SceneTree)->TrustedTimeService:
	var services:=ServiceLocator.from(tree)
	return services.time if services!=null else null

static func now(tree:SceneTree)->float:
	var service:=current(tree)
	return service.now_unix() if service!=null else Time.get_unix_time_from_system()

static func is_trusted(tree:SceneTree)->bool:
	var service:=current(tree)
	return service!=null and service.trusted()
