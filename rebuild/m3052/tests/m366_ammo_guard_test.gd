extends SceneTree
## Isolated mobile menu regression. The full release build also executes
## ammo_picker_test with its final imported mipmapped ship artwork.
var checks:=0
var failures: Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game);current_scene=game
	await process_frame
	game.set_process(false)
	var initial: Vector2=game.sim.player.pos
	var route: Array=game.sim.player.path.duplicate(true)
	var heading: Vector2=game.sim.player.heading
	game._open_modal("Munition")
	check(game.modal.visible and game.modal_kind=="Munition","ammunition picker opens as modal")
	game._choose_ammo(3)
	check(not game.modal.visible and not game.modal_backdrop.visible,"choosing ammunition closes menu and removes chart blocker")
	check(game.suppress_tap_until-Time.get_ticks_msec()>200,"touch-release suppression starts AFTER heavy picker refresh, not before")
	check(game.sim.ammo_mode==3,"selected round stays active")
	check(game.sim.player.pos==initial and game.sim.player.path==route and game.sim.player.heading==heading,"picker never issues a new ship route or turn")
	game.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
