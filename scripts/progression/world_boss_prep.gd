class_name WorldBossPrep
extends Node
signal changed
var guardian_mechanic_seen:=false
var titan_mechanic_seen:=false
var guardian_clear:=false
var titan_clear:=false
var ancient_admiral_clear:=false
var relic_core_ready:=false
func record_mechanic(kind:String)->void:
	if kind=="relic_barrier":guardian_mechanic_seen=true
	elif kind=="pressure_pulse":titan_mechanic_seen=true
	changed.emit()
func record_clear(slot:String)->void:
	if slot=="monster_ancient_guardian_01":guardian_clear=true
	elif slot=="monster_titan_spawn_01":titan_clear=true
	elif slot=="npc_ancient_admiral":ancient_admiral_clear=true
	changed.emit()
func refresh_inventory(inv:PlayerInventory)->void:relic_core_ready=inv!=null and inv.count("ancient_relic_core")>=1;changed.emit()
func ready()->bool:return guardian_mechanic_seen and titan_mechanic_seen and guardian_clear and titan_clear and ancient_admiral_clear and relic_core_ready
func summary()->String:return "BARRIER %s · PULSE %s · GUARD %s · TITAN %s · ADM %s · CORE %s"%[_ok(guardian_mechanic_seen),_ok(titan_mechanic_seen),_ok(guardian_clear),_ok(titan_clear),_ok(ancient_admiral_clear),_ok(relic_core_ready)]
func _ok(v:bool)->String:return "✓" if v else "○"
func export_state()->Dictionary:return {"guardian_mechanic_seen":guardian_mechanic_seen,"titan_mechanic_seen":titan_mechanic_seen,"guardian_clear":guardian_clear,"titan_clear":titan_clear,"ancient_admiral_clear":ancient_admiral_clear,"relic_core_ready":relic_core_ready}
func import_state(v:Dictionary)->void:
	guardian_mechanic_seen=bool(v.get("guardian_mechanic_seen",false));titan_mechanic_seen=bool(v.get("titan_mechanic_seen",false));guardian_clear=bool(v.get("guardian_clear",false));titan_clear=bool(v.get("titan_clear",false));ancient_admiral_clear=bool(v.get("ancient_admiral_clear",false));relic_core_ready=bool(v.get("relic_core_ready",false));changed.emit()
