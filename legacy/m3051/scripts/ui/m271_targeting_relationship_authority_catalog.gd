class_name M271TargetingRelationshipAuthorityCatalog
extends RefCounted
static func overview(runtime:M271TargetingRelationshipAuthorityRuntime)->Dictionary:
	if runtime==null:return {"title":"Target Authority","state":"SERVER REQUIRED","detail":"Keine autoritative Targeting-Replica gebunden."}
	var s:=runtime.snapshot(); var target:=s.get("selected_target",{}) as Dictionary
	return {"title":"Targeting · Cycling · Loss","state":"SERVER REPLICA" if int(s.get("targeting_revision",-1))>=0 else "WAITING","detail":"Revision %d · tick %d · target %s"%[int(s.get("targeting_revision",-1)),int(s.get("server_tick",-1)),str(target.get("entity_id","NONE"))]}
static func relationships(runtime:M271TargetingRelationshipAuthorityRuntime)->Dictionary:
	return {"title":"PvP · Group · Guild · Friendly","state":"SERVER ONLY" if runtime!=null else "SERVER REQUIRED","detail":"Feind/Freund, Gruppe, Gilde, Diplomatie und Friendly-Fire-Legalität werden serverseitig bewertet."}
static func zones(runtime:M271TargetingRelationshipAuthorityRuntime)->Dictionary:
	if runtime==null:return {"title":"Safe Zone · Protection","state":"SERVER REQUIRED","detail":"Keine Zonen-/Schutz-Replica."}
	var s:=runtime.snapshot(); return {"title":"Safe Zone · PvP Protection","state":"SERVER REPLICA","detail":"Zone- und Schutzstatus sind Anzeige; der Client kann Schutz oder Safe-Zone-Regeln niemals aufheben."}
static func aggro(runtime:M271TargetingRelationshipAuthorityRuntime)->Dictionary:
	if runtime==null:return {"title":"Aggro · Threat","state":"SERVER REQUIRED","detail":"Keine Aggro-Replica."}
	return {"title":"NPC / Monster Aggro","state":"SERVER REPLICA","detail":"Threat, Aggro, Leash/Target-Loss und Encounter-Zielwahl bleiben serverseitig; lokale Hints sind nur Lesbarkeit."}
static func legality()->Dictionary:
	return {"title":"Kill · Farm · Attack Legality","state":"SERVER AUTHORITATIVE","detail":"M271 muss Attack-Legalität bestätigen, bevor M269 Fire/Outcome auflösen darf. Anti-Farm/Kill-Credit bleibt serverseitig."}
static func authority()->Dictionary:
	return {"title":"Relationship Authority","state":"SERVER AUTHORITATIVE","detail":"Targeting, Beziehungen, Safe Zones, PvP-Schutz und Aggro sind Serverwahrheit. TEST/GLOBAL bleiben isoliert."}
