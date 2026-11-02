class_name DynamicSpawnPoolResolver
extends RefCounted

static func resolve(tree:SceneTree,sector:Dictionary,region:Dictionary,base_slots:Array)->Dictionary:
	var npc_ids:Array=[]
	var monster_ids:Array=[]
	var admiral_ids:Array=[]
	for value in base_slots:
		npc_ids.append(str(value))
	for value in region.get("npc_slots",[]):
		var id:=str(value)
		if not id.is_empty() and id not in npc_ids:npc_ids.append(id)
	for value in region.get("monster_slots",[]):
		var id:=str(value)
		if not id.is_empty() and id not in monster_ids:monster_ids.append(id)
	var boss:=str(region.get("admiral_slot",region.get("boss_slot","")))
	if not boss.is_empty():admiral_ids.append(boss)
	for value in sector.get("npc_ids",[]):
		var id:=str(value)
		if not id.is_empty() and id not in npc_ids:npc_ids.append(id)
	for value in sector.get("monster_ids",[]):
		var id:=str(value)
		if not id.is_empty() and id not in monster_ids:monster_ids.append(id)
	var sector_admiral:=str(sector.get("admiral_id",""))
	if not sector_admiral.is_empty() and sector_admiral not in admiral_ids:admiral_ids.append(sector_admiral)
	var now:=Time.get_unix_time_from_system()
	for event in DynamicEventResolver.active_events(tree,now):
		var regions:Array=event.get("regions",[])
		var region_id:=str(region.get("id",sector.get("region_id","")))
		if not regions.is_empty() and region_id not in regions:continue
		for value in event.get("npc_ids",[]):
			var id:=str(value)
			if not id.is_empty() and id not in npc_ids:npc_ids.append(id)
		for value in event.get("monster_ids",[]):
			var id:=str(value)
			if not id.is_empty() and id not in monster_ids:monster_ids.append(id)
		for value in event.get("admiral_ids",[]):
			var id:=str(value)
			if not id.is_empty() and id not in admiral_ids:admiral_ids.append(id)
	return {"npc_ids":npc_ids,"monster_ids":monster_ids,"admiral_ids":admiral_ids}

static func select_id(pool:Dictionary,kind:String,index:int)->String:
	var key:="npc_ids"
	if kind=="monster":key="monster_ids"
	elif kind=="admiral":key="admiral_ids"
	var rows:Array=pool.get(key,[])
	return str(rows[posmod(index,rows.size())]) if not rows.is_empty() else ""
