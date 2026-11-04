class_name RepositoryGateway
extends RefCounted
func load_snapshot(_account_id:String)->Dictionary:return {"ok":false,"error":"not_implemented"}
func save_snapshot(_account_id:String,_snapshot:Dictionary,_transaction_id:String)->Dictionary:return {"ok":false,"error":"not_implemented"}
func server_authoritative()->bool:return false

func capabilities()->Dictionary:
	return {"available":false,"mode":"foundation","authoritative":false,"load":false,"save":false,"revision_guard":true,"environment_isolated":true,"reason":"repository_not_implemented"}
