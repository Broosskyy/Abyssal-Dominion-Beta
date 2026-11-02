class_name OfflineTransportAdapter
extends TransportGateway
## Explicit local-only adapter. It cannot satisfy TEST/GLOBAL authority.
func send(request:Dictionary)->Dictionary:
	if str(request.get("environment",""))!="LOCAL_DEVELOPMENT":
		return {"status":"blocked","error":"server_adapter_required","server_verified":false}
	return ApiEnvelope.local_response(request,{"adapter":"offline_local"})
func server_authoritative()->bool:return false

func capabilities()->Dictionary:
	return {"available":true,"mode":"offline_local","connected":false,"authoritative":false,"server_verified":false,"content_handshake":false,"resume":false,"environment_isolated":true,"reason":"local_transport_only"}
