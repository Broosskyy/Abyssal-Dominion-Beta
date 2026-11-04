class_name ProgressionService
extends GameServiceFacade
func _progression()->PlayerProgression:
	return player.get_node_or_null("Progression") as PlayerProgression if player!=null else null
func snapshot()->Dictionary:
	var p:=_progression();return p.export_state() if p!=null else {}
func add_xp(amount:int,reason:String="local_gameplay")->Dictionary:
	if not local_only():return {"ok":false,"error":"server_progression_repository_required"}
	var p:=_progression()
	if p==null:return {"ok":false,"error":"progression_unavailable"}
	var tx:=TransactionEnvelope.local("progression","add_xp",reason,amount,0)
	p.add_xp(amount);return {"ok":true,"authority":"local_only","transaction":tx}
