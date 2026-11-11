extends SceneTree
var failures: Array[String]=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	await process_frame
	var content=root.get_node_or_null("BrowserContent")
	if content==null:print("FAIL: run against the exported core ZIP");quit(1);return
	content.cache_root="user://browser_delivery_qa_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(content.cache_root)
	content.base_url="" # Catalog must be usable without any extra HTTP request.
	check(content.packs.is_empty() and content.available("ship_designs"),"complete ship catalog is embedded at startup")
	check(ResourceLoader.exists("res://assets/classic_baked/schattenkriegsschiff_shaded.png"),"original captain loads from the actual startup pack")
	check(not content._valid_spec({"file":"../other.zip","sha256":"f".repeat(64),"bytes":1}),"unsafe optional filenames rejected")
	check(await content.ensure("ship_designs"),"catalog is immediately ready without a network connection")
	for level in range(1,11):
		check(load("res://assets/classic_baked/elite_%02d.png" % level) is Texture2D,"Elite atlas is bundled at startup: "+str(level))
		check(load("res://assets/elite_v2/previews/elite_%02d.png" % level) is Texture2D,"Elite preview is bundled at startup: "+str(level))
	for event in ["halloween","columbus"]:
		check(load("res://assets/classic_baked/event_"+event+".png") is Texture2D,"event atlas is bundled at startup: "+event)
		check(load("res://assets/expansion/preview_"+event+".webp") is Texture2D,"event preview is bundled at startup: "+event)
	var second=load("res://web/browser_content.gd").new()
	root.add_child(second)
	await process_frame
	second.cache_root=content.cache_root
	second.base_url=""
	check(await second.ensure("ship_designs"),"catalog stays ready on scene changes without HTTP")
	check(load("res://network_client.gd").PROTOCOL==2,"same cross-platform protocol retained in browser core")
	var game=load("res://sea_map.tscn").instantiate()
	game.browser_classic=true
	root.content_scale_size=Vector2i.ZERO
	root.add_child(game)
	await process_frame
	check(game.sim!=null and game.mesh_layer==null,"real shared game scene boots from the minimal core")
	check(game.classic_atlases.size()==23,"all 23 original ship and design atlases load immediately")
	game._open_modal("Werft")
	check(game.modal.visible and game.modal_kind=="Werft","shipyard opens immediately without waiting for an art pack")
	game._equip(2)
	check(int(game.sim.player.skin)==2,"design equips immediately with the existing simulation")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"isolated_export":true}))
	quit(0 if failures.is_empty() else 1)
