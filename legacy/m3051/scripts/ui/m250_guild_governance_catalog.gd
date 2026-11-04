class_name M250GuildGovernanceCatalog
extends RefCounted

static func overview(runtime: M250GuildGovernanceRuntime) -> Dictionary:
	if runtime == null: return {"title":"GILDE", "state":"SERVER ERFORDERLICH", "detail":"Mitgliedschaft und Rollen werden nicht lokal erfunden.", "tone":"locked"}
	var s := runtime.snapshot()
	if str(s.get("source", "")) != "SERVER": return {"title":"GILDE", "state":"LOKALE VORSCHAU", "detail":"Rollen, Mitglieder, Treasury, Krieg und Diplomatie benötigen Serverdaten.", "tone":"info"}
	var membership: Dictionary = s.get("membership", {})
	return {"title":str(membership.get("guild_name", "GILDE")), "state":str(membership.get("role_label", membership.get("role", "MITGLIED"))).to_upper(), "detail":"%d Mitglieder · Revision %d" % [(s.get("members", []) as Array).size(), runtime.revision], "tone":"ready"}

static func treasury(runtime: M250GuildGovernanceRuntime) -> Dictionary:
	var s := runtime.snapshot() if runtime != null else {}
	if str(s.get("source", "")) != "SERVER": return {"title":"TREASURY & VAULT", "state":"SERVER ERFORDERLICH", "detail":"Keine Fake-Goldwerte, Items oder lokalen Transfers.", "tone":"locked"}
	var t: Dictionary = s.get("treasury", {})
	return {"title":"TREASURY & VAULT", "state":str(t.get("status", "SERVER BESTÄTIGT")).to_upper(), "detail":"Ein-/Auszahlungen folgen Rollen, Limits, Ledger und Audit.", "tone":"active"}

static func diplomacy(runtime: M250GuildGovernanceRuntime) -> Dictionary:
	var s := runtime.snapshot() if runtime != null else {}
	if str(s.get("source", "")) != "SERVER": return {"title":"DIPLOMATIE & ALLIANZEN", "state":"NICHT VERBUNDEN", "detail":"Neutral, Allianz, Feindschaft, Waffenruhe; keine gemeinsame Auto-Treasury.", "tone":"info"}
	return {"title":"DIPLOMATIE & ALLIANZEN", "state":"SERVER BESTÄTIGT", "detail":"%d veröffentlichte Beziehungen" % [(s.get("diplomacy", []) as Array).size()], "tone":"ready"}

static func war(runtime: M250GuildGovernanceRuntime) -> Dictionary:
	var s := runtime.snapshot() if runtime != null else {}
	if str(s.get("source", "")) != "SERVER": return {"title":"GUILD WAR", "state":"SERVER ERFORDERLICH", "detail":"Fleet War, Island Siege, Territory, Resource, Season und Event War bleiben autoritativ.", "tone":"locked"}
	var w: Dictionary = s.get("war", {})
	return {"title":"GUILD WAR", "state":str(w.get("state", "KEIN AKTIVER KRIEG")).to_upper(), "detail":str(w.get("objective_summary", "Eligibility, Zeitfenster und Objectives werden serverseitig veröffentlicht.")), "tone":"active" if not w.is_empty() else "info"}
