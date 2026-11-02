class_name M246AchievementCollectionCatalog
extends RefCounted

static func overview_card(runtime: M246AchievementCollectionRuntime) -> Dictionary:
	if runtime == null: return {"title":"ERFOLGE & SAMMLUNGEN","state":"RUNTIME FEHLT","detail":"Progressions-Replica nicht verfügbar.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER":
		return {"title":"ERFOLGE & SAMMLUNGEN","state":"SERVERDATEN AUSSTEHEND","detail":"Kategorien sind sichtbar; Fortschritt, Abschlüsse, Claims und Profil-Showcase werden nicht lokal erfunden.","tone":"info"}
	var summary = snap.get("summary", {})
	if not summary is Dictionary: summary = {}
	var complete := int((summary as Dictionary).get("achievements_completed", 0))
	var total := int((summary as Dictionary).get("achievements_total", 0))
	var collections := int((summary as Dictionary).get("collections_completed", 0))
	return {"title":"ERFOLGE & SAMMLUNGEN","state":"%d/%d ERFOLGE · %d SETS" % [complete,total,collections],"detail":"Serverbestätigter Account-/Captain-Fortschritt. Belohnungen besitzen serverseitige Claim-/Receipt-Autorität.","tone":"ready","progress":float(complete)/float(maxi(1,total))}

static func achievement_card(row: Dictionary) -> Dictionary:
	var progress := float(row.get("progress", 0.0)); var target := maxf(1.0, float(row.get("target", 1.0)))
	var state := str(row.get("state", "in_progress"))
	var claim := str(row.get("claim_state", ""))
	var detail := str(row.get("description", ""))
	var reward := str(row.get("reward_summary", ""))
	if not reward.is_empty(): detail += (" · Reward: " + reward)
	if not claim.is_empty(): detail += (" · Claim: " + claim)
	return {"title":str(row.get("title", row.get("id", "Achievement"))),"state":"%s · %.0f/%.0f" % [state.to_upper(),progress,target],"detail":detail,"tone":"ready" if state in ["completed","claimed"] else "active","progress":clampf(progress/target,0.0,1.0)}

static func collection_card(row: Dictionary) -> Dictionary:
	var discovered := int(row.get("discovered", 0)); var total := maxi(1, int(row.get("total", 1)))
	var detail := "Familie: %s" % str(row.get("family", "collection"))
	var reward := str(row.get("reward_summary", ""))
	if not reward.is_empty(): detail += " · Meilenstein: " + reward
	return {"title":str(row.get("title", row.get("id", "Collection"))),"state":"%d/%d · %s" % [discovered,total,str(row.get("state","in_progress")).to_upper()],"detail":detail,"tone":"ready" if discovered>=total else "info","progress":float(discovered)/float(total)}

static func preview_card(runtime: M246AchievementCollectionRuntime) -> Dictionary:
	if runtime == null: return {"title":"MASTER-KATEGORIEN","state":"NICHT VERFÜGBAR","detail":"","tone":"locked"}
	var preview := runtime.local_category_preview()
	return {"title":"MASTER-KATEGORIEN","state":"10 ERFOLGSBEREICHE · 6 SAMMLUNGEN","detail":"Erfolge: %s · Sammlungen: %s" % [", ".join(PackedStringArray(preview.get("achievement_categories",[]))), ", ".join(PackedStringArray(preview.get("collection_families",[])))],"tone":"info"}

static func authority_card(runtime: M246AchievementCollectionRuntime) -> Dictionary:
	return {"title":"CLAIM & PROFIL-AUTORITÄT","state":"SERVER REQUIRED","detail":"Client setzt weder Completion noch Collection-Fortschritt, Reward-Claim/Receipt oder dauerhaften Profil-Showcase selbst.","tone":"locked"}
