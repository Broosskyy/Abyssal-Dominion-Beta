class_name LocalAccountAdapter
extends AuthGateway
## Offline bridge for the current LocalSession. Never emits authenticated_future_server.
var _session:LocalSession
func _init(session:LocalSession=null)->void:_session=session
func state()->String:
	if _session==null or not _session.active():return "signed_out"
	return "guest_local_preview"
func account()->Dictionary:
	if _session==null or not _session.active():return {}
	return {
		"account_id":"local:"+str(_session.profile.get("id","guest")),
		"captain_id":"local:"+str(_session.profile.get("id","guest")),
		"captain_name":_session.display_name(),
		"provider":"guest" if _session.guest else "local_profile",
		"server_verified":false,
		"environment":"LOCAL_DEVELOPMENT"
	}
func begin_guest()->Dictionary:
	if _session==null:return {"ok":false,"error":"no_local_session"}
	_session.guest=true
	return {"ok":true,"account":account(),"authority":"local_only"}
func sign_in(_provider:String,_payload:Dictionary={})->Dictionary:
	return {"ok":false,"error":"live_auth_not_connected","authority":"none"}
func link_provider(_provider:String,_payload:Dictionary={})->Dictionary:
	return {"ok":false,"error":"server_verification_required","authority":"none"}
func sign_out()->void:
	if _session!=null:_session.logout()

func capabilities()->Dictionary:
	return {"available":true,"mode":"local_preview","verified":false,"guest":true,"sign_in":false,"sign_out":true,"provider_verification":false,"environment_isolated":true,"reason":"local_identity_is_not_live_auth"}
