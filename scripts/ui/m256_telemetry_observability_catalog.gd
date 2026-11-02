class_name M256TelemetryObservabilityCatalog
extends RefCounted

static func overview(runtime: M256TelemetryObservabilityRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER":
		return {"title":"TELEMETRIE & OBSERVABILITY","state":"PIPELINE NICHT VERBUNDEN","detail":"Lokale Diagnostik ist nur DEV-Hilfe. Keine Fake-KPIs, Alerts, Revenue-, Economy- oder Live-Service-Werte.","tone":"locked"}
	var snap := runtime.snapshot()
	return {"title":"TELEMETRIE & OBSERVABILITY","state":str(snap.get("pipeline_state","SERVER")).to_upper(),"detail":"%d Metrikgruppen · %d aktive Alerts" % [runtime.health_rows().size(),runtime.alert_rows().size()],"tone":"info"}

static func diagnostic_card(runtime: M256TelemetryObservabilityRuntime) -> Dictionary:
	var row := runtime.diagnostic_summary() if runtime != null else {"buffered":0,"capacity":64}
	return {"title":"LOKALE DIAGNOSTIK","state":"DEV ONLY","detail":"%d/%d gepufferte, bereinigte Events · keine Gameplay-/Economy-Autorität" % [int(row.get("buffered",0)),int(row.get("capacity",64))],"tone":"info"}

static func metric_card(row: Dictionary) -> Dictionary:
	return {"title":str(row.get("label",row.get("id","METRIK"))).to_upper(),"state":str(row.get("state","SERVER")).to_upper(),"detail":str(row.get("summary","Serverbestätigte Operations-/Analytics-Zusammenfassung")),"tone":"ready" if str(row.get("state","")).to_lower() in ["healthy","ok"] else "info"}

static func alert_card(row: Dictionary) -> Dictionary:
	return {"title":"ALERT · %s" % str(row.get("label",row.get("id","SERVICE"))).to_upper(),"state":str(row.get("severity","INFO")).to_upper(),"detail":str(row.get("summary","Server-/Operations-Alert")),"tone":"locked" if str(row.get("severity","")).to_lower() in ["critical","high"] else "info"}

static func privacy_card() -> Dictionary:
	return {"title":"DATENSCHUTZ & LOGGING","state":"MINIMIERT","detail":"Keine Passwörter, Tokens, Raw-Receipts oder vollständigen Paymentdaten in Telemetrie. Retention und Consent bleiben server-/plattformgesteuert.","tone":"ready"}

static func authority_card() -> Dictionary:
	return {"title":"ANALYTICS-AUTORITÄT","state":"SERVER / OPS ONLY","detail":"Analytics darf keine Rewards, Balance, Käufe oder Sanktionen clientseitig bestätigen. GLOBAL und TEST bleiben analytisch getrennt.","tone":"locked"}
