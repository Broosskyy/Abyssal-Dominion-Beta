class_name M254MailNotificationCatalog
extends RefCounted

static func overview(runtime: M254MailNotificationRuntime) -> Dictionary:
	if runtime == null: return {"title":"MAIL & MITTEILUNGEN","state":"FOUNDATION","detail":"Runtime fehlt; keine Nachrichten werden lokal simuliert.","tone":"locked"}
	var snap := runtime.snapshot()
	if str(snap.get("source", "")) != "SERVER": return {"title":"MAIL & MITTEILUNGEN","state":"SERVER ERFORDERLICH","detail":"Keine Fake-Mails, Claim-Rewards oder Live-Mitteilungen im lokalen Entwicklungsmodus.","tone":"locked"}
	return {"title":"MAIL & MITTEILUNGEN","state":"%d UNGELESEN"%int(snap.get("unread_count",0)),"detail":"%d claimbar · Revision %d"%[int(snap.get("claimable_count",0)),int(snap.get("revision",-1))],"tone":"info"}

static func mail_card(row: Dictionary) -> Dictionary:
	return {"title":str(row.get("title", "SYSTEM-MAIL")),"state":str(row.get("claim_state",row.get("read_state","UNGELESEN"))).replace("_"," ").to_upper(),"detail":str(row.get("body_summary","Servernachricht")),"tone":"ready" if str(row.get("claim_state",""))=="claimed" else "info"}

static func notification_card(row: Dictionary) -> Dictionary:
	return {"title":str(row.get("title","MITTEILUNG")),"state":str(row.get("priority","normal")).to_upper(),"detail":str(row.get("detail",row.get("body_summary","Servermitteilung"))),"tone":"warning" if str(row.get("priority",""))=="critical" else "info"}

static func claim_card(row: Dictionary) -> Dictionary:
	return {"title":"CLAIM-RECEIPT","state":str(row.get("state","confirmed")).to_upper(),"detail":"Server receipt · %s"%str(row.get("receipt_id",row.get("request_id","—"))),"tone":"ready"}

static func authority_card() -> Dictionary:
	return {"title":"MAIL-/CLAIM-AUTORITÄT","state":"SERVER ONLY","detail":"Delivery, Ablauf, Zielgruppe, Claim-Eignung, Settlement, Receipt und Compensation bleiben serverautoritativ. UI-Animationen bestätigen keinen Reward.","tone":"warning"}
