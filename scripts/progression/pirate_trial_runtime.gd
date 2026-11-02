class_name PirateTrialRuntime
extends Node
signal changed
const PATH:="res://data/m123_pirate_trial_runtime.json"
var active_level:=0
var stage_index:=0
var progress:=0
func data()->Dictionary:
	var v:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return v if v is Dictionary else {}
func stages(level:int)->Array:return data().get("trials",{}).get(str(level),{}).get("stages",[])
func start(level:int,inventory:PlayerInventory)->bool:
	if stages(level).is_empty() or inventory==null or not inventory.at_port():return false
	active_level=level;stage_index=0;progress=0;changed.emit();return true
func record(kind:String,amount:int=1)->void:
	if active_level==0:return
	var rows:=stages(active_level)
	if stage_index>=rows.size():return
	var row:Dictionary=rows[stage_index]
	if str(row.get("kind",""))!=kind:return
	progress+=maxi(0,amount)
	if progress>=int(row.get("target",1)):stage_index+=1;progress=0
	changed.emit()
func complete(level:int)->bool:return active_level==level and stage_index>=stages(level).size()
func consume(level:int)->bool:
	if not complete(level):return false
	active_level=0;stage_index=0;progress=0;changed.emit();return true
func summary()->String:
	if active_level==0:return "Keine aktive Prüfung"
	var rows:=stages(active_level)
	if stage_index>=rows.size():return "Prüfung abgeschlossen · im Hafen abgeben"
	var row:Dictionary=rows[stage_index]
	return "%s · %d/%d"%[str(row.get("id","")).replace("_"," ").capitalize(),progress,int(row.get("target",1))]
func export_state()->Dictionary:return {"active_level":active_level,"stage_index":stage_index,"progress":progress}
func import_state(v:Dictionary)->void:
	active_level=int(v.get("active_level",0));stage_index=maxi(0,int(v.get("stage_index",0)));progress=maxi(0,int(v.get("progress",0)));changed.emit()
