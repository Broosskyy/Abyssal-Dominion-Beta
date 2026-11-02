extends Node
func _ready()->void:
	var req:=ApiEnvelope.request("inventory","POST",{"definition_id":"ship_small"})
	var offline:=OfflineTransportAdapter.new()
	var res:=offline.send(req)
	assert(res.status=="local_ok")
	assert(not bool(res.server_verified))
	req.environment="GLOBAL_PRODUCTION"
	assert(offline.send(req).status=="blocked")
	var schema:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m104_persistence_schema.json"))
	assert(schema.tables.has("transaction_ledger"))
	assert(schema.tables.has("wallet_balances"))
	var routing:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m104_authority_routing_map.json"))
	assert(routing.client_remains_local.has("HUD layout"))
	var p0:=P0ReplacementQa.data()
	assert(p0.assets.size()==13)
	print("M104_TRANSPORT_SCHEMA_AUTHORITY_PASS")
