class_name M259SecurityOperationsCatalog
extends RefCounted

static func overview(runtime: M259SecurityOperationsRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SECURITY_SERVER":
		return {"title":"SECURITY POSTURE","state":"SERVER NICHT VERIFIZIERT","detail":"LOCAL zeigt keine Fake-Sicherheitsfreigabe. Rollen, Secrets, Abuse-Fälle und Sanktionen bleiben server-/operationsseitig.","tone":"locked"}
	return {"title":"SECURITY POSTURE","state":"SERVERBESTÄTIGT","detail":"Nur bereinigte Security-Health-Daten werden read-only veröffentlicht; Secret-Material bleibt außerhalb des Clients.","tone":"info"}

static func account(runtime: M259SecurityOperationsRuntime) -> Dictionary:
	var row := runtime.account_security() if runtime != null else {}
	return {"title":"ACCOUNT & SESSION SECURITY","state":str(row.get("state","NICHT VERIFIZIERT")).to_upper(),"detail":"Passwort-Hashing, Rate Limits, Brute-Force-Schutz, Tokenrotation, Sessionverwaltung und zusätzliche Verifikation für sensible Aktionen.","tone":"locked" if row.is_empty() else "info"}

static func secrets() -> Dictionary:
	return {"title":"SECRETS & ENVIRONMENTS","state":"CLIENT-ZUGRIFF GESPERRT","detail":"API-/Store-/Signing-/DB-/Service-/Admin-Secrets bleiben environmentgetrennt im Secret Management; Rotation/Widerruf erfolgen außerhalb des Clients.","tone":"locked"}

static func permissions(runtime: M259SecurityOperationsRuntime) -> Dictionary:
	var row := runtime.permission_health() if runtime != null else {}
	return {"title":"RBAC · LEAST PRIVILEGE","state":str(row.get("state","OPS-AUTORITÄT")).to_upper(),"detail":"Sensible Aktionen sind granular berechtigt und auditierbar. Commerce-, Staff-/Security- und Recovery-Rechte bleiben getrennte Permission-Domänen.","tone":"locked" if row.is_empty() else "info"}

static func anti_abuse(runtime: M259SecurityOperationsRuntime) -> Dictionary:
	var row := runtime.anti_abuse_health() if runtime != null else {}
	return {"title":"ANTI-ABUSE · RATE LIMITS","state":str(row.get("state","SERVER ONLY")).to_upper(),"detail":"Login, Payment, Trade, Bazaar, PvP, Rewards, Inventory, Events, Rankings und Chat: Rate Limits, Replay-Schutz, Plausibilität, Berechtigungsprüfung und Risk-Telemetrie.","tone":"locked" if row.is_empty() else "info"}

static func authority() -> Dictionary:
	return {"title":"SECURITY-AUTORITÄT","state":"SERVER / OPS ONLY","detail":"Client kann keine Staffrolle vergeben, Rechte erhöhen, Secrets lesen/rotieren, Rate Limits abschalten, Abuse bestätigen, kritische Sanktionen aussprechen oder Audits umgehen.","tone":"locked"}
