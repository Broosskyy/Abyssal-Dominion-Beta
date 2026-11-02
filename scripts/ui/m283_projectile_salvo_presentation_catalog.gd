class_name M283ProjectileSalvoPresentationCatalog
extends RefCounted
static func overview(runtime:M283ProjectileSalvoPresentationRuntime)->Dictionary:
	if runtime==null:return {"title":"Projectile / Salvo Presentation","state":"SERVER REQUIRED","detail":"Keine M283 Präsentations-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"Projectile / Salvo Presentation","state":"SERVER REPLICA" if int(s.get("presentation_revision",-1))>=0 else "WAITING","detail":"rev %d · projectiles %d · impacts %d"%[int(s.get("presentation_revision",-1)),int(s.get("projectile_count",0)),int(s.get("impact_count",0))]}
static func cannon()->Dictionary:return {"title":"Cannon Salvo Travel","state":"PRESENTATION ONLY","detail":"Serverbestätigte Salven dürfen Muzzle-/Travel-/Impact-Hooks treiben; Flugvisuals erzeugen keinen Treffer."}
static func harpoon()->Dictionary:return {"title":"Harpoon Impact","state":"MONSTER-READABLE","detail":"Harpunen erhalten eigene Launch-/Travel-/Monster-Impact-Hooks ohne Vermischung mit Kanonenautorität."}
static func impacts()->Dictionary:return {"title":"Water / Hull / Monster Impacts","state":"CONFIRMED HOOKS","detail":"Material-/Zieltyp-spezifische Impact-Hooks bleiben visuell; Schaden/Heal/Status kommen weiter aus M269/M270."}
static func audio_haptics()->Dictionary:return {"title":"Audio / Haptics","state":"LOCAL PLAYBACK","detail":"Sound und Mobile-Haptics dürfen serverbestätigte Ereignisse verstärken, bestätigen aber niemals Treffer oder Schaden."}
static func responsive()->Dictionary:return {"title":"Mobile / Desktop Density","state":"SEA-CHART FIRST","detail":"Effektbudgets bleiben layoutabhängig; Kartenmitte, Tap-to-Sail, Attack-Cluster und Kamera-Joystick bleiben lesbar."}
static func authority()->Dictionary:return {"title":"Projectile Presentation Authority","state":"FAIL-CLOSED","detail":"Client kann Darstellung/Audio/Haptics anpassen, aber keine Projectile-Spawns, Impacts, Treffer oder Damage autorisieren; TEST/GLOBAL getrennt."}
