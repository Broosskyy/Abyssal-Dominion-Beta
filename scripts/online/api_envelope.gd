class_name ApiEnvelope
extends RefCounted
static func request(route:String,method:String,payload:Dictionary={})->Dictionary:
	var build:=BuildIdentity.data()
	var rid:=Crypto.new().generate_random_bytes(16).hex_encode()
	return {
		"request_id":"localreq:"+rid,
		"environment":str(build.get("environment","LOCAL_DEVELOPMENT")),
		"client_version":str(build.get("client_version","?")),
		"build_number":int(build.get("build_number",0)),
		"content_config_version":str(build.get("content_config_version","?")),
		"route":route,"method":method,"payload":payload.duplicate(true)
	}
static func local_response(req:Dictionary,payload:Dictionary={},revision:int=0)->Dictionary:
	return {"request_id":str(req.get("request_id","")),"status":"local_ok","server_time":0,
		"revision":revision,"payload":payload.duplicate(true),"error":"","server_verified":false}
