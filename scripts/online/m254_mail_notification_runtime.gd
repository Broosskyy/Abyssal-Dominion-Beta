class_name M254MailNotificationRuntime
extends Node
## M254 read-only server replica for Mail, Notifications and idempotent Claim presentation.
## Local cache and UI acknowledgement never settle ownership or rewards.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var local_preferences := {"mail_filter":"all", "dismissed_notification_ids":[]}

func _ready() -> void:
	add_to_group("mail_notification_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision < revision: return false
	if str(snapshot.get("environment", "")).is_empty() or str(snapshot.get("environment", "")) == "LOCAL_DEVELOPMENT": return false
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
	return {"source":"LOCAL_PREVIEW","revision":-1,"mail":[],"notifications":[],"claims":[],"unread_count":0,"claimable_count":0}

func mail_rows() -> Array[Dictionary]:
	return _server_rows("mail")

func notification_rows() -> Array[Dictionary]:
	return _server_rows("notifications")

func claim_receipt_rows() -> Array[Dictionary]:
	return _server_rows("claims")

func _server_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func critical_hud_notice() -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"visible":false,"source":str(snap.get("source","LOCAL_PREVIEW"))}
	for row in notification_rows():
		if str(row.get("priority", "")) == "critical" and bool(row.get("hud_eligible", false)):
			return {"visible":true,"source":"SERVER","id":str(row.get("notification_id","")),"label":str(row.get("short_label",row.get("title","SYSTEM")))}
	return {"visible":false,"source":"SERVER"}

func set_mail_filter(filter_id: String) -> void:
	local_preferences["mail_filter"] = filter_id
	changed.emit()

func dismiss_notification_locally(notification_id: String) -> void:
	# Presentation-only acknowledgement; does not mark server delivery/read/claim state.
	var ids: Array = local_preferences.get("dismissed_notification_ids", [])
	if not ids.has(notification_id): ids.append(notification_id)
	local_preferences["dismissed_notification_ids"] = ids
	changed.emit()

func can_client_deliver_mail() -> bool: return false
func can_client_attach_rewards() -> bool: return false
func can_client_set_expiry() -> bool: return false
func can_client_set_audience() -> bool: return false
func can_client_settle_claim() -> bool: return false
func can_client_generate_claim_receipt() -> bool: return false
func can_client_grant_compensation() -> bool: return false
func can_client_confirm_read_sync() -> bool: return false
func can_client_publish_notification() -> bool: return false
