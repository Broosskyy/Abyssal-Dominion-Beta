class_name M249PvpHonorRankedCatalog
extends RefCounted

static func overview_card(runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	if runtime == null: return {"title":"PVP · EHRE · RANKED","state":"RUNTIME FEHLT","detail":"Competitive Replica nicht verfügbar.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER":
		return {"title":"PVP · EHRE · RANKED","state":"SERVERDATEN AUSSTEHEND","detail":"Keine lokale Ehre, Division, MMR, Queue oder PvP-Verwundbarkeit wird erfunden.","tone":"info"}
	var zone := runtime.zone_state(); var ranked := runtime.ranked_state()
	var zone_label := str(zone.get("label", zone.get("type", "ZONE"))).to_upper()
	var division := str(ranked.get("division_label", ranked.get("division", "UNRANKED"))).to_upper()
	return {"title":"PVP · EHRE · RANKED","state":"%s · %s" % [zone_label, division],"detail":"Serverbestätigter Competitive State. Open-Sea PvP, Ranked, Guild War, Event PvP, Bounty Hunt und Duels bleiben getrennte Modi.","tone":"ready"}

static func zone_card(runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"PVP-ZONE","state":"SERVER REQUIRED","detail":"PvP-Verwundbarkeit wird niemals aus einem versteckten lokalen Zustand abgeleitet.","tone":"locked"}
	var zone := runtime.zone_state(); var protection := runtime.protection_state()
	var enabled := bool(zone.get("pvp_enabled", false))
	var state := str(zone.get("label", zone.get("type", "UNBEKANNT"))).to_upper()
	var details: Array[String] = []
	details.append("PVP %s" % ("AKTIV" if enabled else "NICHT AKTIV"))
	if bool(protection.get("starter", false)): details.append("STARTERSCHUTZ")
	if bool(protection.get("respawn", false)): details.append("RESPAWN-SCHUTZ")
	if bool(protection.get("safe_harbor", false)): details.append("SAFE HARBOR")
	return {"title":"PVP-ZONE","state":state,"detail":" · ".join(details),"tone":"danger" if enabled else "info"}

static func honor_card(runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"EHRE","state":"SERVER REQUIRED","detail":"Ehre ist veränderliche PvP-Reputation und bleibt getrennt von Ruhm und Battle Rank.","tone":"locked"}
	var h := runtime.honor_state()
	return {"title":"EHRE","state":str(h.get("label", h.get("value_label", "SERVER"))),"detail":str(h.get("detail", "Qualifiziertes PvP, Bounties, Guild Wars und Danger-Zone-Ziele; Anti-Farm wird serverseitig geprüft.")),"tone":"active"}

static func ranked_card(runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"BATTLE RANK","state":"SERVER REQUIRED","detail":"Hidden MMR + sichtbare Rank Points + Division; keine lokale Ranked-Simulation.","tone":"locked"}
	var r := runtime.ranked_state()
	var state := str(r.get("division_label", r.get("division", "UNRANKED"))).to_upper()
	var detail := str(r.get("rank_points_label", "Rank Points: serverbestätigt"))
	if r.has("season_label"): detail += " · " + str(r.get("season_label", ""))
	return {"title":"BATTLE RANK","state":state,"detail":detail,"tone":"ready","progress":float(r.get("division_progress", 0.0))}

static func queue_card(runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"RANKED QUEUE","state":"NICHT VERBUNDEN","detail":"MMR, Region/Ping, Party Size und kontrollierte Sucherweiterung benötigen den Matchmaking-Service.","tone":"info"}
	var q := runtime.queue_state()
	if q.is_empty(): return {"title":"RANKED QUEUE","state":"NICHT EINGEREIHT","detail":"Kein serverbestätigter Queue-Zustand.","tone":"info"}
	return {"title":"RANKED QUEUE","state":str(q.get("state_label", q.get("state", "SERVER"))).to_upper(),"detail":str(q.get("detail", "Serverbestätigtes Matchmaking.")),"tone":"active"}

static func combat_timer_card(runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"COMBAT TIMER","state":"SERVERZEIT","detail":"Logout, Harbor-Transition und Teleport dürfen qualifiziertes PvP nicht kostenlos resetten.","tone":"locked"}
	var t := runtime.combat_timer_state()
	if not bool(t.get("active", false)): return {"title":"COMBAT TIMER","state":"INAKTIV","detail":"Serverbestätigt kein aktiver PvP-Combat-Timer.","tone":"info"}
	return {"title":"COMBAT TIMER","state":str(t.get("remaining_label", "AKTIV")),"detail":"Serverzeit; Escape-/Logout-Regeln bleiben autoritativ.","tone":"warning"}

static func authority_card(_runtime: M249PvpHonorRankedRuntime) -> Dictionary:
	return {"title":"COMPETITIVE AUTHORITY","state":"SERVER REQUIRED","detail":"Client setzt weder PvP-Flag, Ehre, MMR/Rank Points, Match Result, Combat Timer, Anti-Farm-Verdict noch Rewards.","tone":"locked"}
