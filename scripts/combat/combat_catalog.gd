class_name CombatCatalog
extends RefCounted

const CANNONS := [
	{"id":"light_culverin","name":"Light Culverin","damage":0.78,"reload":0.72,"speed":1.18,"range":0.92,"role":"rapid","unlock_level":1},
	{"id":"naval_cannon","name":"Naval Cannon","damage":1.0,"reload":1.0,"speed":1.0,"range":1.0,"role":"balanced","unlock_level":1},
	{"id":"long_nine","name":"Long Nine","damage":0.92,"reload":1.12,"speed":1.16,"range":1.28,"role":"marksman","unlock_level":8},
	{"id":"storm_carronade","name":"Storm Carronade","damage":1.32,"reload":0.92,"speed":0.88,"range":0.72,"role":"brawler","unlock_level":14},
	{"id":"heavy_bombard","name":"Heavy Bombard","damage":1.48,"reload":1.48,"speed":0.84,"range":1.12,"role":"siege","unlock_level":20},
	{"id":"abyssal_repeater","name":"Abyssal Repeater","damage":1.08,"reload":0.64,"speed":1.12,"range":0.96,"role":"sustained","unlock_level":28},
	{"id":"sovereign_mortar","name":"Sovereign Mortar","damage":1.72,"reload":1.72,"speed":0.78,"range":1.34,"role":"endgame_siege","unlock_level":40}
]

const AMMO := [
	{"id":"iron", "name":"Iron Shot", "damage":1.0, "armor_pierce":0.10, "slow":0.0, "range":1.0, "crit":0.08, "color":Color("ff9c45"), "role":"baseline", "effect":"none", "effect_power":0.0, "effect_duration":0.0},
	{"id":"explosive", "name":"Blast Shot", "damage":1.22, "armor_pierce":0.02, "slow":0.0, "range":0.92, "crit":0.12, "color":Color("ff512f"), "role":"burst", "effect":"none", "effect_power":0.0, "effect_duration":0.0},
	{"id":"chain", "name":"Chain Shot", "damage":0.66, "armor_pierce":0.0, "slow":0.32, "range":0.86, "crit":0.05, "color":Color("d4efff"), "role":"control", "effect":"none", "effect_power":0.0, "effect_duration":0.0},
	{"id":"piercing", "name":"Piercing Shot", "damage":0.92, "armor_pierce":0.42, "slow":0.0, "range":1.02, "crit":0.07, "color":Color("f2e6b1"), "role":"anti_armor", "effect":"none", "effect_power":0.0, "effect_duration":0.0},
	{"id":"ember", "name":"Ember Shot", "damage":0.88, "armor_pierce":0.04, "slow":0.0, "range":0.94, "crit":0.06, "color":Color("ff7b24"), "role":"fire_dot", "effect":"burn", "effect_power":12.0, "effect_duration":4.0},
	{"id":"venom", "name":"Venom Shot", "damage":0.78, "armor_pierce":0.08, "slow":0.0, "range":0.96, "crit":0.05, "color":Color("72d66b"), "role":"poison_dot", "effect":"venom", "effect_power":8.0, "effect_duration":6.0},
	{"id":"shatter", "name":"Shatter Shot", "damage":0.82, "armor_pierce":0.16, "slow":0.0, "range":0.93, "crit":0.06, "color":Color("b7d7ff"), "role":"armor_break", "effect":"armor_break", "effect_power":0.18, "effect_duration":5.0},
	{"id":"spectral", "name":"Spectral Shot", "damage":1.08, "armor_pierce":0.20, "slow":0.0, "range":1.04, "crit":0.10, "color":Color("b985ff"), "role":"rare_tactical", "effect":"spectral_mark", "effect_power":0.10, "effect_duration":5.0},
	{"id":"gravefire", "name":"Gravefire Shot", "damage":0.96, "armor_pierce":0.10, "slow":0.0, "range":0.96, "crit":0.08, "color":Color("8fd15a"), "role":"halloween_burn", "effect":"burn", "effect_power":10.0, "effect_duration":5.0},
	{"id":"pumpkin", "name":"Pumpkin Round", "damage":1.0, "armor_pierce":0.10, "slow":0.0, "range":1.0, "crit":0.08, "color":Color("e58c35"), "role":"halloween_event", "effect":"none", "effect_power":0.0, "effect_duration":0.0},
]

