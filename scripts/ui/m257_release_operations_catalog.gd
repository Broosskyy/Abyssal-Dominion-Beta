class_name M257ReleaseOperationsCatalog
extends RefCounted

static func overview(runtime: M257ReleaseOperationsRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER_OR_RELEASE_PIPELINE":
		return {"title":"RELEASE & BETRIEB","state":"LOCAL DEVELOPMENT","detail":"Keine Fake-Release-, Maintenance-, Feature-Flag- oder Deployment-Autorität. GLOBAL/TEST benötigen bestätigte Operations-Daten.","tone":"locked"}
	var snap := runtime.snapshot()
	return {"title":"RELEASE & BETRIEB","state":str(snap.get("release_state","SERVER")).to_upper(),"detail":"%s · Build %s · Config %s" % [str(snap.get("environment","?")),str(snap.get("build_version","?")),str(snap.get("content_config_version","?"))],"tone":"info"}

static func minimum_version(runtime: M257ReleaseOperationsRuntime) -> Dictionary:
	var gate := runtime.release_gate() if runtime != null else {"state":"NICHT VERBUNDEN","blocking":false,"authority":false}
	return {"title":"MINIMUM VERSION","state":str(gate.get("state","NICHT VERBUNDEN")),"detail":"Pflichtupdates und Kompatibilitätsgrenzen sind server-/releasegesteuert; der Client kann sie nicht umgehen.","tone":"locked" if bool(gate.get("blocking",false)) else "info"}

static func feature_flags(runtime: M257ReleaseOperationsRuntime) -> Dictionary:
	var count := runtime.feature_rows().size() if runtime != null else 0
	return {"title":"FEATURE FLAGS","state":"%d SERVER FLAGS" % count if count > 0 else "KEINE LIVE-DATEN","detail":"Environment-scoped, fail-closed für wert-/wettbewerbskritische Features; keine lokalen GLOBAL-Overrides.","tone":"info"}

static func incident(runtime: M257ReleaseOperationsRuntime) -> Dictionary:
	var row := runtime.incident_summary() if runtime != null else {}
	if row.is_empty(): return {"title":"MAINTENANCE & INCIDENTS","state":"KEIN SERVERSTATUS","detail":"Retry/Statuskommunikation ist vorbereitet; Offlinezustand erzeugt keine autoritative Progression.","tone":"info"}
	return {"title":"MAINTENANCE & INCIDENTS","state":str(row.get("state","ACTIVE")).to_upper(),"detail":str(row.get("summary",row.get("message_key","Serverbestätigter Incident-/Maintenance-Status"))),"tone":"locked" if str(row.get("severity","")).to_lower() in ["critical","high"] else "info"}

static func deployment(runtime: M257ReleaseOperationsRuntime) -> Dictionary:
	var row := runtime.deployment_summary() if runtime != null else {}
	return {"title":"DEPLOYMENT & ROLLBACK","state":str(row.get("state","OPS ONLY")).to_upper(),"detail":"Canary, Promotion, Rollback und Release-Health bleiben Pipeline-/Operations-Aufgaben mit Auditierung.","tone":"locked"}

static func launch_gate() -> Dictionary:
	return {"title":"LAUNCH READINESS","state":"NICHT PRODUKTIONSREIF","detail":"Auth, persistente Ownership, Server-Combat/Economy, Payment, Monitoring, Backup/Restore, Support, Moderation, Minimum-Version und Incident/Rollback müssen gemeinsam produktionsreif sein.","tone":"locked"}
