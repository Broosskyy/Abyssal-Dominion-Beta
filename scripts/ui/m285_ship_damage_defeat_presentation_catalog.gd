class_name M285ShipDamageDefeatPresentationCatalog
extends RefCounted

static func overview(runtime: M285ShipDamageDefeatPresentationRuntime) -> Dictionary:
	if runtime == null: return {"title":"Ship Damage & Defeat", "state":"SERVER REQUIRED", "detail":"Keine M285 Schiffszustands-Replica gebunden."}
	var s := runtime.snapshot()
	return {"title":"Ship Damage & Defeat", "state":"SERVER REPLICA" if int(s.get("state_revision", -1)) >= 0 else "LOCAL PLACEHOLDER READY", "detail":"state rev %d · presentation rev %d · ships %d" % [int(s.get("state_revision", -1)), int(s.get("presentation_revision", -1)), int(s.get("ship_count", 0))]}
static func hit_reactions() -> Dictionary: return {"title":"Ship Hit Reactions", "state":"EVENT DRIVEN", "detail":"Bestätigte Schild-, Rumpf- und Panzerungstreffer wählen kurze Flash-/Tilt-/Motion-Hooks; sie erzeugen keinen Schaden."}
static func hull_shield() -> Dictionary: return {"title":"Hull & Shield Readability", "state":"SEGMENT AWARE", "detail":"Hull-/Shield-/Segmentzustände bleiben getrennt und wählen materiallesbare Effekte, ohne sichtbare Werte als Wahrheit zu verwenden."}
static func damage_states() -> Dictionary: return {"title":"Persistent Damage States", "state":"REPLICA DRIVEN", "detail":"INTACT → LIGHT → MODERATE → HEAVY → CRITICAL → DEFEATED steuert Rumpfschäden, Feuer und Rauch bis Repair oder Defeat bestätigt ist."}
static func placeholders() -> Dictionary: return {"title":"Damage Placeholder Rig", "state":"REPLACEABLE", "detail":"VFX_Damage_01/02, Shield und Sink-Sockets nutzen mobile-taugliche Fallback-Geometrie mit stabilen finalen Asset-Slots."}
static func sinking() -> Dictionary: return {"title":"Sinking & Defeat", "state":"SERVER CONFIRMED", "detail":"NPC-, Spieler- und Admiral-Defeat nutzt seed-gesteuerte Sinksequenzen; Animation bestätigt weder Kill noch Reward."}
static func cleanup() -> Dictionary: return {"title":"Defeat Cleanup", "state":"RECONNECT SAFE", "detail":"Nur CLEANUP_CONFIRMED entfernt Replica-/HUD-Zustand und fordert visuelles World-Entity-Cleanup an; Wiederholungen werden verworfen."}
static func authority() -> Dictionary: return {"title":"Damage / Defeat Authority", "state":"FAIL-CLOSED", "detail":"M269/M270 besitzen Damage/Defeat; M285 darf weder despawnen, looten noch belohnen ohne Serverbestätigung."}
