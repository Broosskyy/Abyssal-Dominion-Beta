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
	content.base_url="http://127.0.0.1:8314/"
	check(not ResourceLoader.exists("res://assets/classic_baked/elite_01.png"),"optional elite is absent from the actual startup pack")
	check(ResourceLoader.exists("res://assets/classic_baked/schattenkriegsschiff_shaded.png"),"original captain loads from the actual startup pack")
	check(not content._valid_spec({"file":"../other.zip","sha256":"f".repeat(64),"bytes":1}),"unsafe optional filenames rejected")
	check(await content.ensure("ship_designs"),"real HTTP optional pack downloads, verifies and mounts")
	check(ResourceLoader.exists("res://assets/classic_baked/elite_01.png"),"elite atlas resolves after mounting")
	check(load("res://assets/classic_baked/elite_01.png") is Texture2D,"imported optional texture decodes")
	check(load("res://assets/elite_v2/previews/elite_01.png") is Texture2D,"shipyard preview resolves after mounting")
	var second=load("res://web/browser_content.gd").new()
	root.add_child(second)
	await process_frame
	second.cache_root=content.cache_root
	second.base_url="" # No network fallback: this must use the verified cache.
	check(await second.ensure("ship_designs"),"repeat visits mount cached bytes without a network request")
	check(await second.ensure("ship_designs"),"repeat equip reuses mounted art")
	check(load("res://network_client.gd").PROTOCOL==1,"same cross-platform protocol retained in browser core")
	var game=load("res://sea_map.tscn").instantiate()
	game.browser_classic=true
	root.content_scale_size=Vector2i.ZERO
	root.add_child(game)
	await process_frame
	check(game.sim!=null and game.mesh_layer==null,"real shared game scene boots from the minimal core")
	game._equip(2)
	check(int(game.sim.player.skin)==2,"optional design can equip with the existing simulation")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"isolated_export":true}))
	quit(0 if failures.is_empty() else 1)
