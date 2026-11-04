class_name M260CapacityPerformanceCatalog
extends RefCounted

static func overview(runtime: M260CapacityPerformanceRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "CAPACITY_OPS":
		return {"title":"CAPACITY & PERFORMANCE","state":"OPS NICHT VERIFIZIERT","detail":"LOCAL zeigt keine erfundene Serverkapazität. CCU-, Instanz-, Datenbank-, Combat- und Eventgrenzen benötigen gemessene Testdaten.","tone":"locked"}
	return {"title":"CAPACITY & PERFORMANCE","state":"SERVERBESTÄTIGT","detail":"Kapazitäts-, Performance- und Testkampagnenstatus werden read-only aus Operations/QA veröffentlicht.","tone":"info"}

static func capacity(runtime: M260CapacityPerformanceRuntime) -> Dictionary:
	var row := runtime.capacity_health() if runtime != null else {}
	return {"title":"CAPACITY PLANNING","state":str(row.get("state","MESSWERTE AUSSTEHEND")).to_upper(),"detail":"CCU, Spieler je Karte/Instanz, Combatlast, NPC/Monster, Chat, Datenbank, Telemetrie und Eventspitzen werden gemessen statt geraten.","tone":"locked" if row.is_empty() else "info"}

static func resilience(runtime: M260CapacityPerformanceRuntime) -> Dictionary:
	var count := runtime.test_campaign_rows().size() if runtime != null else 0
	return {"title":"LOAD · SOAK · CHAOS","state":"%d KAMPAGNEN" % count if count > 0 else "TESTHARNESS AUSSTEHEND","detail":"Last, lange Sessions, Reconnect/Packet Loss, Worldserver-Restarts und ausgewählte Abhängigkeitsausfälle. Destruktive Tests niemals unkontrolliert auf GLOBAL.","tone":"info" if count > 0 else "locked"}

static func client_performance(runtime: M260CapacityPerformanceRuntime) -> Dictionary:
	var row := runtime.performance_health() if runtime != null else {}
	return {"title":"CLIENT PERFORMANCE","state":str(row.get("state","NATIVE QA AUSSTEHEND")).to_upper(),"detail":"Datengetriebene Render-/VFX-/Wasser-/LOD-/FPS-Profile dürfen Qualität skalieren, aber nicht Welt, Content oder Gameplay zwischen Mobile/Desktop/Web verändern.","tone":"locked" if row.is_empty() else "info"}

static func bottlenecks(runtime: M260CapacityPerformanceRuntime) -> Dictionary:
	var count := runtime.bottleneck_rows().size() if runtime != null else 0
	return {"title":"BOTTLENECKS & GATES","state":"%d VERIFIZIERT" % count if count > 0 else "KEINE LIVE-MESSUNG","detail":"Skalierungsgrenzen und Launch-/Event-Gates dürfen erst aus environment-, build- und configgebundenen Messungen abgeleitet werden.","tone":"info" if count > 0 else "locked"}

static func authority() -> Dictionary:
	return {"title":"PERFORMANCE-AUTORITÄT","state":"OPS / QA ONLY","detail":"Client kann keine Produktionslasttests starten, Autoscaling/Server-Tick verändern, Chaos auf GLOBAL auslösen, Testresultate erfinden oder Capacity-Gates selbst freigeben.","tone":"locked"}
