class_name M247BazaarTradingRuntime
extends Node
## M247 V3.8 player Bazaar read-only server replica.
## Local saves cache presentation state only; listings, escrow, fees and value transfer remain server-authoritative online.
signal changed
const PATH := "res://data/m247_bazaar_trading_contract.json"
var revision := -1
var authoritative_snapshot: Dictionary = {}
var local_filters: Dictionary = {}

func contract() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return parsed if parsed is Dictionary else {}

func ingest_authoritative_snapshot(snapshot: Dictionary) -> bool:
	var incoming_revision := int(snapshot.get("revision", -1))
	if incoming_revision < revision: return false
	revision = incoming_revision
	authoritative_snapshot = snapshot.duplicate(true)
	changed.emit()
	return true

func clear_authoritative_snapshot() -> void:
	revision = -1
	authoritative_snapshot = {}
	changed.emit()

func snapshot() -> Dictionary:
	if authoritative_snapshot.is_empty():
		return {"source":"LOCAL_PREVIEW","revision":-1,"summary":{},"listings":[],"my_listings":[],"recent_trades":[],"price_history":[],"limits":{},"config":{}}
	var out := authoritative_snapshot.duplicate(true)
	out["source"] = "SERVER"
	return out

func listing_rows() -> Array:
	var rows = snapshot().get("listings", [])
	return rows as Array if rows is Array else []

func my_listing_rows() -> Array:
	var rows = snapshot().get("my_listings", [])
	return rows as Array if rows is Array else []

func recent_trade_rows() -> Array:
	var rows = snapshot().get("recent_trades", [])
	return rows as Array if rows is Array else []

func price_history_rows() -> Array:
	var rows = snapshot().get("price_history", [])
	return rows as Array if rows is Array else []

func set_local_filters(filters: Dictionary) -> void:
	# Search/filter preferences are presentation state only and never mutate market authority.
	local_filters = filters.duplicate(true)
	changed.emit()

func filtered_listing_rows() -> Array:
	var rows := listing_rows()
	if local_filters.is_empty(): return rows
	var out: Array = []
	for value in rows:
		if not value is Dictionary: continue
		var row := value as Dictionary
		if local_filters.has("item_type") and str(local_filters.item_type) != "" and str(row.get("item_type", "")) != str(local_filters.item_type): continue
		if local_filters.has("family") and str(local_filters.family) != "" and str(row.get("family", "")) != str(local_filters.family): continue
		if local_filters.has("region") and str(local_filters.region) != "" and str(row.get("region", "")) != str(local_filters.region): continue
		var max_price := int(local_filters.get("max_price", -1))
		if max_price >= 0 and int(row.get("unit_price", 0)) > max_price: continue
		out.append(row)
	return out

func export_state() -> Dictionary:
	return {"revision":revision,"authoritative_snapshot":authoritative_snapshot.duplicate(true),"local_filters":local_filters.duplicate(true)}

func import_state(state: Dictionary) -> void:
	var cached = state.get("authoritative_snapshot", {})
	if cached is Dictionary and not (cached as Dictionary).is_empty():
		revision = int(state.get("revision", int((cached as Dictionary).get("revision", -1))))
		authoritative_snapshot = (cached as Dictionary).duplicate(true)
	var filters = state.get("local_filters", {})
	if filters is Dictionary: local_filters = (filters as Dictionary).duplicate(true)
	changed.emit()

func can_client_create_listing() -> bool: return false
func can_client_cancel_listing() -> bool: return false
func can_client_buy_listing() -> bool: return false
func can_client_move_escrow() -> bool: return false
func can_client_set_fees() -> bool: return false
func can_client_transfer_gold_or_items() -> bool: return false
