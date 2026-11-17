extends SceneTree
## M386: validate world blueprint without modifying M385 saves or gameplay.
const CATALOG=preload("res://realm_catalog.gd")
const CONTENT=preload("res://content.gd")
const SIM=preload("res://simulation.gd")
var checks: int=0
var failures: Array[String]=[]

func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(CATALOG.REALMS.size()==20,"twenty independent large-sea concepts")
	check(CATALOG.ZONES.size()==5,"five geography zones")
	check(CONTENT.SEA_MAP_IDS.size()==40,"old forty live map IDs are intact")
	var names: Array[String]=[]
	var mapped: Dictionary={}
	for realm_id in range(1,21):
		var data: Dictionary=CATALOG.realm(realm_id)
		check(not data.is_empty() and int(data.id)==realm_id,"stable prototype realm "+str(realm_id))
		check(not str(data.name) in names,"unique world name "+str(realm_id))
		names.append(str(data.name))
		check(int(data.level)==realm_id,"progression level for realm "+str(realm_id))
		check(not str(data.harbor).is_empty() and not str(data.landscape).is_empty() and not str(data.encounters).is_empty() and not str(data.activity).is_empty(),"biome, activity and spawn theme authored "+str(realm_id))
		check(CATALOG.zone_id(realm_id)==int((realm_id-1)/4),"zone assignment "+str(realm_id))
		var old: Array[int]=CATALOG.legacy_maps(realm_id)
		check(old.size()==2 and old[0]!=old[1],"one proposed realm groups precisely two legacy maps "+str(realm_id))
		for map_id in old:
			check(map_id in CONTENT.SEA_MAP_IDS and not mapped.has(map_id),"unique mapped legacy world "+str(map_id))
			mapped[map_id]=true
			check(CATALOG.realm_for_map(map_id)==realm_id,"reversible map preview "+str(map_id))
		var neighbors: Array[int]=CATALOG.neighbors(realm_id)
		check(not neighbors.is_empty() and not realm_id in neighbors,"realm not isolated "+str(realm_id))
		for neighbor in neighbors:
			check(realm_id in CATALOG.neighbors(neighbor),"all passages bidirectional")
			check(CATALOG.passage_type(realm_id,neighbor)!="","every edge has an authored passage type")
		var route: Array[int]=CATALOG.route(1,realm_id)
		check(not route.is_empty() and route[0]==1 and route.back()==realm_id,"all realms reachable from starting sea "+str(realm_id))
	check(mapped.size()==40,"no old world missing or duplicated in the migration map")
	for bonus in [3,4,5]:
		check(CATALOG.realm_for_map(bonus)==-1,"bonus world never merged into a normal sea")
	check(CATALOG.realm(0).is_empty() and CATALOG.realm(21).is_empty(),"invalid realm access refused")
	check(CATALOG.neighbors(-1).is_empty() and CATALOG.route(-1,1).is_empty(),"invalid journey refused")
	check(CATALOG.passage_type(1,20).is_empty(),"no invented direct fast travel")
	# Truly isolate preview from all gameplay, multiplayer, movement and saves.
	var sim=SIM.new()
	var before: Dictionary=sim.export_save()
	var player_position: Vector2=sim.player.pos
	var player_path: Array=sim.player.path.duplicate(true)
	var current: int=sim.map_id
	var ignored: Array[int]=CATALOG.route(1,20)
	check(not ignored.is_empty(),"world graph has a spanning route")
	check(sim.export_save()==before and sim.player.pos==player_position and sim.player.path==player_path and sim.map_id==current,"catalog browsing cannot change player save, heading, physics or map id")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
