extends SceneTree
func _init() -> void:
	var failures: Array[String] = []
	var event_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/event_framework.json"))
	if not event_data is Dictionary: failures.append("event framework json invalid")
	else:
		if event_data.get("milestone") != "M39": failures.append("event milestone")
		var haunted = event_data.get("events", {}).get("haunted_tide", {})
		if haunted.is_empty(): failures.append("haunted tide missing")
		for hook in ["ammo", "support_ammo", "supplies", "buffs"]:
			if haunted.get("combat_hooks", {}).get(hook, []).is_empty(): failures.append("missing hook " + hook)
	var mobile_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/mobile_ui_contract.json"))
	if not mobile_data is Dictionary or mobile_data.get("milestone") != "M39": failures.append("mobile contract")
	elif int(mobile_data.get("pickers", {}).get("landscape_columns", 0)) != 2: failures.append("landscape picker columns")
	if failures.is_empty(): print("M39_RUNTIME_CONTRACT_PASS"); quit(0)
	push_error("M39_RUNTIME_CONTRACT_FAIL: " + ", ".join(failures)); quit(1)
