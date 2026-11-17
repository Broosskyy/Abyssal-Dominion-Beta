extends SceneTree
## New optional physical 20-sea world must coexist with the untouched 40.
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
const ATLAS=preload("res://realm_catalog.gd")
var checks:int=0
var failures:Array[String]=[]

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(CONTENT.SEA_MAP_IDS.size()==40 and CONTENT.REALM_MAP_IDS.size()==20,"exactly forty legacy and twenty new physical sea instances")
	check(CONTENT.MAPS.size()==63,"bonus-map and legacy-map indices remain stable")
	for id in range(1,21):
		var map_id: int=CONTENT.realm_map_id(id)
		check(map_id==42+id and CONTENT.realm_id_for_map(map_id)==id,"stable dedicated room ID "+str(id))
		check(ATLAS.realm_for_map(map_id)==id,"real sea corresponds to atlas entry "+str(id))
		check(str(CONTENT.MAPS[map_id].name)==str(ATLAS.realm(id).name),"actual map and conceptual map names match")
		check(bool(CONTENT.MAPS[map_id].realm) and str(CONTENT.MAPS[map_id].code)=="R-%02d" % id,"visible code and independent type")
		check(CONTENT.MAPS[map_id].art.size()==9 and CONTENT.MAPS[map_id].secondary_art.size()==9,"both old island lanes available in sea "+str(id))
		var exits: Dictionary=ATLAS.edge_links(id)
		var destinations: Array[int]=CONTENT.sea_neighbors(map_id)
		check(destinations.size()==exits.size(),"physical and atlas gate counts match")
		for edge: String in exits:
			var neighbor: int=CONTENT.sea_edge_neighbor(map_id,edge)
			check(neighbor==CONTENT.realm_map_id(int(exits[edge])),"physical border resolves correct atlas neighbor")
			check(CONTENT.sea_edge_neighbor(neighbor,ATLAS.opposite_edge(edge))==map_id,"every physical gate has a reverse")
	check(not CONTENT.is_playable_sea_id(3) and not CONTENT.is_playable_sea_id(5),"bonus map IDs never accidentally become sea edges")
	var game=SIM.new()
	check(game.world_extent()==game.WORLD and game.map_id==0,"default mode remains legacy map size")
	var old_pos: Vector2=game.player.pos
	var save_before: Dictionary=game.export_save()
	check(game.enter_realm_world(),"guest may opt into new big sea without teleport purchases")
	check(game.in_realm_world() and game.map_id==43,"level-one guest enters new Karibische See")
	check(game.world_extent()==Vector2(17600,6400),"new sea has physically twice the area")
	check(game.islands.size()==18,"both old lane island groups share one large sea")
	check(game.npcs.size()>=16 and game.npcs.any(func(n):return float(n.pos.x)>8800),"existing enemies populate both halves")
	check(game.portals.size()==2,"corner realm has two classic automatic edge crossings")
	check(not game.blocked(Vector2(13000,3200)),"second half contains navigable water")
	game.level=20
	game.npcs.clear()
	game.player.pos=game.edge_point("east",game.world_extent()*.5)
	game.player.last_hit=game.clock-8.0
	game.step(.1)
	check(game.map_id==44,"sailing across eastern border automatically reaches next real sea")
	check(game.player.pos.x<500 and absf(game.player.pos.y-3200)<10,"east crossing preserves y and appears at west inlet")
	check(game.near_portal()==-1,"arrival does not bounce back to previous map")
	game.configure_map(49) # 7th sea: interior, all four borders
	check(game.portals.size()==4,"interior new realm exposes all four real edges")
	var stored_position: Vector2=Vector2(12600,3200)
	game.player.pos=stored_position
	var save: Dictionary=game.export_save()
	var restored=SIM.new()
	check(restored.restore_save(save),"new-world save is readable under existing schema")
	check(restored.map_id==49 and restored.in_realm_world() and restored.world_extent()==Vector2(17600,6400),"world mode survives relaunch")
	check(restored.player.pos.distance_to(stored_position)<200,"large-world x coordinate is preserved")
	check(restored.return_to_legacy_world(),"player can return to previous forty-map world")
	check(restored.map_id==0 and restored.player.pos==old_pos,"legacy map and exact previous position are restored")
	check(restored.player.gold==game.player.gold and restored.deck_slots==game.deck_slots,"world toggle preserves progress and equipment")
	check(restored.realm_last_map==49,"last played new sea is remembered")
	var old_save: Dictionary=save_before.duplicate(true)
	for key in ["legacy_origin_map","legacy_origin_pos","realm_last_map","realm_last_pos"]:old_save.erase(key)
	var older=SIM.new()
	check(older.restore_save(old_save) and not older.in_realm_world(),"existing saves remain in the old world by default")
	check(older.map_id==0 and older.player.pos==old_pos,"existing saves never migrate without consent")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
