class_name M288NavalContactReadabilityCatalog
extends RefCounted

static func overview(runtime: M288NavalContactReadabilityRuntime) -> Dictionary:
	if runtime == null: return {"title":"Naval Contact Readability", "state":"SERVER REQUIRED", "detail":"Keine M288-Kontaktpräsentation gebunden."}
	var s := runtime.snapshot()
	return {"title":"Naval Contact Readability", "state":"SERVER REPLICA" if int(s.get("contact_revision", -1)) >= 0 else "PLACEHOLDERS READY", "detail":"contact rev %d · events %d · contacts %d" % [int(s.get("contact_revision", -1)), int(s.get("event_count", 0)), int(s.get("contact_count", 0))]}
static func relations() -> Dictionary: return {"title":"Relation Identity", "state":"NINE CLASSES", "detail":"Spieler, Flotte, Verbündete, Neutrale, Feinde, Elites, Admiräle, Monster und Bosse erhalten originale, datengetriebene Präsentationsidentitäten."}
static func targeting() -> Dictionary: return {"title":"Target Focus", "state":"CONFIRMED ONLY", "detail":"Fokus-Ring und Zielzustand folgen ausschließlich der bestätigten M271-Auswahl; ein lokaler Ring autorisiert keinen Angriff."}
static func threat_range() -> Dictionary: return {"title":"Threat & Range", "state":"READ ONLY", "detail":"Aggro-Chevrons sowie In-/Out-of-Range-Klammern visualisieren Serverzustand und berechnen weder Aggro noch Reichweite."}
static func priority() -> Dictionary: return {"title":"Elite / Admiral / Monster", "state":"PRIORITY BUDGET", "detail":"Hochwertige Kontakte erhalten ein zurückhaltendes World-Beacon; Mobile zeigt nur priorisierte Signale."}
static func offscreen() -> Dictionary: return {"title":"Offscreen Guidance", "state":"EDGE SAFE", "detail":"Ausgewählte oder bedrohliche Kontakte dürfen am sicheren Bildschirmrand geführt werden; Kartenmitte und beide Kontrollcluster bleiben frei."}
static func model_lock() -> Dictionary: return {"title":"Ship Model Strategy", "state":"SINGLE COMPLETE GLB", "detail":"Alle Kontaktmarker liegen außerhalb des vollständigen Einzelmodells. Kein modularer Rumpf, Mast oder Segel ist erforderlich."}
static func authority() -> Dictionary: return {"title":"Contact Authority", "state":"FAIL-CLOSED", "detail":"M271/M269/M272 besitzen Ziel, Beziehung, Schutz, Reichweite, Aggro und Angriffserlaubnis. M288 präsentiert nur bestätigte Wahrheit."}
