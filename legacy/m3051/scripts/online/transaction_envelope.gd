class_name TransactionEnvelope
extends RefCounted
const DOMAINS:=["inventory","wallet","reward","entitlement","progression"]
static func local(domain:String,operation:String,definition_id:String,quantity:int,expected_revision:int=0)->Dictionary:
	if domain not in DOMAINS:return {}
	var rid:=Crypto.new().generate_random_bytes(16).hex_encode()
	return {
		"transaction_id":"local:"+rid,
		"client_request_id":"localreq:"+rid,
		"account_id":"local:preview",
		"environment":"LOCAL_DEVELOPMENT",
		"domain":domain,"operation":operation,"definition_id":definition_id,
		"quantity":quantity,"expected_revision":expected_revision,
		"server_verified":false
	}
static func valid_shape(value:Dictionary)->bool:
	for key in ["transaction_id","client_request_id","account_id","environment","domain","operation","definition_id","quantity","expected_revision"]:
		if not value.has(key):return false
	return str(value.domain) in DOMAINS
