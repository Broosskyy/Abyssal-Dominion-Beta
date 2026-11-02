class_name M252OnlineReadinessRuntime
extends Node
## Read-only online/session readiness surface. This never creates live authority.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var locator: ServiceLocator

func _ready() -> void:
	add_to_group("online_readiness")

func configure(value: ServiceLocator) -> void:
	locator = value

func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision < revision: return false
	if str(snapshot.get("environment", "")) == "LOCAL_DEVELOPMENT": return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func snapshot() -> Dictionary:
	if not authoritative_snapshot.is_empty():
		var result := authoritative_snapshot.duplicate(true)
		result["source"] = "SERVER"
		result["revision"] = revision
		return result
	return local_diagnostics()

func local_diagnostics() -> Dictionary:
	var tree := get_tree()
	var env := EnvironmentContract.current_id(tree) if tree != null else "LOCAL_DEVELOPMENT"
	var auth_caps := locator.auth.capabilities() if locator != null and locator.auth != null else {"available":false,"mode":"missing"}
	var repo_caps := locator.repository.capabilities() if locator != null and locator.repository != null else {"available":false,"mode":"missing"}
	var transport_caps := locator.transport.capabilities() if locator != null and locator.transport != null else {"available":false,"mode":"missing"}
	var trusted := locator != null and locator.time != null and locator.time.trusted()
	return {
		"source":"LOCAL_DIAGNOSTIC",
		"revision":-1,
		"environment":env,
		"account":{"state":locator.auth.state() if locator != null and locator.auth != null else "unavailable","server_verified":locator.auth.is_server_verified() if locator != null and locator.auth != null else false},
		"transport":transport_caps,
		"repository":repo_caps,
		"auth":auth_caps,
		"trusted_time":{"trusted":trusted,"authority":locator.time.authority() if locator != null and locator.time != null else "missing"},
		"content_version":locator.content.effective_version() if locator != null and locator.content != null else "missing",
		"server_profile_version":"unverified",
		"connection":{"connected":false,"authoritative":false},
		"resume":{"available":false,"server_verified":false},
		"last_error":"production_backend_not_connected" if env != "LOCAL_DEVELOPMENT" else "local_development_only"
	}

func capability_rows() -> Array[Dictionary]:
	var snap := snapshot()
	var rows: Array[Dictionary] = []
	for key in ["auth", "repository", "transport"]:
		var caps: Dictionary = snap.get(key, {}) if snap.get(key, {}) is Dictionary else {}
		rows.append({"id":key,"available":bool(caps.get("available", false)),"mode":str(caps.get("mode", "unknown")),"reason":str(caps.get("reason", ""))})
	var time_row: Dictionary = snap.get("trusted_time", {}) if snap.get("trusted_time", {}) is Dictionary else {}
	rows.append({"id":"trusted_time","available":bool(time_row.get("trusted", false)),"mode":str(time_row.get("authority", "untrusted")),"reason":"server_sync_required" if not bool(time_row.get("trusted", false)) else ""})
	return rows

func can_client_assert_connected() -> bool: return false
func can_client_verify_account() -> bool: return false
func can_client_promote_local_save_to_server() -> bool: return false
func can_client_authorize_remote_repository() -> bool: return false
func can_client_generate_server_revision() -> bool: return false
func can_client_override_environment_isolation() -> bool: return false
func can_client_generate_trusted_time() -> bool: return false
func can_client_finalize_resume() -> bool: return false
