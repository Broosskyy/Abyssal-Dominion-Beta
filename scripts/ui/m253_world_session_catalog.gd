class_name M253WorldSessionCatalog
extends RefCounted

static func overview(runtime: M253WorldSessionRuntime) -> Dictionary:
	if runtime == null: return {"title":"WORLD SESSION","state":"FOUNDATION","detail":"Session-Runtime fehlt; kein Livezustand wird simuliert.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"title":"WORLD SESSION","state":"NICHT VERBUNDEN","detail":"Keine serververifizierte Session. LOCAL bleibt Entwicklungsmodus.","tone":"warning"}
	var conn := runtime.connection_state()
	return {"title":"WORLD SESSION","state":str(conn.get("state","connected")).replace("_"," ").to_upper(),"detail":"Session %s · Revision %d" % [str(snap.get("session_id","?")), int(snap.get("revision",-1))],"tone":"ready" if str(conn.get("state",""))=="connected" else "warning"}

static func world_card(runtime: M253WorldSessionRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"SEEKARTE / CHANNEL","state":"SERVER ERFORDERLICH","detail":"Map, Instanz, Channel und Population werden nicht lokal erfunden.","tone":"locked"}
	var w := runtime.world_state()
	return {"title":"SEEKARTE / CHANNEL","state":str(w.get("map_id","UNBEKANNT")).to_upper(),"detail":"Region %s · Instanz %s · Channel %s · Population %d · World rev %d" % [str(w.get("region_id","?")),str(w.get("instance_id","?")),str(w.get("channel_id","?")),int(w.get("population",0)),int(w.get("world_revision",-1))],"tone":"info"}

static func presence_card(runtime: M253WorldSessionRuntime) -> Dictionary:
	var n := runtime.presence_rows().size() if runtime != null else 0
	var server := runtime != null and str(runtime.snapshot().get("source", "")) == "SERVER"
	return {"title":"PRESENCE","state":"%d SICHTBAR"%n if server else "SERVER ERFORDERLICH","detail":"Nur freigegebene serverpublizierte Präsenzdaten; keine simulierten Online-Spieler.","tone":"info" if server else "locked"}

static func reconnect_card(runtime: M253WorldSessionRuntime) -> Dictionary:
	if runtime == null or str(runtime.snapshot().get("source", "")) != "SERVER": return {"title":"RECONNECT / RESUME","state":"FOUNDATION","detail":"Resume-Ticket und Verdict müssen vom Server kommen.","tone":"locked"}
	var r := runtime.resume_state()
	return {"title":"RECONNECT / RESUME","state":str(r.get("state","unavailable")).replace("_"," ").to_upper(),"detail":"Opaque server-issued resume reference · Client kann Rejoin niemals selbst bestätigen.","tone":"ready" if bool(r.get("server_verified",false)) else "warning"}

static func authority_card() -> Dictionary:
	return {"title":"WORLD-AUTHORITY","state":"SERVER ONLY","detail":"Session-ID, Presence, Map/Instanz/Channel, World Revision, Server Tick und Resume-Verdict bleiben serverautoritativ. Prediction/Interpolation ist nur Darstellung.","tone":"warning"}
