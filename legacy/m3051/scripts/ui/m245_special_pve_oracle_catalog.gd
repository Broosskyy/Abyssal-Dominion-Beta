class_name M245SpecialPveOracleCatalog
extends RefCounted

static func status_card(runtime: M245SpecialPveOracleRuntime) -> Dictionary:
	if runtime == null: return {"title":"ORAKEL / KOMPASS-SYSTEM","state":"RUNTIME FEHLT","detail":"Special-PvE-Replica nicht verfügbar.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER":
		return {"title":"ORAKEL / KOMPASS-SYSTEM · ARBEITSNAME","state":"SERVERDATEN AUSSTEHEND","detail":"Tide Essence, Reward-Roll, Pity und Claim werden nicht lokal erfunden. Reward-Pool-Kategorien sind als transparente Vorschau verfügbar.","tone":"info"}
	var amount := int(snap.get("resource_amount", -1))
	var pity := int(snap.get("pity_current", -1)); var threshold := int(snap.get("pity_threshold", -1))
	var pity_text := "Pity: SERVER" if pity < 0 or threshold <= 0 else "Pity: %d/%d" % [pity, threshold]
	return {"title":"ORAKEL / KOMPASS-SYSTEM · ARBEITSNAME","state":"%s · %s" % [("Tide Essence: %d" % amount) if amount >= 0 else "Tide Essence: SERVER", pity_text],"detail":"RewardTable, Duplicate-Regel und Claim stammen aus dem autoritativen Snapshot.","tone":"ready"}

static func pool_card(runtime: M245SpecialPveOracleRuntime) -> Dictionary:
	var categories: Array = runtime.local_pool_preview() if runtime != null else []
	return {"title":"TRANSPARENTER REWARD-POOL","state":", ".join(PackedStringArray(categories)).to_upper() if not categories.is_empty() else "NICHT VERFÜGBAR","detail":"Kategorien ja; Wahrscheinlichkeiten, Mengen und Pity-Schwelle bleiben bis Content-/Legal-/Balance-Freigabe ungesetzt.","tone":"info"}

static func last_reward_card(runtime: M245SpecialPveOracleRuntime) -> Dictionary:
	if runtime == null: return {"title":"LETZTE BELOHNUNG","state":"KEINE SERVERDATEN","detail":"Keine lokale Reward-Simulation.","tone":"locked"}
	var reward = runtime.snapshot().get("last_reward", {})
	if not reward is Dictionary or (reward as Dictionary).is_empty(): return {"title":"LETZTE BELOHNUNG","state":"KEINE SERVERDATEN","detail":"Keine lokale Reward-Simulation.","tone":"locked"}
	return {"title":"LETZTE BELOHNUNG","state":str((reward as Dictionary).get("label", (reward as Dictionary).get("id", "SERVER REWARD"))).to_upper(),"detail":"Status: %s" % str(runtime.snapshot().get("claim_state","server_required")),"tone":"active"}
