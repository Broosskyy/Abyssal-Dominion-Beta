class_name M268AuthoritativeMovementCatalog
extends RefCounted

static func overview(runtime: M268AuthoritativeMovementRuntime) -> Dictionary:
	if runtime == null: return {"title":"Movement Authority","state":"FOUNDATION","detail":"Live-Movement benötigt World-Replica und Serververdict."}
	var s:=runtime.snapshot()
	if str(s.get("source",""))!="SERVER": return {"title":"Movement Authority","state":"BACKEND ERFORDERLICH","detail":"LOCAL kann Bewegung anfragen/predicten, aber keine Position bestätigen."}
	return {"title":"Movement Authority","state":"SERVER VERIFIZIERT","detail":"Entity %s · Rev %d · Tick %d"%[str(s.get("network_entity_id","?")),int(s.get("movement_revision",-1)),int(s.get("server_tick",-1))]}

static func prediction(runtime: M268AuthoritativeMovementRuntime) -> Dictionary:
	var pending:=int(runtime.snapshot().get("pending_prediction_count",0)) if runtime!=null else 0
	return {"title":"Tap-to-Sail · Prediction","state":"%d PENDING"%pending if pending>0 else "REQUEST ONLY","detail":"Tap-to-Sail sendet Ziel-Intent; Prediction ist ausschließlich visuelles Responsiveness-Layer und niemals Commitbeleg."}

static func reconciliation(runtime: M268AuthoritativeMovementRuntime) -> Dictionary:
	if runtime==null: return {"title":"Reconciliation","state":"SERVER REQUIRED","detail":"Korrekturen benötigen autoritativen Bewegungszustand."}
	var c:=runtime.snapshot().get("correction",{}) as Dictionary
	var kind:=str(c.get("kind","NONE"))
	return {"title":"Reconciliation","state":kind,"detail":"Server-Ack entfernt bestätigte Commands; offene Intents werden nur presentation-seitig erneut angewendet. %s"%str(c.get("reason",""))}

static func abuse_guards() -> Dictionary:
	return {"title":"Movement Integrity","state":"SERVER ONLY","detail":"Speed-, Teleport-, Route-/Collision- und Movement-Revision-Legalität werden serverseitig entschieden; Clientgrenzen sind keine Anti-Cheat-Wahrheit."}

static func authority() -> Dictionary:
	return {"title":"Movement Authority Boundary","state":"SERVER ONLY","detail":"Client darf Position, Velocity, Heading, Command-Acks oder Prediction nie zu Weltwahrheit promoten. TEST und GLOBAL bleiben getrennt."}
