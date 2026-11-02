class_name M273AuthoritativeEncounterOrchestrationCatalog
extends RefCounted
static func overview(runtime:M273AuthoritativeEncounterOrchestrationRuntime)->Dictionary:
	if runtime==null:return {"title":"Encounter Orchestration","state":"SERVER REQUIRED","detail":"Keine autoritative Encounter-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"Encounter · Spawn · Lifecycle","state":"SERVER REPLICA" if int(s.get("encounter_revision",-1))>=0 else "WAITING","detail":"%s · %s · revision %d · sequence %d"%[str(s.get("encounter_kind","UNBOUND")),str(s.get("lifecycle_state","INACTIVE")),int(s.get("encounter_revision",-1)),int(s.get("orchestration_sequence",-1))]}
static func spawns()->Dictionary:
	return {"title":"Spawn · Despawn · Respawn","state":"SERVER AUTHORITATIVE","detail":"Spawn-Gruppen, Entity-Generationen, Despawn, Respawn und Reset werden serverseitig orchestriert; Clients zeigen nur bestätigte World-Replikas."}
static func phases_waves()->Dictionary:
	return {"title":"Admiral · Boss · Waves · Adds","state":"DATA-DRIVEN FOUNDATION","detail":"Phasen, Wellen und Adds laufen über eine gemeinsame serverseitige Encounter-Pipeline. Finale Schwellen, Timings und Gruppengrößen bleiben ungesetzt."}
static func lifecycle()->Dictionary:
	return {"title":"Start · Reset · Defeat · Cleanup","state":"SERVER ONLY","detail":"Encounter-Aktivierung, Leash-/Wipe-Reset, Defeat, Completion und Cleanup sind server-owned und revisions-/sequenzgesichert."}
static func integration()->Dictionary:
	return {"title":"AI · World · Combat · Rewards","state":"SERVER CHAIN","detail":"M273 orchestriert Encounter; M272 entscheidet AI-Absicht, M267 repliziert Spawns/Des-pawns, M269/M270 lösen Combat-State auf und M266 bleibt Reward-/Loot-Settlement-Grenze."}
static func authority()->Dictionary:
	return {"title":"Encounter Authority","state":"SERVER AUTHORITATIVE","detail":"Clients können weder Spawn/Despawn, Respawn/Reset, Wellen/Phasen, Completion noch Rewards committen. TEST/GLOBAL bleiben strikt isoliert."}
