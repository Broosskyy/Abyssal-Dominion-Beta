class_name M239MasterReadinessCatalog
extends RefCounted

## M239 static/read-only production readiness helper. Never owns gameplay or server state.
const MATRIX_PATH := "res://data/m239_master_convergence_matrix.json"

static func load_matrix()->Dictionary:
	if not FileAccess.file_exists(MATRIX_PATH): return {}
	var file:=FileAccess.open(MATRIX_PATH,FileAccess.READ)
	if file==null:return {}
	var parsed=JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func missing_or_foundation_domains()->Array:
	var out:Array=[]
	for row in load_matrix().get("domains",[]):
		if row is Dictionary and str(row.get("status","")) in ["MISSING","FOUNDATION"]:
			out.append(row.duplicate(true))
	return out

static func production_online_ready()->bool:
	# Explicitly false until real auth + persistence + transport are wired and verified.
	return false
