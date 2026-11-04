class_name M263OnlineAlphaCatalog
extends RefCounted
static func overview(runtime: M263OnlineAlphaRuntime) -> Dictionary:
	var snap := runtime.snapshot()
	if str(snap.get("source","")) != "SERVER": return {"title":"Online Alpha E2E","state":"BACKEND ERFORDERLICH","detail":"LOCAL simuliert keinen erfolgreichen Login, Weltbeitritt, Combat, Persistenz oder Reconnect."}
	return {"title":"Online Alpha E2E","state":runtime.phase(),"detail":"Serververifizierter End-to-End-Zustand · Environment %s"%str(snap.get("environment","?"))}
static func flow(runtime: M263OnlineAlphaRuntime) -> Dictionary:
	var rows := runtime.flow_checks()
	if rows.is_empty(): return {"title":"Login → Welt → Leave","state":"NICHT VERIFIZIERT","detail":"Auth · Account · Session · Join · Sync · Movement · Combat · Persistenz · Reconnect · Leave"}
	var failed := 0
	for row in rows:
		if str(row.get("status","")).to_upper() in ["FAILED","BLOCKED"]: failed += 1
	return {"title":"Login → Welt → Leave","state":"%d BLOCKER"%failed if failed>0 else "SERVER EVIDENZ","detail":"End-to-End-Prüfung bleibt an denselben Build/Environment/Session-Kontext gebunden."}
static func persistence(runtime: M263OnlineAlphaRuntime) -> Dictionary:
	var row := runtime.persistence_state()
	if row.is_empty(): return {"title":"Persistenz & Datenintegrität","state":"SERVER ONLY","detail":"Client bestätigt Ownership, Rewards oder Save-Erfolg niemals selbst."}
	return {"title":"Persistenz & Datenintegrität","state":str(row.get("status","SERVER")),"detail":"Autoritative Persistenz-/Integritätsevidenz aus dem Backend."}
static func reconnect(runtime: M263OnlineAlphaRuntime) -> Dictionary:
	var row := runtime.reconnect_state()
	if row.is_empty(): return {"title":"Disconnect · Reconnect · Resume","state":"SERVER ONLY","detail":"Kein lokales Resume-Ticket, keine Duplikation, kein Fortsetzen veralteter Weltzustände."}
	return {"title":"Disconnect · Reconnect · Resume","state":str(row.get("status","SERVER")),"detail":"Rejoin-Verdict und Weltresync bleiben serverautoritativ."}
static func authority() -> Dictionary:
	return {"title":"Online Authority","state":"SERVER ONLY","detail":"Client sendet Intents; Auth, Session, Movement, Combat, Persistenz, Rejoin und Leave-Ack werden nicht lokal finalisiert."}
