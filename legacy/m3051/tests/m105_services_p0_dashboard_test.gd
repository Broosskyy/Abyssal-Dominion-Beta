extends Node
func _ready()->void:
	var adapter:=TransportAdapterFactory.create(get_tree())
	assert(not adapter.server_authoritative())
	var dash:=P0ReplacementDashboard.data()
	assert(int(dash.summary.total)==13)
	assert(int(dash.summary.final)==0)
	var contract:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m105_service_facade_contract.json"))
	assert(contract.services.has("wallet"))
	assert(contract.services.has("entitlement"))
	var glb:=JSON.parse_string(FileAccess.get_file_as_string("res://data/m105_glb_diagnostic_contract.json"))
	assert(str(glb.checks.forward_axis).contains("+Z"))
	print("M105_SERVICES_P0_DASHBOARD_PASS")
