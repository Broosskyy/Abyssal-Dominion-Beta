extends SceneTree
## Mobile-first contract: exploration missions are accessible and actually
## pay once, without clobbering classic-world logbook or menus.
const SIM=preload("res://simulation.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:
	call_deferred("_run")

func _run()->void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(844,390)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	game.modal_tab["Logbuch"]="REVIER"
	game._open_modal("Logbuch")
	await process_frame
	check(game.modal_body.find_child("RealmMissionClaim",true,false)==null,"old sea has no fake regional reward")
	check(game.modal_body.find_children("*","Button",true,false).any(func(b):return "NEUEN WELTKARTE" in str(b.text)),"old sea points to optional new world")
	game._close_modal()
	check(game.sim.enter_realm_world(),"regional beta world can be entered")
	game._sync_region()
	game.modal_tab["Logbuch"]="REVIER"
	game._open_modal("Logbuch")
	await process_frame
	var claim:Button=game.modal_body.find_child("RealmMissionClaim",true,false)
	check(claim!=null and claim.disabled,"new mission reward starts locked")
	var visible_text:String=""
	for item:Label in game.modal_body.find_children("*","Label",true,false):
		visible_text+=str(item.text)+" "
	check("GEZEITENFUNDE" in visible_text and "HARPUNEN" in visible_text and "Gold" in visible_text,"exploration progress and bounty are readable")
	check(game.modal_tabs.get_children().any(func(b):return str(b.get_meta("menu_tab",""))=="REVIER"),"new logbook tab can be tapped")
	for n in 3:game.sim._realm_mission_record("salvage")
	game.sim._realm_mission_record("hunts")
	game._open_modal("Logbuch")
	await process_frame
	claim=game.modal_body.find_child("RealmMissionClaim",true,false)
	check(claim!=null and not claim.disabled,"claim activates only when real simulation completes mission")
	var gold:int=int(game.sim.player.gold)
	var amount:int=int(game.sim.realm_mission_info().gold)
	if claim!=null:claim.pressed.emit()
	check(int(game.sim.player.gold)==gold+amount,"UI button awards the exact displayed reward")
	check(bool(game.sim.realm_mission_info().claimed),"UI commits one-time completion")
	game._open_modal("Logbuch")
	await process_frame
	claim=game.modal_body.find_child("RealmMissionClaim",true,false)
	check(claim!=null and claim.disabled,"already completed mission no longer allows a second payout")
	check(game.sim.return_to_legacy_world(),"legacy return remains available after mission claim")
	game._sync_region()
	game._open_modal("Logbuch")
	await process_frame
	check(game.modal_body.find_child("RealmMissionClaim",true,false)==null,"old world displays no beta payout")
	game.modal_tab["Logbuch"]="AKTUELL"
	game._open_modal("Logbuch")
	await process_frame
	check(game.modal_body.find_child("ActiveQuest",true,false)!=null,"classic campaign logbook remains functional")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
