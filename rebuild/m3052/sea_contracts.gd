extends RefCounted
## Local repeatable beta content. A fresh acceptance starts a fresh counter baseline.
const ORDER := ["patrol","salvage","hunt"]
const SPECS := {
 "patrol":{"name":"Patrouillenjagd","description":"Versenke 4 NPC-Schiffe. Monster und Türme zählen nicht.","goal":4,"gold":120,"xp":80,"essence":1},
 "salvage":{"name":"Bergungsvertrag","description":"Berge 4 Beutekisten besiegter Gegner.","goal":4,"gold":80,"xp":60,"essence":1},
 "hunt":{"name":"Jagd in der Tiefe","description":"Besiege ein Seeungeheuer mit Harpunen.","goal":1,"gold":100,"xp":75,"essence":1}
}
var entries: Dictionary={}
func counter(sim,key: String) -> int:
 match key:
  "patrol":return maxi(0,int(sim.kills)-int(sim.monster_kills))
  "salvage":return int(sim.loot_collected)
  "hunt":return int(sim.monster_kills)
 return 0
func restore(raw: Variant,sim) -> void:
 entries.clear()
 if not raw is Dictionary:return
 for key: String in ORDER:
  if not raw.has(key):continue
  var stored: Variant=raw.get(key,{})
  if not stored is Dictionary:continue
  var start: Variant=stored.get("start",-1)
  var valid: bool=(start is int or start is float) and is_finite(float(start)) and float(start)>=0.0 and float(start)==floorf(float(start)) and float(start)<=float(counter(sim,key))
  entries[key]={"active":stored.get("active",false)==true and valid,"start":int(start) if valid else counter(sim,key),"completed":clampi(int(stored.get("completed",0)),0,999999)}
func snapshot() -> Dictionary:return entries.duplicate(true)
func info(sim,key: String) -> Dictionary:
 if not SPECS.has(key):return {}
 var data: Dictionary=SPECS[key].duplicate()
 var state: Dictionary=entries.get(key,{})
 data.active=bool(state.get("active",false))
 data.progress=clampi(counter(sim,key)-int(state.get("start",counter(sim,key))),0,int(data.goal)) if data.active else 0
 data.ready=data.active and int(data.progress)>=int(data.goal)
 data.completed=int(state.get("completed",0))
 return data
func ready_count(sim) -> int:
 var count: int=0
 for key: String in ORDER:
  if bool(info(sim,key).ready):count+=1
 return count
func accept(sim,key: String) -> bool:
 if not SPECS.has(key) or sim.staff.active() or bool(entries.get(key,{}).get("active",false)):return false
 var completed: int=int(entries.get(key,{}).get("completed",0))
 entries[key]={"active":true,"start":counter(sim,key),"completed":completed}
 sim.message="Seevertrag angenommen · "+str(SPECS[key].name)
 return true
func claim(sim,key: String) -> bool:
 var data: Dictionary=info(sim,key)
 if data.is_empty() or not bool(data.ready) or sim.staff.active():return false
 # Mark paid before awarding: repeat clicks cannot pay the same round twice.
 entries[key].active=false
 entries[key].completed=mini(999999,int(data.completed)+1)
 sim.player.gold+=int(data.gold);sim.essence+=int(data.essence)
 sim.award_xp(int(data.xp))
 sim.message="Seevertrag erfüllt · +%d Gold · +%d EP · +%d Essenz" % [data.gold,data.xp,data.essence]
 return true
