class_name ShipAssetAcceptance
extends RefCounted
const PATH := "res://data/m65_p0_ship_acceptance.json"
const SOCKET_PATH := "res://data/m65_ship_socket_contract.json"
static var _data: Dictionary = {}
static var _socket_data: Dictionary = {}

static func _ensure() -> void:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	if _socket_data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOCKET_PATH))
		_socket_data = parsed if parsed is Dictionary else {}

static func is_p0_ship(id: String) -> bool:
	_ensure()
	return _data.get("ships",{}).has(id)

static func socket_names() -> Array[String]:
	_ensure()
	var result: Array[String] = []
	for row in _socket_data.get("required",[]):
		result.append(str(row.get("id","")))
	return result

static func find_socket(root: Node, socket_name: String) -> Node3D:
	if root == null: return null
	var node := root.find_child(socket_name, true, false)
	return node as Node3D if node is Node3D else null

static func socket_report(root: Node, id: String) -> Array[String]:
	_ensure()
	var lines: Array[String] = []
	for row in _socket_data.get("required",[]):
		if id not in row.get("required_on",[]): continue
		var name := str(row.get("id",""))
		lines.append("%s · %s" % [name, "OK" if find_socket(root,name) != null else "FALLBACK"])
	return lines

static func acceptance_lines(id: String, bounds: AABB) -> Array[String]:
	_ensure()
	var info: Dictionary = _data.get("ships",{}).get(id,{})
	if info.is_empty(): return []
	var lines: Array[String] = []
	lines.append("ROLE · " + str(info.get("camera_role","P0 ship")))
	lines.append("BOUNDS · %.2f × %.2f × %.2f m" % [bounds.size.x,bounds.size.y,bounds.size.z])
	if info.has("target_length_m"):
		var r: Array = info.target_length_m
		lines.append("LENGTH ENVELOPE · %.1f–%.1f m · %s" % [float(r[0]),float(r[1]),"OK" if bounds.size.z >= float(r[0]) and bounds.size.z <= float(r[1]) else "CHECK"])
	if info.has("target_width_m"):
		var r: Array = info.target_width_m
		lines.append("WIDTH ENVELOPE · %.1f–%.1f m · %s" % [float(r[0]),float(r[1]),"OK" if bounds.size.x >= float(r[0]) and bounds.size.x <= float(r[1]) else "CHECK"])
	lines.append("WATERLINE · Y=0")
	lines.append("FORWARD · +Z")
	lines.append("GAMEPLAY · wrapper-owned")
	return lines
