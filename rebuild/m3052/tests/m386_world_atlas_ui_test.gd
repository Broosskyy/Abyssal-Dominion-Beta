extends SceneTree
## M386 UI contract: a usable atlas on a real mobile viewport, with
## correct hybrid borders and no hidden mutations to the active M385 sea.
const REALM=preload("res://realm_chart.gd")
const CATALOG=preload("res://realm_catalog.gd")
var checks: int=0
var failures: Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size=Vector2i.ZERO
	root.size=Vector2i(852,393)
	var game=load("res://sea_map.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await process_frame
	game.set_process(false)
	var before: Dictionary=game.sim.export_save().duplicate(true)
	var old_map: int=game.sim.map_id
	var pos: Vector2=game.sim.player.pos
	var heading: Vector2=game.sim.player.heading
	check(game.realm_edge_mode==CATALOG.DEFAULT_EDGE_MODE,"mixed 2-4 edge world is selected by default")
	game.chart_realm_preview=true
	game._open_modal("Seekarten")
	await process_frame
	var atlas=game.modal_body.find_child("RealmChartPreview",true,false)
	check(atlas!=null,"real world map contains interactive realm atlas")
	if atlas!=null:
		check(atlas.edge_mode=="hybrid","atlas points at real mixed border topology")
		check(atlas.sim==game.sim,"world map reads player state without copying it")
		check(atlas.custom_minimum_size.y>=(1120.0 if game.modal_scroll.size.x<560.0 else 650.0),"responsive atlas reserves enough height for chosen column count")
		atlas.size=Vector2(350,1120)
		check(atlas._columns()==2,"mobile viewport stacks atlas in two columns")
		check(atlas.node_point(20).y+48.0<atlas.size.y-24.0,"twentieth sea card is fully visible")
		check(atlas.node_at(atlas.node_point(11))==11,"each mobile sea is selectable")
		atlas.picked.emit(11)
		check(game.realm_chart_pick==11 and game.chart_realm_preview,"touching sea selects its details without triggering travel")
	await process_frame
	var latest=game.modal_body.find_child("RealmChartPreview",true,false)
	if latest!=null:
		latest.size=Vector2(920,650)
		check(latest._columns()==4,"tablet/desktop atlas uses four columns")
		check(latest.node_point(20).y+48.0<latest.size.y-24.0,"desktop displays all five rows")
	game.realm_edge_mode="two"
	game._open_modal("Seekarten")
	await process_frame
	var comparison=game.modal_body.find_child("RealmChartPreview",true,false)
	check(comparison!=null and comparison.edge_mode=="two","legacy edge-geometry comparison remains accessible")
	game.realm_edge_mode="hybrid"
	game._open_modal("Seekarten")
	check(game.sim.export_save()==before,"opening and switching future charts does not modify game progress")
	check(game.sim.map_id==old_map and game.sim.player.pos==pos and game.sim.player.heading==heading,"atlas selection changes neither sea nor active 2D/3D ship movement")
	game._close_modal()
	game.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
