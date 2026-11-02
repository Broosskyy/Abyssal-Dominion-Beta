class_name M255PaymentCommerceRuntime
extends Node
## M255 read-only server/provider replica for catalog, purchases and entitlements.
## The client may start a purchase intent but cannot grant ownership, validate receipts or settle refunds.
signal changed
var revision := -1
var authoritative_snapshot: Dictionary = {}
var local_preferences := {"shop_filter":"all"}

func _ready() -> void:
	add_to_group("payment_commerce_readiness")

func ingest_authoritative_snapshot(snapshot: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < 0 or incoming_revision < revision: return false
	var environment := str(snapshot.get("environment", ""))
	if environment.is_empty() or environment == "LOCAL_DEVELOPMENT": return false
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
	return {"source":"LOCAL_PREVIEW","revision":-1,"offers":[],"purchases":[],"entitlements":[],"provider_status":{}}

func offer_rows() -> Array[Dictionary]: return _server_rows("offers")
func purchase_rows() -> Array[Dictionary]: return _server_rows("purchases")
func entitlement_rows() -> Array[Dictionary]: return _server_rows("entitlements")

func _server_rows(key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return result
	var rows = snap.get(key, [])
	if rows is Array:
		for row in rows:
			if row is Dictionary: result.append((row as Dictionary).duplicate(true))
	return result

func provider_status() -> Dictionary:
	var snap := snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"source":"LOCAL_PREVIEW","state":"unavailable"}
	var row = snap.get("provider_status", {})
	if row is Dictionary:
		var result: Dictionary = (row as Dictionary).duplicate(true)
		result["source"] = "SERVER"
		return result
	return {"source":"SERVER","state":"unknown"}

func purchase_intent_preview(product_id: String) -> Dictionary:
	# Presentation-only request envelope. A real provider adapter/server must execute and verify it.
	if product_id.is_empty(): return {"accepted":false,"reason":"missing_product_id","authority":"CLIENT_PRESENTATION_ONLY"}
	return {"accepted":true,"product_id":product_id,"authority":"CLIENT_PRESENTATION_ONLY","grants_ownership":false}

func set_shop_filter(filter_id: String) -> void:
	local_preferences["shop_filter"] = filter_id
	changed.emit()

func can_client_validate_receipt() -> bool: return false
func can_client_grant_entitlement() -> bool: return false
func can_client_confirm_purchase() -> bool: return false
func can_client_set_store_price() -> bool: return false
func can_client_reuse_purchase_token() -> bool: return false
func can_client_settle_refund() -> bool: return false
func can_client_settle_chargeback() -> bool: return false
func can_client_revoke_entitlement() -> bool: return false
func can_client_transfer_test_entitlement_to_global() -> bool: return false
func can_client_mutate_premium_wallet() -> bool: return false
