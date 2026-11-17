extends SceneTree
## M386: compare classic edge-only world layouts without mutating M385 gameplay.
const CATALOG=preload("res://realm_catalog.gd")
const CONTENT=preload("res://content.gd")
const SIM=preload("res://simulation.gd")
const OPPOSITE={"east":"west","west":"east","north":"south","south":"north"}
var checks: int=0
var failures: Array[String]=[]

func check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:failures.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	check(CATALOG.REALMS.size()==20,"twenty independent large-sea concepts")
	check(CATALOG.ZONES.size()==5,"five geographic zones")
	check(CONTENT.SEA_MAP_IDS.size()==40,"forty old physical maps remain untouched")
	check(CATALOG.EDGE_MODES==["hybrid","two"],"hybrid classic edges are default, with optional comparison")
	check(CATALOG.DEFAULT_EDGE_MODE=="hybrid","default layout uses 2-4 classic borders")
	var edge_counts: Dictionary={2:0,3:0,4:0}
	var names: Array[String]=[]
	var mapped: Dictionary={}
	for realm_id in range(1,21):
		var data: Dictionary=CATALOG.realm(realm_id)
		check(not data.is_empty() and int(data.id)==realm_id,"stable concept id "+str(realm_id))
		check(not str(data.name) in names,"unique name for concept "+str(realm_id))
		names.append(str(data.name))
		check(int(data.level)==realm_id,"original level progression preserved")
		check(not str(data.harbor).is_empty() and not str(data.landscape).is_empty() and not str(data.encounters).is_empty() and not str(data.activity).is_empty(),"content themes exist")
		check(CATALOG.zone_id(realm_id)==int((realm_id-1)/4),"zone assignment is stable")
		var old: Array[int]=CATALOG.legacy_maps(realm_id)
		check(old.size()==2 and old[0]!=old[1],"two old maps proposed for one large future sea")
		for map_id in old:
			check(map_id in CONTENT.SEA_MAP_IDS and not mapped.has(map_id),"no duplicate or missing mapping "+str(map_id))
			mapped[map_id]=true
			check(CATALOG.realm_for_map(map_id)==realm_id,"old-to-new realm preview is reversible")
		for mode: String in CATALOG.EDGE_MODES:
			var links: Dictionary=CATALOG.edge_links(realm_id,mode)
			check(not links.is_empty(),"every sea has at least one accessible boundary in "+mode)
			check(links.size()<= (2 if mode=="two" else 4),"maximum classic boundaries")
			if mode=="hybrid":edge_counts[links.size()]=int(edge_counts.get(links.size(),0))+1
			var values: Dictionary={}
			for edge: String in links:
				check(edge in OPPOSITE,"only 4 classic cardinal map borders")
				var neighbor: int=int(links[edge])
				check(neighbor>=1 and neighbor<=20 and neighbor!=realm_id,"map edge leads to a valid other sea")
				check(not values.has(neighbor),"each exit has unique immediate destination")
				values[neighbor]=true
				check(CATALOG.edge_neighbor(neighbor,str(OPPOSITE[edge]),mode)==realm_id,"reverse border returns to origin")
				check(neighbor in CATALOG.neighbors(realm_id,mode),"world graph agrees with edge map")
			var route: Array[int]=CATALOG.route(1,realm_id,mode)
			check(not route.is_empty() and route[0]==1 and route.back()==realm_id,"all seas reachable via "+mode)
			for i in range(route.size()-1):
				check(route[i+1] in CATALOG.neighbors(route[i],mode),"each route step is a real adjacent border")
		check(CATALOG.edge_neighbor(realm_id,"north","two")==-1,"two-border mode has no top portal")
		check(CATALOG.edge_neighbor(realm_id,"south","two")==-1,"two-border mode has no bottom portal")
		check(CATALOG.edge_neighbor(realm_id,"west","two")==(realm_id-1 if realm_id>1 else -1),"two-border west is predecessor")
		check(CATALOG.edge_neighbor(realm_id,"east","two")==(realm_id+1 if realm_id<20 else -1),"two-border east is successor")
	check(mapped.size()==40,"all old maps appear exactly once")
	check(edge_counts[2]==4 and edge_counts[3]==10 and edge_counts[4]==6,"20 big seas have exactly 4 corners (2 exits), 10 coast maps (3 exits) and 6 central maps (4 exits)")
	check(CATALOG.edge_neighbor(4,"east","hybrid")==-1,"hybrid world respects east-most world boundary")
	check(CATALOG.edge_neighbor(5,"west","hybrid")==-1,"hybrid world respects west-most world boundary")
	check(CATALOG.edge_neighbor(1,"south","hybrid")==5,"hybrid world uses geographic south")
	check(CATALOG.edge_neighbor(5,"north","hybrid")==1,"hybrid world returns via north")
	for bonus in [3,4,5]:
		check(CATALOG.realm_for_map(bonus)==-1,"bonus world stays independent")
	check(CATALOG.realm(0).is_empty() and CATALOG.realm(21).is_empty(),"out-of-range realms rejected")
	check(CATALOG.edge_links(1,"currents").is_empty() and CATALOG.route(1,20,"currents").is_empty(),"invented shortcut mode not supported")
	check(CATALOG.route(1,20,"two").size()==20,"linear comparison follows classic predecessor/successor")
	check(CATALOG.exit_count(1)==2 and CATALOG.exit_count(7)==4 and CATALOG.exit_count(8)==3,"hybrid exit counts match corners, center and rim")
	check(CATALOG.edge_neighbor(7,"north")==3 and CATALOG.edge_neighbor(7,"south")==11 and CATALOG.edge_neighbor(7,"west")==6 and CATALOG.edge_neighbor(7,"east")==8,"central sea has the correct four real neighbors")
	for edge: String in CATALOG.CARDINAL_EDGES:
		check(CATALOG.opposite_edge(CATALOG.opposite_edge(edge))==edge,"opposite travel side returns home")
	check(CATALOG.entry_position(Vector2(8800,6400),"east",1950)==Vector2(240,1950),"east crossing arrives near destination west side")
	check(CATALOG.entry_position(Vector2(8800,6400),"west",1950)==Vector2(8560,1950),"west crossing arrives near destination east side")
	check(CATALOG.entry_position(Vector2(8800,6400),"north",3500)==Vector2(3500,6160),"north crossing arrives near destination south side")
	check(CATALOG.entry_position(Vector2(8800,6400),"south",3500)==Vector2(3500,240),"south crossing arrives near destination north side")
	check(CATALOG.entry_position(Vector2(8800,6400),"south",5)==Vector2(240,240),"near-corner tangent clamps to safe inset")
	check(CATALOG.entry_position(Vector2(8800,6400),"portal",3500)==Vector2(-1,-1),"unknown edge cannot teleport")
	var sim=SIM.new()
	var before: Dictionary=sim.export_save()
	var position: Vector2=sim.player.pos
	var path: Array=sim.player.path.duplicate(true)
	var map_id: int=sim.map_id
	for mode: String in CATALOG.EDGE_MODES:
		for target in range(1,21):
			CATALOG.route(1,target,mode)
			CATALOG.edge_links(target,mode)
	check(sim.export_save()==before and sim.player.pos==position and sim.player.path==path and sim.map_id==map_id,"both preview layouts leave player, save, collision and movement unchanged")
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
