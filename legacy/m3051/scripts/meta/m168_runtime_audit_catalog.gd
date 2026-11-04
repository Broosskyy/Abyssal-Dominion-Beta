class_name M168RuntimeAuditCatalog
extends Node
const PATH := "res://data/m168_runtime_mobile_menu_audit.json"
var data:Dictionary={}
func _ready()->void:
	add_to_group("m168_runtime_audit_catalog")
	if FileAccess.file_exists(PATH):
		var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:data=parsed
func stations()->Array:return data.get("crafting_station_runtime",[]) as Array
func station(id:String)->Dictionary:
	for row in stations():
		if row is Dictionary and str(row.get("id",""))==id:return (row as Dictionary).duplicate(true)
	return {}
func station_upgrade_cost(id:String,current_level:int)->int:
	var row:=station(id)
	if row.is_empty():return 0
	return int(row.get("base_cost",0))+int(row.get("cost_step",0))*maxi(0,current_level)
func menu_contracts()->Array:return data.get("menu_runtime_contracts",[]) as Array
func mobile()->Dictionary:return (data.get("mobile_polish",{}) as Dictionary).duplicate(true)
