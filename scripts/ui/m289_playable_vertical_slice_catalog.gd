class_name M289PlayableVerticalSliceCatalog
extends RefCounted

static func overview(runtime: M289PlayableVerticalSliceRuntime) -> Dictionary:
	if runtime == null: return {"title":"Playable Vertical Slice", "state":"RUNTIME MISSING", "detail":"M289-Readiness-Observer ist nicht gebunden."}
	var view := runtime.readiness_view()
	return {"title":"Playable Vertical Slice", "state":"SOURCE READY" if int(view.source_ready) == int(view.source_total) else "SOURCE BLOCKED", "detail":"Source-Gates %d/%d · Ablauf %d/%d" % [int(view.source_ready), int(view.source_total), int(view.observed_stages), int(view.stage_total)]}
static func content() -> Dictionary: return {"title":"Slice Content", "state":"PLACEHOLDER INTAKE", "detail":"1 Hafen, 3 vollständige Starter-GLBs, normale NPCs, Elite, Admiral, Monster und Loot besitzen feste austauschbare Slots."}
static func loop() -> Dictionary: return {"title":"End-to-End Loop", "state":"12 STAGES", "detail":"Hafen → Auslaufen → Tap-to-Sail → Ziel → Kanonen/Harpune → Reparatur → Loot/Quest → Untergang/Respawn → Hafenrückkehr."}
static func controls() -> Dictionary: return {"title":"Mobile Controls", "state":"MASTER LOCKED", "detail":"Tap-to-Sail bleibt Schiffseingabe; der Steuerkreis bewegt nur die Kamera. Kein Auto-Chase und kein standardmäßiges Autofire."}
static func combat() -> Dictionary: return {"title":"Combat Boundary", "state":"SERVER CONTRACT", "detail":"Target → Attack → Reload; Kanonen gegen Schiffe, Harpunen gegen Monster. Treffer, Schaden, Loot und Fortschritt bleiben autoritativ."}
static func models() -> Dictionary: return {"title":"Ship Model Strategy", "state":"SINGLE COMPLETE GLB", "detail":"Jedes Startschiff ist ein vollständiges Einzelmodell. Echte modulare Schiffe bleiben auf eine spätere Phase verschoben."}
static func native_qa(runtime: M289PlayableVerticalSliceRuntime) -> Dictionary:
	if runtime == null: return {"title":"Native Gameplay QA", "state":"NOT EVALUATED", "detail":"Keine M289-QA-Daten."}
	var view := runtime.readiness_view()
	return {"title":"Native Gameplay QA", "state":str(view.native_status), "detail":"PASS %d/%d · BLOCKED %d · Godot/Android/GPU/Audio/Haptics benötigen echte Ausführung." % [int(view.native_pass), int(view.native_total), int(view.native_blocked)]}
static func authority() -> Dictionary: return {"title":"Slice Authority", "state":"OBSERVER ONLY", "detail":"M289 beobachtet Gates und Ablaufbelege; es bestätigt weder Kampf, Bewegung, Loot, Fortschritt, Respawn noch Release."}
