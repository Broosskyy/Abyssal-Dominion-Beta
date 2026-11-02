class_name M252OnlineReadinessCatalog
extends RefCounted

static func overview(runtime: M252OnlineReadinessRuntime) -> Dictionary:
	if runtime == null: return {"title":"ONLINE-BEREITSCHAFT","state":"NICHT VERFÜGBAR","detail":"Readiness-Runtime fehlt.","tone":"locked"}
	var snap := runtime.snapshot()
	var server := str(snap.get("source", "")) == "SERVER"
	return {"title":"ONLINE-BEREITSCHAFT","state":"SERVER-SNAPSHOT" if server else "LOCAL / NICHT VERBUNDEN","detail":"%s · Content %s · Client bleibt ohne verifizierten Remote-Adapter nicht autoritativ." % [str(snap.get("environment", "?")), str(snap.get("content_version", "?"))],"tone":"ready" if server else "warning"}

static func capability_card(row: Dictionary) -> Dictionary:
	var available := bool(row.get("available", false))
	return {"title":str(row.get("id", "SERVICE")).replace("_", " ").to_upper(),"state":"BEREIT" if available else "FOUNDATION / GESPERRT","detail":str(row.get("mode", "unknown")) + ("" if str(row.get("reason", "")).is_empty() else " · " + str(row.get("reason", ""))),"tone":"ready" if available else "locked"}

static func isolation_card() -> Dictionary:
	return {"title":"UMGEBUNGS-ISOLATION","state":"VERTRAG AKTIV","detail":"LOCAL, INTERNAL, TEST und GLOBAL dürfen Profile, Wallets, Inventare, Gilden, Rankings, Entitlements und LiveConfig nicht frei vermischen.","tone":"info"}

static func authority_card() -> Dictionary:
	return {"title":"AUTHORITY-GRENZE","state":"FAIL-CLOSED","detail":"Kein Client-Login, lokaler Save, Device-Timestamp oder UI-Zustand darf Serveridentität, Ownership, Revision, Resume oder Transaktionserfolg erzeugen.","tone":"warning"}
