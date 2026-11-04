class_name ContentPublishValidator
extends RefCounted

const REF_FIELDS:Dictionary={
	"event":{"npc_ids":"npc","monster_ids":"monster","quests":"quest","shops":"shop","spawn_table_ids":"spawn_table","formation_ids":"formation","admiral_ids":"npc"},
	"quest":{"next_quest_id":"quest"},
	"npc":{"loot_table_id":"loot_table"},
	"monster":{"loot_table_id":"loot_table"},
	"encounter":{"boss_id":"monster"},
}

static func validate_snapshot(snapshot:Dictionary)->PackedStringArray:
	var errors:=PackedStringArray()
	if int(snapshot.get("schema_version",0))<=0:errors.append("schema_version_required")
	if str(snapshot.get("config_version","")).is_empty():errors.append("config_version_required")
	var records:Array=((snapshot.get("content",{}) as Dictionary).get("records",[]))
	var ids:Dictionary={};var type_by_id:Dictionary={}
	for row in records:
		if not row is Dictionary:errors.append("record_invalid");continue
		var id:=str(row.get("id",""));var type_id:=str(row.get("type",""))
		if id.is_empty():errors.append("record_id_required")
		elif ids.has(id):errors.append("duplicate_id:"+id)
		else:ids[id]=true;type_by_id[id]=type_id
		for field in ["behavior_components","objective_components","reward_components","wave_components","phase_components"]:
			if row.get(field,[]) is Array:
				for error in ContentBehaviorEngine.validate_components(row.get(field,[])):errors.append(id+":"+error)
		if type_id=="shop":
			for offer in row.get("offers",[]):
				if offer is Dictionary and str(offer.get("content_id","")).is_empty():errors.append(id+":shop_offer_content_id_required")
		if type_id in ["ship","npc","monster"] and str(row.get("asset_slot","")).is_empty():errors.append(id+":asset_slot_required")
		for p0_error in P0AssetPublishValidator.validate_record(row as Dictionary):errors.append(id+":"+p0_error)
	for row in records:
		if not row is Dictionary:continue
		_validate_references(row as Dictionary,ids,type_by_id,errors)
	_validate_sector_package(records,ids,errors)
	_validate_master_structure(records,errors)
	return errors

static func _validate_references(row:Dictionary,ids:Dictionary,type_by_id:Dictionary,errors:PackedStringArray)->void:
	var id:=str(row.get("id",""));var type_id:=str(row.get("type",""))
	var fields:Dictionary=REF_FIELDS.get(type_id,{})
	for field in fields:
		var expected:=str(fields[field]);var value:Variant=row.get(field,null)
		var refs:Array=value if value is Array else ([] if value==null or str(value).is_empty() else [value])
		for ref_value in refs:
			var ref:=str(ref_value)
			if ids.has(ref):
				if str(type_by_id.get(ref,""))!=expected and not (field=="admiral_ids" and str(type_by_id.get(ref,""))=="npc"):
					errors.append(id+":"+str(field)+":wrong_type:"+ref)
				continue
			var tree:=Engine.get_main_loop() as SceneTree
			if tree!=null and not DynamicContentResolver.by_id(tree,expected,ref).is_empty():continue
			# Stable built-in world/asset references may intentionally live outside content.records.
			if ref.begins_with("NPC-") or ref.begins_with("MON-") or ref.begins_with("SHIP-") or ref.begins_with("POI-") or ref.begins_with("HARBOR-"):continue
			errors.append(id+":"+str(field)+":unknown_ref:"+ref)

static func _validate_sector_package(records:Array,ids:Dictionary,errors:PackedStringArray)->void:
	var package:Dictionary={}
	for row in records:
		if row is Dictionary and str(row.get("type",""))=="sector":package[str(row.get("id",""))]=row
	var opposite:Dictionary={"left":"right","right":"left","up":"down","down":"up"}
	for id in package:
		var row:Dictionary=package[id]
		var neighbors:Dictionary=row.get("neighbors",{})
		var map_position:Array=row.get("map_position",[])
		if map_position.size()<2:errors.append(str(id)+":map_position_required")
		var level:=int(row.get("pirate_level",0))
		if level<1 or level>60:errors.append(str(id)+":pirate_level_out_of_master_range")
		for direction in neighbors:
			var other:=str(neighbors[direction])
			var other_row:Dictionary=package.get(other,{})
			if other_row.is_empty():other_row=WorldSectorRegistry.by_id(other)
			if other_row.is_empty():errors.append(str(id)+":unknown_neighbor:"+other);continue
			var back:Dictionary=other_row.get("neighbors",{})
			var reverse:=str(opposite.get(direction,""))
			if not reverse.is_empty() and str(back.get(reverse,""))!=str(id):
				errors.append(str(id)+":asymmetric_neighbor:"+str(direction)+":"+other)

static func _validate_master_structure(records:Array,errors:PackedStringArray)->void:
	for row in records:
		if not row is Dictionary:continue
		var type_id:=str(row.get("type",""))
		if type_id=="ship":
			var mastery:=int(row.get("mastery_levels",10))
			if mastery<1 or mastery>10:errors.append(str(row.get("id",""))+":ship_mastery_must_be_1_10")
		if type_id=="sector" and int(row.get("pirate_level",1))<1:
			errors.append(str(row.get("id",""))+":invalid_progression_level")

static func publish_request(tree:SceneTree,config_version:String)->Dictionary:
	return AdminActionGuard.request_envelope(tree,"content.publish","publish_snapshot","content_version",config_version)
