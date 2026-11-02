class_name M281CombatHudConvergenceCatalog
extends RefCounted
static func overview(runtime:M281CombatHudConvergenceRuntime)->Dictionary:
	if runtime==null:return {"title":"Combat HUD Convergence","state":"SERVER REQUIRED","detail":"Keine M281 Combat-HUD-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"Combat HUD Convergence","state":"SERVER REPLICA" if int(s.get("visual_revision",-1))>=0 else "WAITING","detail":"Visual rev %d · server tick %d"%[int(s.get("visual_revision",-1)),int(s.get("server_tick",-1))]}
static func target()->Dictionary:return {"title":"Target Header · Legality","state":"SEA-CHART FIRST","detail":"Targetname, Beziehung, Legalität, Distanz/Range und Boss/Admiral-Hierarchie bleiben kompakt lesbar; M271 ist die Autorität."}
static func reload_ammo()->Dictionary:return {"title":"Reload · Salve · Munition","state":"NAVAL CADENCE","detail":"Großer Angriff unten rechts erhält klare Reload-/Ready-/Range-Rückmeldung; aktive Munition/Waffenfamilie bleibt direkt am Combat-Cluster sichtbar. M269/M270 bleiben autoritativ."}
static func effects()->Dictionary:return {"title":"Buffs · Debuffs · Damage / Heal","state":"PRIORITIZED","detail":"Nur wenige relevante Statuschips und bestätigte Combat-Outcomes werden priorisiert; keine Effektwand über der Seekartenmitte."}
static func boss()->Dictionary:return {"title":"Boss / Admiral Telegraphs","state":"READABLE","detail":"Phasen-/Gefahrenhinweise dürfen stärker auffallen, bleiben aber außerhalb der freien Kartenmitte und blockieren Tap-to-Sail/Targeting nicht."}
static func responsive()->Dictionary:return {"title":"Mobile / Desktop Combat HUD","state":"PARITY FOUNDATION","detail":"Safe Areas, große Touch-Ziele, kompakte Mobile-Hierarchie und großzügigere Desktop-Abstände bei identischer Kampfpriorität."}
static func authority()->Dictionary:return {"title":"Combat Visual Authority","state":"FAIL-CLOSED","detail":"HUD rendert bestätigte M269/M270/M271-Zustände. Clientvisuals autorisieren kein Ziel, keinen Reload, Ammo-Verbrauch, Treffer, Status oder Bossphase; TEST/GLOBAL bleiben getrennt."}
