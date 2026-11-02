class_name AfkRewardService
extends Node

var claims:Dictionary={}
func _ready()->void:add_to_group("afk_reward_service");set_meta("production_authority","SERVER_REQUIRED")
func preview(profile_id:String,offline_seconds:int,catch_up_multiplier:float=1.0,focus_multiplier:float=1.0)->Dictionary:
	var row:=AfkRewardCatalog.profile(profile_id)
	if row.is_empty():return {"ok":false,"error":"unknown_profile"}
	var seconds:=clampi(offline_seconds,0,AfkRewardCatalog.cap_seconds());var hours:=float(seconds)/3600.0
	var catch_cap:=float((AfkRewardCatalog.config.get("caps",{}) as Dictionary).get("catch_up_multiplier_cap",1.5));var mult:=clampf(catch_up_multiplier,1.0,catch_cap)*clampf(focus_multiplier,0.75,1.15)
	var items:Array=[]
	for item in row.get("items_per_hour",[]):
		var quantity:=floori(float(item.get("quantity",0))*hours*mult)
		if quantity>0:items.append({"id":str(item.get("id","")),"quantity":quantity})
	return {"ok":true,"profile_id":profile_id,"seconds":seconds,"capped":offline_seconds>seconds,"gold":floori(float(row.get("gold_per_hour",0))*hours*mult),"world_xp":floori(float(row.get("world_xp_per_hour",0))*hours*mult),"companion_xp":floori(float(row.get("companion_xp_per_hour",0))*hours*mult),"items":items,"authority":"LOCAL_PREVIEW_ONLY","production_requires_trusted_server_time":true,"claim_required":true}
func claim(preview_data:Dictionary,claim_id:String)->Dictionary:
	if not bool(preview_data.get("ok",false)):return {"ok":false,"error":"invalid_preview"}
	if claim_id.is_empty():return {"ok":false,"error":"claim_id_required"}
	if claims.has(claim_id):return {"ok":true,"duplicate":true,"receipt":claims[claim_id]}
	var services:=ServiceLocator.from(get_tree())
	if services==null or services.rewards==null:return {"ok":false,"error":"reward_service_missing"}
	var bundle:=RewardBundleService.bundle("AFK-CLAIM-"+claim_id,"m152_local_afk_preview",int(preview_data.get("gold",0)),int(preview_data.get("world_xp",0)),preview_data.get("items",[]))
	var receipt:=services.rewards.apply(bundle)
	if bool(receipt.get("ok",false)):claims[claim_id]=receipt.duplicate(true)
	return {"ok":bool(receipt.get("ok",false)),"duplicate":bool(receipt.get("duplicate",false)),"receipt":receipt,"companion_xp_preview":int(preview_data.get("companion_xp",0)),"authority":"LOCAL_PREVIEW_ONLY"}
