class_name M287ShipMotionIdentityCatalog
extends RefCounted

static func overview(runtime: M287ShipMotionIdentityRuntime) -> Dictionary:
	if runtime == null: return {"title":"Ship Motion Identity", "state":"SERVER REQUIRED", "detail":"Keine M287-Bewegungspräsentation gebunden."}
	var s := runtime.snapshot()
	return {"title":"Ship Motion Identity", "state":"SERVER REPLICA" if int(s.get("motion_revision", -1)) >= 0 else "PLACEHOLDERS READY", "detail":"motion rev %d · events %d · entities %d" % [int(s.get("motion_revision", -1)), int(s.get("event_count", 0)), int(s.get("entity_count", 0))]}
static func profiles() -> Dictionary: return {"title":"Motion Profiles", "state":"FIVE FAMILIES", "detail":"LIGHT, BALANCED, HEAVY, ADMIRAL und ABYSSAL unterscheiden sichtbare Wasserverdrängung und Segelreaktion, niemals echte Geschwindigkeit."}
static func wakes() -> Dictionary: return {"title":"Bow / Stern / Turn Wake", "state":"REPLACEABLE VFX", "detail":"Bugverdrängung, Heckspur und Kurvenwasser besitzen getrennte austauschbare VFX-Slots außerhalb des vollständigen Schiffsmodells."}
static func sails() -> Dictionary: return {"title":"Sail Response", "state":"PRESENTATION ONLY", "detail":"Segel reagieren dezent auf bestätigten Fahrt-/Kurvenzustand; Mast, Heading und Navigation bleiben unangetastet."}
static func movement_states() -> Dictionary: return {"title":"Motion States", "state":"REPLICA DRIVEN", "detail":"Anker, Idle, Beschleunigung, Fahrt, Kurve, Bremsen, Drift und Korrektur werden als bestätigte Präsentationszustände geführt."}
static func responsive() -> Dictionary: return {"title":"Cross-platform Motion", "state":"PARITY", "detail":"Mobile/Web reduziert sekundäres Kurvenwasser; Welt, Route, Kollision, Geschwindigkeit und Gameplay bleiben identisch."}
static func controls() -> Dictionary: return {"title":"Tap-to-Sail / Camera", "state":"LOCKED", "detail":"Wassertipp bewegt das Schiff. Der Steuerkreis unten links bewegt ausschließlich die Kamera; M287 ändert diese Trennung nicht."}
static func authority() -> Dictionary: return {"title":"Movement Authority", "state":"FAIL-CLOSED", "detail":"M268 besitzt Position, Velocity, Heading, Route und Kollision. M287 erzeugt ausschließlich Wake-/Segel-/Wasserfeedback."}
