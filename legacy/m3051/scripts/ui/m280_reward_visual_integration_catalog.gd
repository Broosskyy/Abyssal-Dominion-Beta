class_name M280RewardVisualIntegrationCatalog
extends RefCounted
static func overview(runtime:M280RewardVisualIntegrationRuntime)->Dictionary:
	if runtime==null:return {"title":"Reward Visual Integration","state":"SERVER REQUIRED","detail":"Keine M280 Reward-Visual-Replica gebunden."}
	var s:=runtime.snapshot(); return {"title":"Reward Visual Integration","state":"SERVER REPLICA" if int(s.get("visual_revision",-1))>=0 else "WAITING","detail":"Encounter %s · visual rev %d"%[str(s.get("encounter_id","UNBOUND")),int(s.get("visual_revision",-1))]}
static func hud()->Dictionary:return {"title":"Combat HUD · Loot Feedback","state":"SEA-CHART FIRST","detail":"Bestätigte Rewards erscheinen kurz unterhalb der Topbar und lassen Mitte, Angriff unten rechts und Kamera-Steuerung unten links frei."}
static func boss_admiral()->Dictionary:return {"title":"Boss / Admiral Reveal","state":"HIGH EMPHASIS","detail":"Boss-/Admiral-Rewards dürfen stärker hervorgehoben werden, bleiben aber kompakt und blockieren weder Targeting noch Tap-to-Sail."}
static func icons()->Dictionary:return {"title":"Reward Icons · Asset Hooks","state":"MASTER-ASSET READY","detail":"Rewarddarstellung referenziert stabile icon_asset_id-Hooks; vorhandene Ammo/Item/Currency-Mastericons werden wiederverwendet, UI-Rahmen bleiben Code/UI-Foundation."}
static func responsive()->Dictionary:return {"title":"Mobile / Desktop Reward Layout","state":"PARITY FOUNDATION","detail":"Safe-Area-aware Breite, kompakter Mobile-Stack und großzügigere Desktop-Abstände; keine Card-in-Card-Überladung."}
static func vfx()->Dictionary:return {"title":"Reward VFX / Motion Hooks","state":"PRESENTATION ONLY","detail":"Reveal/Pulse/Impact-Hooks dürfen lokale Animationen triggern; Timing und VFX bestätigen niemals Besitz, Claim oder Settlement."}
static func authority()->Dictionary:return {"title":"Visual Reward Authority","state":"FAIL-CLOSED","detail":"Client rendert ausschließlich serverbestätigte Rewarddaten. Titel/Rarity/Menge/Icon-Wahrheit, Claim und Settlement bleiben serverseitig; TEST/GLOBAL getrennt."}
