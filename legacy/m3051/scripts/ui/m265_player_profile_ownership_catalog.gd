class_name M265PlayerProfileOwnershipCatalog
extends RefCounted
static func overview(runtime: M265PlayerProfileOwnershipRuntime) -> Dictionary:
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"title":"Player Profile · Ownership","state":"BACKEND ERFORDERLICH","detail":"Lokale Preview besitzt keine dauerhafte Ownership- oder Progressionsautorität."}
	return {"title":"Player Profile · Ownership","state":"SERVER VERIFIZIERT","detail":"Account/Captain gebunden · Environment %s · Profilrevision %d" % [str(snap.get("environment","?")), int(snap.get("revision",-1))]}
static func ownership(runtime: M265PlayerProfileOwnershipRuntime) -> Dictionary:
	var rows := runtime.ownership_rows()
	if rows.is_empty(): return {"title":"Ownership Ledger","state":"SERVER ONLY","detail":"Schiffe, Designs, Waffen, Equipment, Items, Cosmetics, Companions und Artifacts benötigen dauerhafte Server-Ownership."}
	return {"title":"Ownership Ledger","state":"%d INSTANZEN" % rows.size(),"detail":"Nur serverbestätigte Instanzen gelten als dauerhaft im Besitz."}
static func loadout(runtime: M265PlayerProfileOwnershipRuntime) -> Dictionary:
	var row := runtime.equipment_state()
	if row.is_empty(): return {"title":"Fleet · Equipment · Loadout","state":"FAIL CLOSED","detail":"Equipped-State darf ausschließlich auf tatsächlich owned Instanzen verweisen."}
	return {"title":"Fleet · Equipment · Loadout","state":"SERVER SNAPSHOT","detail":"Loadout-/Equipment-Referenzen wurden aus dem autoritativen Profil geladen."}
static func progression(runtime: M265PlayerProfileOwnershipRuntime) -> Dictionary:
	var p := runtime.progression_state(); var w := runtime.wallet_state()
	if p.is_empty() and w.is_empty(): return {"title":"Progression · Wallet","state":"SERVER ONLY","detail":"Level, Unlocks, Quests und Walletwerte werden nicht aus lokalem Previewzustand bestätigt."}
	return {"title":"Progression · Wallet","state":"SERVER SNAPSHOT","detail":"Progression und Wallet sind Teil derselben persistierten Captain-Wahrheit."}
static func authority() -> Dictionary:
	return {"title":"Profile Authority","state":"SERVER ONLY","detail":"Client kann Ownership/Wallet/Progression nicht vergeben, unowned Items nicht equippen und TEST-Ownership nicht nach GLOBAL übertragen."}
