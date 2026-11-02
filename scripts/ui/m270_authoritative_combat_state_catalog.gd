class_name M270AuthoritativeCombatStateCatalog
extends RefCounted
static func overview(runtime:M270AuthoritativeCombatStateRuntime)->Dictionary:
	if runtime==null: return {"title":"Combat State","state":"SERVER REQUIRED","detail":"Kein autoritativer Combat-State gebunden."}
	var s:=runtime.snapshot(); return {"title":"Combat State · Reload","state":str(s.get("combat_phase","WAITING")),"detail":"State rev %d · server tick %d · weapons %d"%[int(s.get("combat_state_revision",-1)),int(s.get("server_tick",-1)),(s.get("weapon_states",{}) as Dictionary).size()]}
static func effects(runtime:M270AuthoritativeCombatStateRuntime)->Dictionary:
	if runtime==null:return {"title":"Status Effects","state":"SERVER REQUIRED","detail":"Keine bestätigten Effekte."}
	var s:=runtime.snapshot(); return {"title":"Buffs · Debuffs · DoT/HoT","state":"SERVER REPLICA","detail":"%d aktive Effekte. Dauer, Tick, Stack/Refresh und Remove bleiben serverseitig."%[(s.get("status_effects",{}) as Dictionary).size()]}
static func sustain(runtime:M270AuthoritativeCombatStateRuntime)->Dictionary:
	return {"title":"Repair · Shield · Sustain","state":"SERVER ONLY" if runtime!=null else "SERVER REQUIRED","detail":"Repair, Shield-Heal, DoT/HoT und Defeat verändern Ressourcen nur durch serverbestätigte State-Events."}
static func projectiles(runtime:M270AuthoritativeCombatStateRuntime)->Dictionary:
	if runtime==null:return {"title":"Projectiles","state":"SERVER REQUIRED","detail":"Keine Projectile-Replica."}
	return {"title":"Projectile · Impact","state":"SERVER REPLICA","detail":"%d aktive Projektile. Lokale Flug/VFX-Interpolation bestätigt niemals Impact oder Schaden."%[(runtime.snapshot().get("projectiles",{}) as Dictionary).size()]}
static func authority()->Dictionary:
	return {"title":"Combat State Authority","state":"SERVER AUTHORITATIVE","detail":"M269 entscheidet Fire/Outcome; M270 hält Reload, Effekte, Sustain und Projectile-Lifecycle. TEST/GLOBAL bleiben isoliert."}
