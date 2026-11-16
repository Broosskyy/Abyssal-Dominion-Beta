extends SceneTree
## M377: mobile menu inertia taps must not activate hidden buttons;
## decorative HUD animations are throttled independently from gameplay.
const HUD_BUTTON=preload("res://nautical_button.gd")
const TOUCH_SCROLL=preload("res://touch_scroll.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(800,450)
	var button=HUD_BUTTON.new()
	button.size=Vector2(100,100)
	root.add_child(button)
	await process_frame
	button.set_process(false)
	button.motion_enabled=true
	button.latched=true
	button.decorative_frame_elapsed=0.0
	button._process(0.016)
	check(is_equal_approx(button.decorative_frame_elapsed,0.016),"decorative HUD frame budget accumulates time without forcing 60Hz redraw")
	button._process(0.016)
	check(is_equal_approx(button.decorative_frame_elapsed,0.032),"decorative HUD frame budget retains sub-50ms work")
	button._process(0.020)
	check(absf(button.decorative_frame_elapsed-0.002)<0.0001,"HUD decoration schedules at 20 FPS rather than rendering every game frame")
	button.latched=false
	button._process(0.020)
	check(button.decorative_frame_elapsed==0.0,"idle or inactive HUD animations stop using CPU budget")
	button._press_visual()
	check(button.press_reaction>0.0,"user button presses still produce immediate feedback")

	var scroll=TOUCH_SCROLL.new()
	scroll.position=Vector2(30,30)
	scroll.size=Vector2(260,160)
	var contents=Control.new()
	contents.custom_minimum_size=Vector2(220,1200)
	scroll.add_child(contents)
	root.add_child(scroll)
	await process_frame
	scroll.set_process(false)
	scroll.velocity=900.0
	var tap=InputEventScreenTouch.new()
	tap.index=0
	tap.pressed=true
	tap.position=scroll.get_global_rect().get_center()
	scroll._input(tap)
	check(scroll.velocity==0.0 and not scroll.pressing and scroll.active_touch==-1,"tapping during momentum stops scroll without arming a hidden button press")
	check(scroll.swallow_until>0,"inertia-stop gesture temporarily suppresses emulated duplicate mouse press")
	var release=InputEventScreenTouch.new()
	release.index=0
	release.pressed=false
	release.position=tap.position
	scroll._input(release)
	check(not scroll.pressing and scroll.active_touch==-1,"releasing an inertia-stop tap does not start a new gesture")
	scroll.swallow_until=0
	scroll._input(tap)
	check(scroll.pressing and scroll.active_touch==0,"a later intentional tap still starts a normal menu gesture")
	scroll._input(release)
	check(not scroll.pressing and scroll.active_touch==-1,"normal menu touch still releases cleanly")
	scroll.queue_free()
	button.queue_free()
	print(JSON.stringify({"checks":checks,"failures":failures,"status":"PASS" if failures.is_empty() else "FAIL"}))
	quit(0 if failures.is_empty() else 1)
