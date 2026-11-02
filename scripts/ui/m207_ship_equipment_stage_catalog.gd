class_name M207ShipEquipmentStageCatalog
extends RefCounted
## Visual-only mapping for ship equipment stages. No gameplay authority.

static func stage_for_level(level:int)->int:
	if level<=0:return 0
	if level<=2:return 1
	if level<=4:return 2
	if level<=6:return 3
	if level<=8:return 4
	return 5

static func icon_slot(kind:String,level:int)->String:
	var stage:=stage_for_level(level)
	if stage<=0:return "ui_ship_equipment_"+kind
	return "ui_ship_equipment_stage_%s_%d"%[kind,stage]

static func stage_label(level:int)->String:
	var stage:=stage_for_level(level)
	return ["BASIS","LEICHT","VERSTÄRKT","FORTGESCHRITTEN","SCHWER","MEISTERWERK"][stage]

static func production_hint(kind:String)->String:
	return {
		"hull_armor":"sichtbare Rumpfplatten / Bordwandverstärkung",
		"cannon_battery":"repräsentative Seitenbatterie, nicht Projektil-Spawn-Autorität",
		"sails":"Mast-/Segelverstärkung und Takelage",
		"harpoon_mount":"Monsterjäger-Harpunenhalter / Bugmodul",
		"ram":"Bugramme / verstärkter Steven"
	}.get(kind,"visuelles Ausrüstungsmodul")
