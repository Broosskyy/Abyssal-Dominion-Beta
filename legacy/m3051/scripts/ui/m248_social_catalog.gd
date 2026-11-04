class_name M248SocialCatalog
extends RefCounted

static func overview_card(runtime: M248SocialRuntime) -> Dictionary:
	if runtime == null: return {"title":"SOZIALES","state":"RUNTIME FEHLT","detail":"Social-Replica nicht verfügbar.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER":
		return {"title":"SOZIALES","state":"SERVERDATEN AUSSTEHEND","detail":"Keine Freunde, Gruppenmitglieder, Chatnachrichten oder Profile werden lokal erfunden.","tone":"info"}
	var summary = snap.get("summary", {}); if not summary is Dictionary: summary = {}
	return {"title":"SOZIALES","state":"%d FREUNDE · GRUPPE %d" % [int(summary.get("friend_count", runtime.friend_rows().size())),runtime.group_member_rows().size()],"detail":"Serverbestätigte Social-/Presence-Daten. Mitgliedschaft, Chatdelivery und Moderation bleiben serverautoritativ.","tone":"ready"}

static func friend_card(row: Dictionary) -> Dictionary:
	var state := str(row.get("status", "offline")).to_upper()
	var detail := str(row.get("presence", row.get("region", "")))
	if bool(row.get("in_group", false)): detail = (detail + " · " if not detail.is_empty() else "") + "IN GRUPPE"
	return {"title":str(row.get("display_name", row.get("user_id", "Freund"))),"state":state,"detail":detail,"tone":"ready" if state in ["ONLINE","INGAME"] else "info"}

static func group_card(runtime: M248SocialRuntime) -> Dictionary:
	if runtime == null: return {"title":"FLEET-GRUPPE","state":"NICHT VERFÜGBAR","detail":"","tone":"locked"}
	var group := runtime.group_state()
	if group.is_empty(): return {"title":"FLEET-GRUPPE","state":"KEINE SERVER-GRUPPE","detail":"Normale Gruppen starten als kleine Fleet; Zielgröße zunächst etwa fünf und konfigurierbar.","tone":"info"}
	return {"title":"FLEET-GRUPPE","state":"%d MITGLIEDER" % runtime.group_member_rows().size(),"detail":"Leader · Invite/Kick/Leave · Ready · Target-Pings · Shared Objective Credit · Personal Loot.","tone":"ready"}

static func member_card(row: Dictionary) -> Dictionary:
	var state := "BEREIT" if bool(row.get("ready", false)) else "NICHT BEREIT"
	if bool(row.get("leader", false)): state = "LEADER · " + state
	return {"title":str(row.get("display_name", row.get("user_id", "Mitglied"))),"state":state,"detail":str(row.get("ship", row.get("presence", ""))),"tone":"ready"}

static func chat_card(row: Dictionary) -> Dictionary:
	var channel := str(row.get("channel", "region")).to_upper()
	var author := str(row.get("display_name", row.get("sender_display", "Captain")))
	var staff := str(row.get("verified_staff_role", ""))
	if not staff.is_empty(): author = "[%s] %s" % [staff.to_upper(), author]
	return {"title":"%s · %s" % [channel, author],"state":str(row.get("sent_at_label", "")),"detail":str(row.get("message", "")),"tone":"info"}

static func safety_card(_runtime: M248SocialRuntime) -> Dictionary:
	return {"title":"SICHERHEIT & MODERATION","state":"SERVER REQUIRED","detail":"Block · Mute · Report · Rate Limits · Spam-Schutz · Moderationslogs. Chat besitzt keine Gameplay-Autorität; Staffrollen im Chat sind nur serververifiziert.","tone":"locked"}

static func authority_card(_runtime: M248SocialRuntime) -> Dictionary:
	return {"title":"SOCIAL AUTHORITY","state":"SERVER REQUIRED","detail":"Client kann Freunde, Gruppenstatus, Ready-State, Chatdelivery, Reports oder Contribution-Credit nicht autoritativ festlegen.","tone":"locked"}
