class_name RewardBundleService
extends GameServiceFacade
var inventory_service:InventoryService
var wallet_service:WalletService
var progression_service:ProgressionService
var entitlement_service:EntitlementService
var local_receipts:Array[Dictionary]=[]
var _local_claimed:Dictionary={}
const MAX_LOCAL_RECEIPTS:=64
func configure(inv:InventoryService,wallet:WalletService,prog:ProgressionService,ent:EntitlementService)->void:
	inventory_service=inv;wallet_service=wallet;progression_service=prog;entitlement_service=ent
func apply(bundle:Dictionary)->Dictionary:
	if not local_only():return {"ok":false,"error":"server_reward_transaction_required"}
	if not bundle.get("entitlements",[]).is_empty():
		return {"ok":false,"error":"local_entitlement_grant_forbidden"}
	var reward_id:=str(bundle.get("reward_id",""))
	if reward_id.is_empty():return {"ok":false,"error":"reward_id_required"}
	if _local_claimed.has(reward_id):
		return {"ok":true,"authority":"local_only","reward_id":reward_id,"duplicate":true,
			"receipt":(_local_claimed[reward_id] as Dictionary).duplicate(true)}
	var receipt:={"ok":true,"authority":"local_only","reward_id":reward_id,
		"reason":str(bundle.get("reason","")),"operations":[],"duplicate":false,
		"local_sequence":local_receipts.size()+1,"timestamp_msec":Time.get_ticks_msec()}
	var coins:=int(bundle.get("coins",0))
	var xp:=int(bundle.get("xp",0))
	if coins!=0 and wallet_service!=null:receipt.operations.append(wallet_service.add_coins(coins,str(bundle.get("reason","reward"))))
	if xp!=0 and progression_service!=null:receipt.operations.append(progression_service.add_xp(xp,str(bundle.get("reason","reward"))))
	var inv:=inventory_service
	for row in bundle.get("items",[]):
		if inv==null:continue
		var id:=str(row.get("id",""));var qty:=int(row.get("quantity",0))
		var result:=inv.set_count(id,inv.count(id)+qty)
		receipt.operations.append(result)
	_local_claimed[reward_id]=receipt.duplicate(true)
	local_receipts.append(receipt.duplicate(true))
	if local_receipts.size()>MAX_LOCAL_RECEIPTS:local_receipts.pop_front()
	return receipt

func receipt_history()->Array[Dictionary]:
	return local_receipts.duplicate(true)

func receipt_summary()->String:
	return "LOCAL REWARD RECEIPTS · %d · same-session dedupe active"%local_receipts.size()
static func bundle(id:String,reason:String,coins:int=0,xp:int=0,items:Array=[])->Dictionary:
	return {"reward_id":id,"reason":reason,"coins":coins,"xp":xp,"items":items.duplicate(true),"entitlements":[]}
