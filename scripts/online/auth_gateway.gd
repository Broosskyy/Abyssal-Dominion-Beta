class_name AuthGateway
extends RefCounted
## Replaceable auth boundary. Implementations must never turn a local profile into server identity.
func provider_ids()->Array[String]:return ["guest","email","google","apple"]
func state()->String:return "signed_out"
func account()->Dictionary:return {}
func begin_guest()->Dictionary:return {"ok":false,"error":"not_implemented"}
func sign_in(_provider:String,_payload:Dictionary={})->Dictionary:return {"ok":false,"error":"not_implemented"}
func link_provider(_provider:String,_payload:Dictionary={})->Dictionary:return {"ok":false,"error":"server_verification_required"}
func sign_out()->void:pass
func is_server_verified()->bool:return false

func capabilities()->Dictionary:
	return {"available":false,"mode":"foundation","verified":false,"guest":false,"sign_in":false,"sign_out":false,"provider_verification":false,"environment_isolated":true,"reason":"auth_not_implemented"}
