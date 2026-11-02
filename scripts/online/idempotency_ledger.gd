class_name IdempotencyLedger
extends RefCounted
## Local test helper only. Future authoritative dedupe belongs to the server/database.
var seen:Dictionary={}
func accept(envelope:Dictionary)->Dictionary:
	if not TransactionEnvelope.valid_shape(envelope):return {"status":"rejected","reason":"invalid_shape"}
	var key:=str(envelope.client_request_id)
	if seen.has(key):return {"status":"duplicate","result":seen[key].duplicate(true)}
	var result:={"status":"accepted","local_only":true,"transaction_id":str(envelope.transaction_id)}
	seen[key]=result.duplicate(true)
	return result
