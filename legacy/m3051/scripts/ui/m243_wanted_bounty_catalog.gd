class_name M243WantedBountyCatalog
extends RefCounted

static func status_card(runtime: M243WantedBountyRuntime) -> Dictionary:
	if runtime == null:
		return {"title":"WANTED", "state":"RUNTIME FEHLT", "detail":"Wanted/Bounty-Replica ist nicht verfügbar.", "tone":"locked"}
	var s := runtime.snapshot()
	if str(s.get("source", "")) != "SERVER":
		return {"title":"WANTED", "state":"KEINE SERVERDATEN", "detail":"Wanted Score, Killstreak und PvP-Kopfgeld werden nicht lokal erfunden.", "tone":"locked"}
	return {"title":"WANTED", "state":str(s.get("wanted_label", s.get("wanted_state", "AKTIV"))).to_upper(), "detail":"Killstreak %d · Risiko %s · Server-Replica r%d" % [int(s.get("kill_streak",0)), str(s.get("risk_state","unknown")), int(s.get("revision",-1))], "tone":"warning" if str(s.get("wanted_state","inactive")) != "inactive" else "info"}

static func bounty_card(row: Dictionary) -> Dictionary:
	var target_type := str(row.get("target_type", "target")).to_upper()
	var target_label := str(row.get("target_label", row.get("target_id", "Unbekanntes Ziel")))
	var state := str(row.get("state", "published")).to_upper()
	var detail := "%s · %s" % [target_type, str(row.get("objective", "Jagdauftrag"))]
	if row.has("expires_label"): detail += " · " + str(row.expires_label)
	return {"title":target_label, "state":state, "detail":detail, "tone":"active"}

static func authority_card(runtime: M243WantedBountyRuntime) -> Dictionary:
	var s := runtime.snapshot() if runtime != null else {}
	return {"title":"BOUNTY-AUTORITÄT", "state":"SERVER REQUIRED", "detail":"Kill-Qualifikation, Anti-Farming, Ehre, Auszahlung und Settlement bleiben serverautoritativ. Status: %s." % str(s.get("anti_farm_state","server_required")), "tone":"locked"}
