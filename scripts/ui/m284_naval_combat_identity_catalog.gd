class_name M284NavalCombatIdentityCatalog
extends RefCounted
static func overview(runtime:M284NavalCombatIdentityRuntime)->Dictionary:
	if runtime==null:return {"title":"Naval Combat Identity","state":"SERVER REQUIRED","detail":"Keine M284 Profil-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"Naval Combat Identity","state":"SERVER REPLICA" if int(s.get("profile_revision",-1))>=0 else "WAITING","detail":"rev %d · profiles %d · active %s"%[int(s.get("profile_revision",-1)),int(s.get("profile_count",0)),str(s.get("active_profile_id","—"))]}
static func cannon_families()->Dictionary:return {"title":"Cannon Families","state":"DISTINCT FEEL","detail":"Kanonentypen erhalten eigene Muzzle-, Salvo-, Travel-, Impact- und Audio-Hooks; Werte bleiben Combat-/Content-Autorität."}
static func ammo_harpoon()->Dictionary:return {"title":"Ammo / Harpoon Identity","state":"READABLE","detail":"Munition und Harpunen können eigene Flug-/Impact-/Audio-Profile nutzen, ohne neue Item- oder Trefferautorität."}
static func materials()->Dictionary:return {"title":"Impact Material Profiles","state":"HOOK DRIVEN","detail":"Wasser, Holz/Rumpf, Panzerung, Schild und Monster können unterschiedliche bestätigte Impact-Hooks erhalten."}
static func rhythm()->Dictionary:return {"title":"Salvo Rhythm","state":"PRESENTATION ONLY","detail":"Stagger/Rhythmus formt das Schussgefühl, ändert aber weder Reload, Feuerrate noch Damage-Wahrheit."}
static func audio()->Dictionary:return {"title":"Naval Combat Audio","state":"PROFILED PLAYBACK","detail":"Familienbezogene Fire/Travel/Impact-Audio-Hooks verstärken Identität; Sound bestätigt niemals Treffer."}
static func authority()->Dictionary:return {"title":"Combat Identity Authority","state":"FAIL-CLOSED","detail":"Client darf Motion/Haptics-Zugänglichkeit anpassen, aber keine Damage-, Reload-, Projectile- oder Hit-Wahrheit aus Profilen erzeugen."}
