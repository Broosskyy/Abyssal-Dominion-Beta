extends SceneTree
## Regression: 2013-style sea-chart navigation is presentation/input only.
## Run with --headless --path rebuild/m3052 --script tests/classic_navigation_test.gd
var checks:=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:call_deferred("_run")

func _press(game: Node,key: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=key
	event.pressed=true
	game._unhandled_input(event)

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(1280,720)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	game.loading_left=0.0
	var starting_pos: Vector2=game.sim.player.pos
	var ammo: Array=game.sim.player.ammo.duplicate()
	check(game._classic_chart_center().distance_to(starting_pos)<0.01,"locked chart center equals captain position")
	game._shift_camera(Vector2(180,120))
	var inspected: Vector2=game.camera_anchor
	check(not game.camera_locked and inspected.distance_to(starting_pos)>10,"chart panning unlocks follow and changes only the view")
	check(game._classic_chart_center().distance_to(inspected.clamp(Vector2(8,8),game.sim.WORLD-Vector2(8,8)))<.01,"K target is the inspected chart center")
	check(game.sim.player.pos==starting_pos and game.sim.player.ammo==ammo,"camera exploration cannot sail or spend ammunition")
	_press(game,KEY_C)
	check(game.camera_locked and game.pan==Vector2.ZERO,"C recenters and resumes ship following")
	game._shift_camera(Vector2(120,80))
	var expected: Vector2=game._classic_chart_center()
	game._classic_center_course()
	check(game.sim.player.path.is_empty() or Vector2(game.sim.player.path.back()).distance_to(expected)<.01,"K course never silently targets another chart coordinate")
	check(game.sim.player.ammo==ammo,"K camera-course action cannot consume ammunition")
	game.sim.player.path.clear()
	game.modal_tab["Anzeige"]="STEUERUNG"
	game._open_modal("Anzeige")
	var button_labels: Array[String]=[]
	for button: Button in game.modal_body.find_children("*","Button",true,false):button_labels.append(button.text)
	check(button_labels.any(func(label):return "ZUM SCHIFF" in label),"accessible camera recenter action")
	check(button_labels.any(func(label):return "KURS SETZEN" in label),"accessible chart-center navigation action")
	check(button_labels.any(func(label):return "MUNITION" in label),"accessible ammunition action")
	var repairing_before: bool=game.sim.repairing
	_press(game,KEY_R)
	check(game.sim.repairing==repairing_before,"keyboard repair cannot activate behind a settings dialog")
	_press(game,KEY_K)
	check(game.sim.player.path.is_empty(),"keyboard course cannot activate behind a settings dialog")
	game._close_modal()
	_press(game,KEY_M)
	check(game.modal.visible and game.modal_kind=="Menü","M opens the real game menu")
	check(game.sim.player.pos==starting_pos,"navigation shortcuts never move the simulated ship")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
