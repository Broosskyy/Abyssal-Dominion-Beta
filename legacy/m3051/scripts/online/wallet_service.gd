class_name WalletService
extends GameServiceFacade
func _progression()->PlayerProgression:
	return player.get_node_or_null("Progression") as PlayerProgression if player!=null else null
func coins()->int:
	var p:=_progression();return p.coins if p!=null else 0
func add_coins(amount:int,reason:String="local_gameplay")->Dictionary:
	if not local_only():return {"ok":false,"error":"server_wallet_repository_required"}
	var p:=_progression()
	if p==null:return {"ok":false,"error":"wallet_unavailable"}
	var tx:=TransactionEnvelope.local("wallet","add_coins",reason,amount,0)
	p.add_coins(amount)
	return {"ok":true,"authority":"local_only","transaction":tx,"balance":p.coins}
