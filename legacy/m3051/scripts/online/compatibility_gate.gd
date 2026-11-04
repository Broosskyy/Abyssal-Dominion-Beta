class_name CompatibilityGate
extends RefCounted
const PATH:="res://data/m102_compatibility_matrix.json"
static func data()->Dictionary:
	var parsed:=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}
static func local_check()->Dictionary:
	var d:=data()
	var build:=BuildIdentity.data()
	var ok:=str(build.get("environment",""))=="LOCAL_DEVELOPMENT" and int(d.get("client",{}).get("build",0))==102
	return {"ok":ok,"mode":"local_only","server_check_performed":false}
