class_name M280RewardVisualIntegrationRuntime
extends Node
## M280 visual integration layer over M279. Presentation-only; never reward authority.
signal changed
signal visual_feedback(kind: String, payload: Dictionary)

var presentation_revision := -1
var visual_revision := -1
var server_tick := -1
var environment := ""
var encounter_id := ""
var visual_state: Dictionary = {}
var last_server_event: Dictionary = {}

const SERVER_EVENTS := ["VISUAL_SNAPSHOT", "SEA_CHART_REWARD", "BOSS_REVEAL", "ADMIRAL_REVEAL", "INBOX_BADGE_VISUAL", "CLAIM_VISUAL_STATE", "VISUAL_CLEARED", "VISUAL_RESTORED"]
const EMPHASIS := ["QUIET", "STANDARD", "HIGH", "BOSS", "ADMIRAL"]

func _ready() -> void:
	add_to_group("reward_visual_integration_readiness")

func bind_reward_presentation(runtime: M279AuthoritativeRewardPresentationRuntime) -> bool:
	if runtime == null: return false
	var s := runtime.snapshot()
	if str(s.get("source", "")) != "SERVER": return false
	presentation_revision = int(s.get("presentation_revision", -1))
	server_tick = int(s.get("server_tick", -1))
	environment = str(s.get("environment", "")).to_upper()
	encounter_id = str(s.get("encounter_id", ""))
	if presentation_revision < 0 or environment.is_empty() or encounter_id.is_empty(): return false
	changed.emit(); return true

func ingest_server_visual_event(event: Dictionary, server_verified: bool) -> bool:
	if not server_verified: return false
	if str(event.get("environment", "")).to_upper() != environment or str(event.get("encounter_id", "")) != encounter_id: return false
	var pr := int(event.get("presentation_revision", -1)); var vr := int(event.get("visual_revision", -1)); var tick := int(event.get("server_tick", -1))
	if pr < presentation_revision or vr <= visual_revision or tick < server_tick: return false
	var kind := str(event.get("event", "")).to_upper(); if kind not in SERVER_EVENTS: return false
	var state: Variant = event.get("visual_state", {})
	if not state is Dictionary or not _valid_visual_state(state as Dictionary): return false
	presentation_revision = pr; visual_revision = vr; server_tick = tick; visual_state = (state as Dictionary).duplicate(true)
	last_server_event = event.duplicate(true); last_server_event["server_verified"] = true
	visual_feedback.emit(kind, last_server_event.duplicate(true)); changed.emit(); return true

func _valid_visual_state(state: Dictionary) -> bool:
	if state.is_empty(): return true
	if str(state.get("authority", "SERVER")).to_upper() != "SERVER": return false
	if str(state.get("emphasis", "STANDARD")).to_upper() not in EMPHASIS: return false
	for forbidden in ["client_reward_value", "client_quantity_override", "client_rarity_override", "client_claim_success", "client_settlement_success"]:
		if state.has(forbidden): return false
	return true

func presentation_view(layout: Dictionary) -> Dictionary:
	if visual_revision < 0 or visual_state.is_empty(): return {}
	var compact := bool(layout.get("compact", false))
	var safe: Rect2 = layout.get("safe", Rect2())
	var top: Rect2 = layout.get("top", Rect2())
	var width := minf((360.0 if compact else 500.0), maxf(220.0, safe.size.x - 28.0))
	return {
		"source":"SERVER",
		"visual_revision":visual_revision,
		"title":str(visual_state.get("title", "BELOHNUNG BESTÄTIGT")),
		"subtitle":str(visual_state.get("subtitle", "")),
		"quantity_text":str(visual_state.get("quantity_text", "")),
		"rarity":str(visual_state.get("rarity", "standard")),
		"emphasis":str(visual_state.get("emphasis", "STANDARD")).to_upper(),
		"icon_asset_id":str(visual_state.get("icon_asset_id", "")),
		"inbox_badge_count":int(visual_state.get("inbox_badge_count", 0)),
		"claim_state":str(visual_state.get("claim_state", "NONE")),
		"rect":Rect2(Vector2(safe.get_center().x-width*0.5, top.end.y + (12.0 if compact else 16.0)), Vector2(width, 68.0 if compact else 76.0)),
		"authority":"LOCAL_RENDER_OF_SERVER_CONFIRMED_STATE"
	}

func local_visual_intent(request_id: String, action: String) -> Dictionary:
	if request_id.is_empty() or action.to_upper() not in ["DISMISS", "OPEN_INBOX", "OPEN_CLAIM"]: return {}
	return {"intent":"REWARD_VISUAL_"+action.to_upper(), "request_id":request_id, "expected_visual_revision":visual_revision, "environment":environment, "authority":"CLIENT_PRESENTATION_INTENT_ONLY", "creates_value":false, "changes_reward":false, "confirms_claim":false, "settles_reward":false}

func invalidate_from_world_resync() -> void:
	visual_state.clear(); last_server_event = {"event":"WORLD_RESYNC", "server_verified":false}; changed.emit()

func snapshot() -> Dictionary:
	return {"source":"SERVER" if visual_revision>=0 else "LOCAL_PREVIEW", "environment":environment, "encounter_id":encounter_id, "presentation_revision":presentation_revision, "visual_revision":visual_revision, "server_tick":server_tick, "visual_state":visual_state.duplicate(true), "last_server_event":last_server_event.duplicate(true)}

func can_client_create_reward_visual_truth() -> bool: return false
func can_client_override_reward_icon_or_rarity() -> bool: return false
func can_client_confirm_reward_delivery() -> bool: return false
func can_client_transfer_test_visual_to_global() -> bool: return false
