class_name CapstoneEncounterRoles
extends RefCounted
const PATH:="res://data/m132_capstone_encounter_roles.json"
static func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH));return v if v is Dictionary else {}
static func row(level:int)->Dictionary:return ((data().get("levels",{}) as Dictionary).get(str(level),{}) as Dictionary).duplicate(true)
static func has(level:int)->bool:return not row(level).is_empty()
static func boss_kind(level:int,fallback:String)->String:return str(row(level).get("boss_kind",fallback))
static func boss_slot(level:int,fallback:String)->String:return str(row(level).get("boss_slot",fallback))
static func boss_title(level:int,fallback:String)->String:return str(row(level).get("boss_title",fallback))
static func hunter_slot(level:int)->String:return str(row(level).get("hunter_slot",""))
static func hunter_title(level:int)->String:return str(row(level).get("hunter_title","Hunter Target"))
