extends Node
func _ready()->void:
	var auth:=AdminAuthorization.new();add_child(auth)
	assert(not auth.can("content.publish"))
	assert(not auth.apply_verified_identity({"staff_id":"x","roles":["content_editor"],"permissions":["admin.access","content.edit"],"permission_version":"1"},false))
	assert(auth.apply_verified_identity({"staff_id":"x","roles":["content_editor"],"permissions":["admin.access","content.edit"],"permission_version":"1"},true))
	assert(auth.can("content.edit"))
	assert(not auth.can("content.publish"))
	var rbac:=JSON.parse_string(FileAccess.get_file_as_string("res://data/admin_rbac_contract.json"))
	assert(int(rbac.critical_actions["payment.configure"].approval_count)==2)
	print("M127_RBAC_PASS")
