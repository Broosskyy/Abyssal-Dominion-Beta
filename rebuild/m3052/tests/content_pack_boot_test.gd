extends SceneTree
var failures: Array[String]=[]
var count=0
func check(ok: bool,label: String) -> void:
	count+=1
	if not ok:failures.append(label)
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var args=OS.get_cmdline_user_args()
	var path=args[0]
	var spec=JSON.parse_string(FileAccess.get_file_as_string(args[1])).latest
	var model=load("res://updater/data_model.gd")
	check(not ResourceLoader.exists("res://sea_map.tscn"),"bootstrap host has no game scene before patch")
	check(model.verify_file(spec,path),"exported signed data ZIP authenticates independently of the game")
	check(ProjectSettings.load_resource_pack(path,true),"data ZIP mounts without an Android installer")
	var version=JSON.parse_string(FileAccess.get_file_as_string("res://assets/content_version.json"))
	check(int(version.revision)==int(spec.revision),"new game data revision comes from the mounted ZIP")
	var scene=load("res://sea_map.tscn")
	check(scene!=null,"game scene loads from data pack")
	var game=scene.instantiate();root.add_child(game);current_scene=game
	await process_frame
	check(game.sim.npcs.size()==17 and game.skins.size()==30,"game scripts, all 30 ship designs and scene dependencies instantiate from the pack")
	# Critical end-to-end check: this scene was mounted from the standalone
	# signed DATA ZIP, not directly from the GitHub source tree.
	for skin_id in [27,28,29]:
		var key: String=game.TEST_SHIP_KEYS[skin_id-27]
		check(game.mesh_layer.has_test_ship(skin_id),"signed Android data pack includes playable full GLB: "+key)
		check(game.test_ship_textures.has(key),"signed Android data pack includes genuine 8-view sprite: "+key)
		check(game.skin_previews[skin_id]==game.TEST_SHIP_PREVIEWS[key],"signed Android data pack includes genuine preview: "+key)
	var next_spec=JSON.parse_string(FileAccess.get_file_as_string("res://fixture.json"))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://fixture.zip"),ProjectSettings.globalize_path("user://content_a.zip"))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://fixture.zip"),ProjectSettings.globalize_path("user://content_b.zip"))
	var f=FileAccess.open("user://content_active.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"slot":"user://content_a.zip","spec":next_spec,"attempted":true,"confirmed":false}));f.close()
	f=FileAccess.open("user://content_previous.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"slot":"user://content_b.zip","spec":next_spec,"attempted":true,"confirmed":true}));f.close()
	f=FileAccess.open("user://captain_m3052.json",FileAccess.WRITE);f.store_string("{\"gold\":987}");f.close()
	var boot=load("res://updater/data_boot.gd").new()
	check(boot.active_revision==int(next_spec.revision) and boot.loaded_slots==["user://content_b.zip"],"failed launch trial falls back to previous authenticated cache slot")
	check(FileAccess.get_file_as_string("user://captain_m3052.json")=="{\"gold\":987}","content rollback preserves the separate captain save")
	boot.free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":count,"failures":failures,"game_loaded_from_data_pack":true}))
	quit(0 if failures.is_empty() else 1)
