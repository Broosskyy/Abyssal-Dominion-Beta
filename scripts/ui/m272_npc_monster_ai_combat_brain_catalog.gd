class_name M272NpcMonsterAICombatBrainCatalog
extends RefCounted
static func overview(runtime:M272NpcMonsterAICombatBrainRuntime)->Dictionary:
	if runtime==null:return {"title":"AI Combat Brain","state":"SERVER REQUIRED","detail":"Keine autoritative NPC-/Monster-AI-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"NPC · Monster · Admiral · Boss","state":"SERVER REPLICA" if int(s.get("brain_revision",-1))>=0 else "WAITING","detail":"%s · %s · revision %d · decision %d"%[str(s.get("archetype","UNBOUND")),str(s.get("brain_state","IDLE")),int(s.get("brain_revision",-1)),int(s.get("decision_sequence",-1))]}
static func state_machine(runtime:M272NpcMonsterAICombatBrainRuntime)->Dictionary:
	return {"title":"Patrol · Pursue · Attack · Return","state":"SERVER ONLY" if runtime!=null else "SERVER REQUIRED","detail":"Patrol, Acquire, Pursue, Attack, Reposition, Evade, Leash und Return sind serverseitige Entscheidungen; Clients zeigen nur bestätigte Zustände/Telegraphen."}
static func threat(runtime:M272NpcMonsterAICombatBrainRuntime)->Dictionary:
	return {"title":"Threat · Target Resolution","state":"SERVER AUTHORITATIVE","detail":"M271 liefert legale Beziehungen/Ziele; M272 bewertet Threat und wählt serverseitig das Encounter-Ziel. Lokale Threat-Hints sind nicht entscheidend."}
static func archetypes()->Dictionary:
	return {"title":"NPC · Monster · Admiral · Boss Profiles","state":"DATA-DRIVEN FOUNDATION","detail":"Gemeinsame Authority-Pipeline mit archetypspezifischen Verhaltensprofilen/Phasen; keine finalen Radien, Gewichte oder Timings sind hart codiert."}
static func integration()->Dictionary:
	return {"title":"Movement · Fire · Combat State","state":"SERVER CHAIN","detail":"M272 entscheidet AI-Absicht; M268 validiert Bewegung, M271 Ziellegalität, M269 Fire/Outcome und M270 zeitlichen Kampfzustand. M267 repliziert die bestätigte Welt."}
static func authority()->Dictionary:
	return {"title":"AI Authority","state":"SERVER AUTHORITATIVE","detail":"Clients können weder Aggro/Threat, Target, AI-State, Leash, Path, Angriff noch Bossphase committen. TEST/GLOBAL bleiben isoliert."}
