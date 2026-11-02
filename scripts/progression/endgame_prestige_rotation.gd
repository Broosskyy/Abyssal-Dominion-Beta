class_name EndgamePrestigeRotation
extends Node
signal changed
var unlocked:=false
var cycle:=0
var legendary_sinks:=0
var guardian_sinks:=0
var world_objectives:=0
const GOALS:={"legendary_sinks":5,"guardian_sinks":2,"world_objectives":4}
func unlock()->void:unlocked=true;changed.emit()
func record(kind:String,amount:int=1)->void:
	if not unlocked:return
	if kind=="legendary":legendary_sinks=mini(GOALS.legendary_sinks,legendary_sinks+maxi(0,amount))
	elif kind=="guardian":guardian_sinks=mini(GOALS.guardian_sinks,guardian_sinks+maxi(0,amount))
	elif kind=="world":world_objectives=mini(GOALS.world_objectives,world_objectives+maxi(0,amount))
	changed.emit()
func ready()->bool:return unlocked and legendary_sinks>=GOALS.legendary_sinks and guardian_sinks>=GOALS.guardian_sinks and world_objectives>=GOALS.world_objectives
func claim(inventory:PlayerInventory)->bool:
	if not ready() or inventory==null or not inventory.at_port():return false
	cycle+=1;legendary_sinks=0;guardian_sinks=0;world_objectives=0
	inventory.set_count("dominion_crest",mini(PlayerInventory.MAX_STOCK,inventory.count("dominion_crest")+1))
	changed.emit();return true
func export_state()->Dictionary:return {"unlocked":unlocked,"cycle":cycle,"legendary_sinks":legendary_sinks,"guardian_sinks":guardian_sinks,"world_objectives":world_objectives}
func import_state(v:Dictionary)->void:
	unlocked=bool(v.get("unlocked",false));cycle=maxi(0,int(v.get("cycle",0)))
	legendary_sinks=maxi(0,int(v.get("legendary_sinks",0)));guardian_sinks=maxi(0,int(v.get("guardian_sinks",0)));world_objectives=maxi(0,int(v.get("world_objectives",0)));changed.emit()
