class_name M264AuthAccountRepositoryCatalog
extends RefCounted
static func overview(runtime: M264AuthAccountRepositoryRuntime) -> Dictionary:
	var snap := runtime.snapshot()
	if str(snap.get("source","")) != "SERVER": return {"title":"Auth · Account · Repository","state":"BACKEND ERFORDERLICH","detail":"Lokales Profil ist keine Live-Identität; persistente Serverdaten werden nicht simuliert."}
	return {"title":"Auth · Account · Repository","state":"SERVER VERIFIZIERT","detail":"Identität und Repository-Status · Environment %s · Revision %d"%[str(snap.get("environment","?")),int(snap.get("revision",-1))]}
static func identity(runtime: M264AuthAccountRepositoryRuntime) -> Dictionary:
	var row := runtime.account_state()
	if row.is_empty(): return {"title":"Identität & Provider","state":"SERVER ONLY","detail":"Guest · E-Mail · Google · Apple vorbereitet; Verifikation und Linking bleiben Backend-Aufgabe."}
	return {"title":"Identität & Provider","state":"VERIFIZIERT","detail":"Account/Captain IDs sind nach Serververifikation unveränderliche Identitätsanker."}
static func repository(runtime: M264AuthAccountRepositoryRuntime) -> Dictionary:
	var row := runtime.repository_state()
	if row.is_empty(): return {"title":"Persistent Repository","state":"NICHT VERBUNDEN","detail":"Load/Commit benötigen Remote Repository, Revision Guard und idempotente Transaktion."}
	return {"title":"Persistent Repository","state":str(row.get("state","SERVER")),"detail":"Serverbestätigter Repository-Zustand; Client-Erfolg ist niemals Commit-Evidenz."}
static func conflicts(runtime: M264AuthAccountRepositoryRuntime) -> Dictionary:
	var row := runtime.last_commit()
	if row.is_empty(): return {"title":"Revision · Konflikte · Migration","state":"FAIL CLOSED","detail":"Revision Conflict, Identity/Environment Mismatch und Migrationen werden nicht lokal überschrieben."}
	return {"title":"Revision · Konflikte · Migration","state":str(row.get("status","SERVER")),"detail":"Letztes Commit-Ergebnis stammt aus dem autoritativen Repository."}
static func authority() -> Dictionary:
	return {"title":"Account Authority","state":"SERVER ONLY","detail":"Client kann Auth nicht verifizieren, IDs nicht vergeben, Repository-Commits nicht bestätigen und TEST nicht nach GLOBAL übertragen."}
