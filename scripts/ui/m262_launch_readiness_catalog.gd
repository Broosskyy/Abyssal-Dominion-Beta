class_name M262LaunchReadinessCatalog
extends RefCounted
static func overview(runtime: M262LaunchReadinessRuntime) -> Dictionary:
	var snap := runtime.snapshot()
	if str(snap.get("source","")) != "RELEASE_OPS": return {"title":"Launch Readiness","state":"NICHT BEWERTET","detail":"LOCAL ist kein Produktionsnachweis. GLOBAL-Freigabe benötigt echte QA-/Operations-Evidenz."}
	return {"title":"Launch Readiness","state":str(runtime.decision().get("state","NOT_EVALUATED")),"detail":"RC-Entscheidung aus verifizierter Release-/Operationsquelle."}
static func candidate(runtime: M262LaunchReadinessRuntime) -> Dictionary:
	var row := runtime.candidate()
	if row.is_empty(): return {"title":"Release Candidate","state":"KEINE EVIDENZ","detail":"Build, Config, Source Revision und Environment müssen zusammen nachgewiesen werden."}
	return {"title":"Release Candidate","state":str(row.get("label",row.get("build_number","RC"))),"detail":"Environment %s · Config %s"%[str(row.get("environment","?")),str(row.get("content_config_version","?"))]}
static func gates(runtime: M262LaunchReadinessRuntime) -> Dictionary:
	var rows := runtime.gate_rows()
	if rows.is_empty(): return {"title":"Cross-Domain Gates","state":"NICHT BEWERTET","detail":"Fehlende Evidenz zählt niemals als PASS."}
	var blocked := 0
	for row in rows:
		if str(row.get("status","")).to_upper() == "BLOCKED": blocked += 1
	return {"title":"Cross-Domain Gates","state":"%d BLOCKER"%blocked if blocked>0 else "EVIDENZ VORHANDEN","detail":"Account · World · Payment · Monitoring · Recovery · Security · Capacity · Device/Network QA"}
static func blockers(runtime: M262LaunchReadinessRuntime) -> Dictionary:
	return {"title":"Release Blocker","state":"%d"%runtime.blocker_rows().size(),"detail":"Blocker dürfen nur durch echte Evidenz oder auditierte privilegierte Waiver aufgelöst werden."}
static func authority() -> Dictionary:
	return {"title":"Promotion Authority","state":"OPS / PIPELINE ONLY","detail":"Client kann GLOBAL nicht freigeben, Blocker nicht überschreiben, Waiver nicht ausstellen und keine Gate-Evidenz erfinden."}
