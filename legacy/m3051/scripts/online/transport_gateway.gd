class_name TransportGateway
extends RefCounted
func send(_request:Dictionary)->Dictionary:
	return {"status":"unavailable","error":"transport_not_implemented","server_verified":false}
func server_authoritative()->bool:return false

func capabilities()->Dictionary:
	return {"available":false,"mode":"foundation","connected":false,"authoritative":false,"server_verified":false,"content_handshake":false,"resume":false,"environment_isolated":true,"reason":"transport_not_implemented"}
