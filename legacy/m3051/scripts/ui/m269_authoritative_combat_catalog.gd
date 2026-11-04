class_name M269AuthoritativeCombatCatalog
extends RefCounted

static func overview(runtime: M269AuthoritativeCombatRuntime) -> Dictionary:
	if runtime==null: return {"title":"Combat Resolution","state":"SERVER REQUIRED","detail":"Keine autoritative Combat-Replica gebunden."}
	var s:=runtime.snapshot()
	return {"title":"Combat Resolution","state":"SERVER BOUND" if str(s.get("source",""))=="SERVER" else "LOCAL PREVIEW","detail":"Combat rev %d · server tick %d · pending fire %d"%[int(s.get("combat_revision",-1)),int(s.get("server_tick",-1)),int(s.get("pending_fire_count",0))]}

static func targeting(runtime: M269AuthoritativeCombatRuntime) -> Dictionary:
	if runtime==null: return {"title":"Targeting","state":"SERVER REQUIRED","detail":"Zielstatus nicht verfügbar."}
	var target:=str(runtime.snapshot().get("selected_target_entity_id",""))
	return {"title":"Targeting & Fire Intent","state":"TARGET LOCK" if not target.is_empty() else "NO TARGET","detail":"Zielwahl/Target-Cycling darf sofort reagieren; Range, Beziehung und Line-of-Fire bleiben serverseitige Legalitätsentscheidungen."}

static func resolution(runtime: M269AuthoritativeCombatRuntime) -> Dictionary:
	if runtime==null: return {"title":"Hit / Damage / Heal","state":"SERVER REQUIRED","detail":"Kein bestätigtes Combat-Ergebnis."}
	var v:=runtime.snapshot().get("last_verdict",{}) as Dictionary
	return {"title":"Hit · Damage · Heal","state":str(v.get("outcome","WAITING")),"detail":"Treffer, Miss, Block, Critical, Schaden, Heal und Death gelten erst mit server-verifiziertem Combat-Verdict."}

static func settlement() -> Dictionary:
	return {"title":"Ammo · Cooldown · Rewards","state":"SERVER ONLY","detail":"Ammo-Verbrauch/Ownership und Combat-Rewards koppeln an M266-Transaktionen; Cooldown/Reload und Kill Credit sind keine Client-Wahrheit."}

static func authority() -> Dictionary:
	return {"title":"Combat Authority Boundary","state":"SERVER ONLY","detail":"M267 transportiert, M268 bewegt, M269 entscheidet Combat. Client-VFX sind Feedback, kein Hit-/Damage-/Reward-Beleg. TEST und GLOBAL bleiben getrennt."}
