class_name M261CrashClientHealthCatalog
extends RefCounted

static func overview(runtime: M261CrashClientHealthRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "QA_OPS":
		return {"title":"CLIENT HEALTH & QA","state":"NATIVE QA AUSSTEHEND","detail":"LOCAL ist keine Release-Evidenz. Crash-, Geräte-, Netzwerk- und Langzeitdaten benötigen reale Plattform-/QA-Läufe.","tone":"locked"}
	return {"title":"CLIENT HEALTH & QA","state":"OPS / QA VERIFIZIERT","detail":"Crash-, Client-Health-, Netzwerk- und QA-Matrix-Status werden read-only aus der verifizierten Operationsquelle gezeigt.","tone":"info"}

static func crash(runtime: M261CrashClientHealthRuntime) -> Dictionary:
	var row := runtime.crash_health() if runtime != null else {}
	return {"title":"CRASH DIAGNOSTICS","state":str(row.get("state","PROVIDER AUSSTEHEND")).to_upper(),"detail":"Build, Plattform, zulässiger Geräte-/Fehlerkontext und Sessionkorrelation; Secrets, Tokens und Receipts werden nicht in Diagnostik übernommen.","tone":"locked" if row.is_empty() else "info"}

static func device_health(runtime: M261CrashClientHealthRuntime) -> Dictionary:
	var row := runtime.client_health() if runtime != null else {}
	return {"title":"DEVICE HEALTH","state":str(row.get("state","REAL-DEVICE QA AUSSTEHEND")).to_upper(),"detail":"FPS/Frame Time, RAM/VRAM, Batterie, Thermal, Streaming, lange Sessions und Resume. Rendering darf skalieren, Gameplay/Welt nicht.","tone":"locked" if row.is_empty() else "info"}

static func network(runtime: M261CrashClientHealthRuntime) -> Dictionary:
	var row := runtime.network_health() if runtime != null else {}
	return {"title":"NETWORK QA","state":str(row.get("state","PROFILE AUSSTEHEND")).to_upper(),"detail":"Mobile Bandbreite, Jitter, Paketverlust, variable Latenz, Disconnect/Reconnect und Background/Resume; Resume validiert Session statt alten Weltzustand blind fortzusetzen.","tone":"locked" if row.is_empty() else "info"}

static func matrix(runtime: M261CrashClientHealthRuntime) -> Dictionary:
	var count := runtime.qa_run_rows().size() if runtime != null else 0
	return {"title":"DEVICE & ACCOUNT TEST MATRIX","state":"%d VERIFIZIERTE LÄUFE" % count if count > 0 else "ABDECKUNG AUSSTEHEND","detail":"Android-Klassen, iOS, Browser, Desktopziele, Netzwerkprofile und vorbereitete Account-/Progressionszustände. Ein Entwicklergerät reicht nicht als Releasebeleg.","tone":"info" if count > 0 else "locked"}

static func authority() -> Dictionary:
	return {"title":"QA-AUTORITÄT","state":"OPS / QA ONLY","detail":"Client kann Uploadzustand, QA-Gate, Device-Ergebnis oder Crash-Incident nicht selbst bestätigen und TEST/GLOBAL-Ergebnisse nicht vermischen.","tone":"locked"}
