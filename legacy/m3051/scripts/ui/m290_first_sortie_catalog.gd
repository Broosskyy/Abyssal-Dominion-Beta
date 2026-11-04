class_name M290FirstSortieCatalog
extends RefCounted

static func overview(runtime: M290FirstSortieIntegrationRuntime) -> Dictionary:
	if runtime == null: return {"title":"First Sea Sortie", "state":"RUNTIME MISSING", "detail":"M290-Integrationsbrücke ist nicht gebunden."}
	var view := runtime.presentation_view()
	return {"title":"First Sea Sortie", "state":str(view.status).replace("_", " "), "detail":"%d/%d beobachtet (%d lokal, %d serverbestätigt) · Nächstes: %s · Niederlage/Respawn QA %d/%d" % [int(view.observed), int(view.total), int(view.local_core), int(view.server_verified_core), str(view.next_label), int(view.optional_qa_observed), int(view.optional_qa_total)]}

static func event_binding() -> Dictionary: return {"title":"Gameplay Event Binding", "state":"CONNECTED", "detail":"Tap-to-Sail, Zielwahl, Kanonen-/Harpunenfeuer, Reparatur, Loot, Auftrag, Untergang, Respawn und Hafenstatus liefern reine Beobachtungs-Hooks."}
static func m291_causality() -> Dictionary: return {"title":"Sortie Evidence · M291", "state":"CORE / OPTIONAL QA", "detail":"Ablegen nur nach Hafen-Interaktion oder tatsächlichem Verlassen von Haven's Reach. Reguläre Rückkehr ohne erzwungenen Untergang; Niederlage/Respawn bleiben separate QA. Beobachtet ist kein Treffer- oder Native-PASS."}
static func m292_guidance() -> Dictionary: return {"title":"First Sortie HUD · M292", "state":"LAYOUT SAFE", "detail":"Ohne aktiv verfolgten Auftrag zeigt das bestehende Missionsfeld den nächsten Ausfahrtsschritt samt Hinweis. Mit Auftrag bleibt dieser vorn; nur ein kleiner Zähler erscheint, falls genug Platz ist. Lokal beobachtet ist niemals serverbestätigt."}
static func m293_world_priority() -> Dictionary: return {"title":"World Guidance · M293", "state":"PLAYER CHOICE FIRST", "detail":"Ausfahrts-Beacon pausiert bei verfolgtem Auftrag, aktivem Kampfziel, offenem Menü/Karte oder Untergang. Hafenstart und Rückkehr zeigen nur Haven's Reach; versunkene oder entfernte Ziele werden nicht markiert."}
static func m294_sailing(runtime: M290FirstSortieIntegrationRuntime) -> Dictionary:
	if runtime == null or runtime.sailing_observer == null: return {"title":"Tap-to-Sail Route · M294", "state":"NOT EVALUATED", "detail":"Kein lokaler Routen-Beobachter gebunden; keine Fahrt wird behauptet."}
	var route := runtime.sailing_observer.presentation_view()
	var names := {"IDLE":"KEIN KURS", "INTENT_ONLY":"KURS GESETZT", "MOTION_OBSERVED":"FAHRT LOKAL BEOBACHTET", "ARRIVAL_OBSERVED":"ANKUNFT LOKAL BEOBACHTET", "INTERRUPTED":"ROUTE UNTERBROCHEN"}
	return {"title":"Tap-to-Sail Route · M294", "state":str(names.get(str(route.state), "NICHT AUSGEWERTET")), "detail":"Lokale QA-Beobachtung einer Wasser-Tap-Route · Revision %d · kein Server-Bewegungsbeleg, kein Native-PASS. %s" % [int(route.route_generation), str(route.interruption_reason)]}
static func guidance() -> Dictionary: return {"title":"Visible Sortie Guidance", "state":"PRESENTATION ONLY", "detail":"Ein einzelner ersetzbarer Welt-Beacon und eine kompakte Missionsleisten-Anzeige führen zum nächsten offenen Schritt; keine Auto-Navigation oder Zielwahl."}
static func models() -> Dictionary: return {"title":"Ship Model Strategy", "state":"ONE SHIP = ONE GLB", "detail":"Starter, NPCs, Elites und Admiräle bleiben vollständige Einzelmodelle. Externe Sockets tragen nur Waffen, VFX, Wake, Schaden und Marker."}
static func clean_room() -> Dictionary: return {"title":"Genre Reference", "state":"CLEAN ROOM", "detail":"Seafight/Battle of Sea dienen nur als Referenz für unmittelbare Lesbarkeit und befriedigendes Seekarten-Feedback; keine proprietären Inhalte oder Timings."}
static func native_qa(runtime: M290FirstSortieIntegrationRuntime) -> Dictionary:
	var state := "NOT EVALUATED" if runtime == null else str(runtime.presentation_view().native_status).replace("_", " ")
	return {"title":"Native Gameplay QA", "state":state, "detail":"Statische Event-Bindings sind kein Godot-/Geräte-PASS. Desktop, Android, GPU, Audio und Haptik benötigen echte Belege."}
static func authority() -> Dictionary: return {"title":"First Sortie Authority", "state":"OBSERVER ONLY", "detail":"M290 bewegt kein Schiff, wählt kein Ziel, feuert nicht, bestätigt keinen Treffer und vergibt weder Loot noch Fortschritt oder Rewards."}
