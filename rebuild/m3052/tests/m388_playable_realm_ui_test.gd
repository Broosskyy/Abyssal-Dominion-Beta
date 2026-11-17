extends SceneTree
## Actual mobile UI can enter and leave the optional double-width sea world.
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(844,390)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var former: Dictionary=game.sim.export_save()
	var prior_map: int=game.sim.map_id
	var prior_position: Vector2=game.sim.player.pos
	game._open_modal("Seekarten")
	await process_frame
	var buttons: Array=game.modal_body.find_children("*","Button",true,false)
	var go: Button=null
	for item in buttons:
		if "GROSSE SEEKARTEN TESTEN" in str(item.text):go=item;break
	check(go!=null,"mobile map menu contains real beta-world entry button")
	if go!=null:go.pressed.emit()
	await process_frame
	check(game.sim.in_realm_world() and game.sim.map_id==43,"clicking beta button enters a playable new sea")
	check(game.sim.world_extent()==Vector2(17600,6400),"gameplay camera uses double-sized sea physics")
	check(game.ruler.world_size==game.sim.world_extent(),"sea-ruler viewport covers real larger world")
	check(not game.modal.visible,"entering sea closes map selection and displays game")
	game._open_modal("Seekarten")
	await process_frame
	var return_button: Button=null
	for item in game.modal_body.find_children("*","Button",true,false):
		if "KLASSISCHEN WELT ZURÜCK" in str(item.text):return_button=item;break
	check(return_button!=null,"new sea exposes a single-tap return to legacy maps")
	if return_button!=null:return_button.pressed.emit()
	await process_frame
	check(not game.sim.in_realm_world() and game.sim.map_id==prior_map,"return button restores exact legacy sea")
	check(game.sim.player.pos==prior_position and game.ruler.world_size==SIM.WORLD,"return preserves the ship position and old ruler")
	check(game.sim.player.gold==former.gold and game.sim.cannon_slots()==SIM.new().cannon_slots(),"switching to beta does not buy/free-grant equipment")
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