static func _runtime_array(path:String,fallback:Array)->Array:
	var tree:=Engine.get_main_loop() as SceneTree
	if tree!=null:
		var registry:=LiveConfigRegistry.current(tree)
		if registry!=null:
			var rows:=registry.array(path,[])
			if not rows.is_empty():
				for row in rows:
					if row is Dictionary and row.has("color"):row["color"]=Color(str(row["color"]))
				return rows
	return fallback

static func _m164_extensions(key:String)->Array:
	var path:="res://data/m164_no_code_combat_guild_ui.json"
	if not FileAccess.file_exists(path):return []
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:return []
	return (parsed as Dictionary).get(key,[]) as Array

static func cannon_rows()->Array:
	return DynamicContentResolver.merged(Engine.get_main_loop() as SceneTree,"weapon",_runtime_array("combat.cannons",CANNONS))

static func ammo_rows()->Array:
	var base:Array=_runtime_array("combat.ammo",AMMO).duplicate(true)
	var known:Dictionary={}
	for row in base: if row is Dictionary:known[str(row.get("id",""))]=true
	for row in _m164_extensions("ammo_extensions"):
		if row is Dictionary and not known.has(str(row.get("id",""))):base.append((row as Dictionary).duplicate(true))
	return DynamicContentResolver.merged(Engine.get_main_loop() as SceneTree,"ammo",base)

static func cannon_count()->int:return maxi(1,cannon_rows().size())
static func ammo_count()->int:return maxi(1,ammo_rows().size())
static func ammo_id(index:int)->String:return str(ammo(index).get("id","iron"))
static func ammo_ids()->Array[String]:
	var result:Array[String]=[]
	for row in ammo_rows():
		if row is Dictionary:
			var id:=str(row.get("id",""))
			if not id.is_empty():result.append(id)
	return result

static func ammo_index_by_id(id:String)->int:
	var rows:=ammo_rows()
	for i in rows.size():
		if rows[i] is Dictionary and str(rows[i].get("id",""))==id:return i
	return -1

static func cannon(index: int) -> Dictionary:
	var rows:=cannon_rows()
	return rows[posmod(index,rows.size())]
static func ammo(index: int) -> Dictionary:
	var rows:=ammo_rows()
	return rows[posmod(index,rows.size())]

static func recommended_ammo(distance_ratio: float, target_armor: float) -> int:
	if distance_ratio < 0.72:
		return 1
	if target_armor >= 0.22:
		return 0
	return 2

static func m155_progression_data()->Dictionary:
	var path:="res://data/m155_cannon_progression.json"
	if not FileAccess.file_exists(path):return {}
	var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func cannon_role_profile(cannon_row:Dictionary)->Dictionary:
	var roles:Dictionary=m155_progression_data().get("role_profiles",{})
	return (roles.get(str(cannon_row.get("role","balanced")),{}) as Dictionary).duplicate(true)

static func cannon_upgrade_tier(cannon_upgrade_level:int)->Dictionary:
	var rows:Array=m155_progression_data().get("upgrade_tiers",[])
	if rows.is_empty():return {"tier":1,"label":"Serviceable"}
	var index:=clampi(int(floor(float(maxi(0,cannon_upgrade_level))/2.0)),0,rows.size()-1)
	return (rows[index] as Dictionary).duplicate(true)

static func preferred_ammo_ids(cannon_row:Dictionary)->Array[String]:
	var result:Array[String]=[]
	for id in cannon_role_profile(cannon_row).get("preferred_ammo",[]):result.append(str(id))
	return result
