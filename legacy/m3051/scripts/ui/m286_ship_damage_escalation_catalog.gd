class_name M286ShipDamageEscalationCatalog
extends RefCounted

static func overview(runtime: M286ShipDamageEscalationRuntime) -> Dictionary:
	if runtime == null: return {"title":"Ship Damage Overlays", "state":"SERVER REQUIRED", "detail":"Keine M286-Segment-Replica gebunden."}
	var s := runtime.snapshot()
	return {"title":"Ship Damage Overlays", "state":"SERVER REPLICA" if int(s.get("escalation_revision", -1)) >= 0 else "PLACEHOLDERS READY", "detail":"escalation rev %d · transitions %d · entities %d" % [int(s.get("escalation_revision", -1)), int(s.get("transition_count", 0)), int(s.get("entity_count", 0))]}
static func segments() -> Dictionary: return {"title":"Ship Damage Segments", "state":"SEVEN ZONES", "detail":"Bug, Backbord-/Steuerbordrumpf, Deck, Mast, Segel und Heck werden nur aus bestätigtem Segmentzustand visualisiert."}
static func deck_mast_sails() -> Dictionary: return {"title":"Deck · Mast · Sails", "state":"OVERLAY ONLY", "detail":"Bresche, Mast- und Segelschaden sind VFX-Proxies über einem vollständigen Einzelmodell; sie ersetzen oder zerlegen keine Schiffsteile."}
static func flooding() -> Dictionary: return {"title":"Flooding & Waterline", "state":"STAGED", "detail":"Wasserlinie, Blasen und Breakup erscheinen nur innerhalb der bestätigten Defeat-Sequenz und beeinflussen keine Bewegung."}
static func sinking_profiles() -> Dictionary: return {"title":"Sinking Profiles", "state":"DATA DRIVEN", "detail":"Leichte, schwere, Admiral- und abyssale Präsentationen wählen seed-gesteuerte Profile; finale Kurven bleiben Native-QA-offen."}
static func placeholders() -> Dictionary: return {"title":"Damage Overlay Placeholders", "state":"REPLACEABLE", "detail":"Deck-, Mast-, Segel-, Rumpf-, Wasserlinien-, Blasen- und Wrack-Proxies liegen außerhalb des vollständigen Schiffsmodells."}
static func responsive() -> Dictionary: return {"title":"Sea-chart Readability", "state":"BUDGETED", "detail":"Mobile/Web reduziert sekundäre Segmente und Blasen; Karte, Tap-to-Sail und beide unteren Kontrollzonen bleiben frei."}
static func authority() -> Dictionary: return {"title":"Destruction Authority", "state":"FAIL-CLOSED", "detail":"M285 bestätigt Defeat; M286 ändert weder Transform, Equipment, Schaden, Despawn, Wreck-Entity, Loot noch Reward."}
