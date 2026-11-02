extends SceneTree

const QAVideoRecorderScript = preload("res://tools/qa_video_recorder.gd")
const ENTRY_SCENE := "res://scenes/entry.tscn"
const GAME_SCENE := "res://scenes/main.tscn"
const OUTPUT_ROOT := "user://qa_video_m302/"

var _recorder
var _flow_id := ""
var _steps: Array[String] = []
var _warnings: PackedStringArray = []


func _initialize() -> void:
	_flow_id = str(OS.get_environment("QA_VIDEO_FLOW") if OS.has_environment("QA_VIDEO_FLOW") else "")
	if _flow_id.is_empty():
		push_error("QA_VIDEO_FLOW environment variable is required")
		quit(1)
		return
	var fps := 30
	if OS.has_environment("QA_VIDEO_FPS"):
		fps = maxi(1, int(OS.get_environment("QA_VIDEO_FPS")))
	var output_dir := OUTPUT_ROOT.path_join(_flow_id).path_join("frames")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	_recorder = QAVideoRecorderScript.new(self, output_dir, fps)
	call_deferred("_run_flow")


func _run_flow() -> void:
	_recorder.begin()
	match _flow_id:
		"flow_a_entry_sea":
			await _flow_a_entry_sea()
		"flow_b_sea_gameplay":
			await _flow_b_sea_gameplay()
		"flow_c_harbor_poi":
			await _flow_c_harbor_poi()
		"flow_d_combat":
			await _flow_d_combat()
		_:
			push_error("Unknown QA_VIDEO_FLOW: %s" % _flow_id)
			quit(2)
			return
	var summary: Dictionary = _recorder.end()
	_print_done(summary)
	quit(0)


func _print_done(summary: Dictionary) -> void:
	var resolution: Array = summary.get("resolution", [0, 0])
	print(
		"QA_VIDEO_DONE flow_id=%s frames=%d fps=%d resolution=%dx%d steps=%s warnings=%s" % [
			_flow_id,
			int(summary.get("frames", 0)),
			int(summary.get("fps", 30)),
			int(resolution[0]),
			int(resolution[1]),
			",".join(_steps),
			"|".join(_warnings),
		]
	)


func _record_for(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await process_frame
		await RenderingServer.frame_post_draw
		_recorder.tick(1.0 / 60.0)
		elapsed += 1.0 / 60.0


func _wait_until_ready(timeout_frames: int = 600) -> bool:
	for i in timeout_frames:
		var player := get_first_node_in_group("player")
		var world := get_first_node_in_group("world_map")
		if player != null and world != null:
			_steps.append("sea_ready@%d" % i)
			return true
		await process_frame
		await RenderingServer.frame_post_draw
		_recorder.tick(1.0 / 60.0)
	_warnings.append("sea_ready_timeout")
	return false


func _mount_main_scene(sync_guest: bool) -> Node:
	root.set_meta("reconstruction_test_mode", true)
	root.set_meta("environment_id", "LOCAL_DEVELOPMENT")
	if sync_guest:
		root.set_meta("guest_session", true)
		root.set_meta("selected_ship_id", "swift_barco")
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		push_error("Failed to load main scene")
		quit(3)
		return null
	var game := packed.instantiate()
	root.add_child(game)
	return game


func _player() -> Node:
	return get_first_node_in_group("player")


func _world() -> Node:
	return get_first_node_in_group("world_map")


func _camera() -> Node:
	return root.get_viewport().get_camera_3d()


func _flow_a_entry_sea() -> void:
	_steps.append("splash")
	root.set_meta("qa_video_sync_load", true)
	root.set_meta("reconstruction_test_mode", true)
	var entry := (load(ENTRY_SCENE) as PackedScene).instantiate()
	root.add_child(entry)
	await _record_for(1.5)
	_steps.append("login")
	entry._action("continue", "")
	await _record_for(1.0)
	_steps.append("guest")
	entry._action("guest", "")
	await _record_for(1.0)
	_steps.append("home")
	await _record_for(1.2)
	_steps.append("play")
	entry._action("play", "")
	if not await _wait_until_ready(900):
		_warnings.append("entry_sea_load_slow")
	await _record_for(0.8)
	_steps.append("sea_stable")
	await _record_for(8.0)


func _flow_b_sea_gameplay() -> void:
	_steps.append("main_load")
	_mount_main_scene(false)
	if not await _wait_until_ready():
		return
	await _record_for(1.5)
	var player := _player()
	if player != null and player.has_node("PlayerInput"):
		_steps.append("sail_forward")
		var input := player.get_node("PlayerInput")
		input.set_navigation_world_target(player.global_position + Vector3(0.0, 0.0, 48.0), "qa_sail")
	await _record_for(12.0)
	_steps.append("hold")


func _flow_c_harbor_poi() -> void:
	_steps.append("main_load")
	_mount_main_scene(true)
	if not await _wait_until_ready():
		return
	var world := _world()
	var player := _player()
	if world == null or player == null:
		_warnings.append("missing_world_or_player")
		return
	await _record_for(1.0)
	var extent: float = world.sector_spawn_extent()
	var port_position := Vector3(-extent * 0.78, 0.55, extent * 0.68)
	_steps.append("approach_harbor")
	player.global_position = port_position + Vector3(18.0, 0.0, -12.0)
	var camera := _camera()
	if camera != null and "zoom_factor" in camera:
		camera.zoom_factor = 1.35
	if player.has_node("PlayerInput"):
		var input := player.get_node("PlayerInput")
		input.set_navigation_world_target(port_position + Vector3(4.0, 0.0, -3.0), "qa_harbor")
	await _record_for(14.0)
	_steps.append("harbor_hold")


func _flow_d_combat() -> void:
	_steps.append("main_load")
	_mount_main_scene(true)
	if not await _wait_until_ready():
		return
	var player := _player()
	if player == null:
		return
	await _record_for(2.0)
	var enemies := get_nodes_in_group("enemies")
	var wait_frames := 0
	while enemies.is_empty() and wait_frames < 360:
		await process_frame
		await RenderingServer.frame_post_draw
		_recorder.tick(1.0 / 60.0)
		wait_frames += 1
		enemies = get_nodes_in_group("enemies")
	if enemies.is_empty():
		_warnings.append("no_enemy_spawned")
	else:
		_steps.append("enemy_present:%d" % enemies.size())
	if player.has_node("Targeting") and not enemies.is_empty():
		var enemy := enemies[0]
		player.get_node("Targeting").set_target(enemy)
		_steps.append("target_locked")
		var offset: Vector3 = enemy.global_position - player.global_position
		offset.y = 0.0
		if offset.length() > 26.0:
			player.global_position = enemy.global_position - offset.normalized() * 22.0
	if player.has_node("Weapons"):
		var weapons := player.get_node("Weapons")
		weapons.auto_fire = true
		_steps.append("auto_fire_on")
	await _record_for(15.0)
	if player.has_node("Weapons"):
		player.get_node("Weapons").auto_fire = false
	_steps.append("combat_end")
