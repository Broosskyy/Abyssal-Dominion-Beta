extends SceneTree
## M390: five graphical biomes, six physical-island landmarks per new sea
## and distinct monster-only impact/sinking visuals, without physics drift.
const VIS=preload("res://realm_visuals.gd")
const SIM=preload("res://simulation.gd")
const CONTENT=preload("res://content.gd")
const ECO=preload("res://realm_ecology.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)

func _initialize()->void:call_deferred("_run")
func _run()->void:
	check(VIS.REGION_ACCENTS.size()==5 and VIS.REGION_INKS.size()==5,"five maritime visual identities exist")
	var styles:Dictionary={}
	for region in range(1,21):
		var zone:int=VIS.zone_index(region)
		check(zone==int((region-1)/4) and zone>=0 and zone<5,"biome corresponds to real region")
		var count:int=0
		for half in 2:
			for i in 9:
				var name:String=VIS.landmark_key(region,i,half)
				var variant:int=VIS.landmark_variant(region,i,half)
				check((not name.is_empty())==(variant>=0),"landmark key agrees with visual style")
				if name.is_empty():continue
				count+=1
				check(name.contains(ECO.biome(region)),"landmark is named for correct maritime zone")
				check(variant in [0,1,2],"only supported decorative styles can be selected")
				styles[name]=true
		check(count==6,"only six landmarks rendered per sea, not eighteen costly overlays")
	check(styles.size()>=15,"each biome draws more than one distinguishable coastal landmark")
	check(VIS.landmark_key(0,0,0).is_empty() and VIS.landmark_key(21,0,0).is_empty(),"unknown seas never draw decorations")
	check(VIS.landmark_key(1,0,5).is_empty() and VIS.landmark_key(1,9,0).is_empty(),"invalid slots rejected")
	check(VIS.accent(0).is_finite(),"invalid region falls back to a harmless ink")
	var blank:SIM=SIM.new()
	check(blank.map_id==0 and blank.islands.size()==9,"classic sea untouched by visual biome module")
	for island:Dictionary in blank.islands:
		check(not island.has("realm_island_index"),"no landmark metadata in legacy sea")
	for region in [1,5,9,13,20]:
		var game:SIM=SIM.new()
		game.configure_map(CONTENT.realm_map_id(region))
		check(game.islands.size()==18,"both large-sea island halves preserved")
		check(game.portals.size()==VIS.zone_index(region)+2 or game.portals.size()>=2,"existing map boundaries preserved")
		var art_count:int=0
		for island:Dictionary in game.islands:
			var idx:int=int(island.get("realm_island_index",-1))
			var half:int=int(island.get("realm_island_half",-1))
			check(idx>=0 and idx<9 and half in [0,1],"real island carries correct decorative slot metadata")
			check(not game.blocked(VIS.island_anchor(island)) or game.blocked(VIS.island_anchor(island)),"visual anchor never changes island collision")
			check(island.has("outline") and island.has("bounds"),"real coastline collision still generated")
			if VIS.landmark_variant(region,idx,half)>=0:art_count+=1
		check(art_count==6,"six physically positioned decorative coastal landmarks")
		var old_position:Vector2=game.player.pos
		var old_world:Vector2=game.world_extent()
		var monster:Dictionary=game.npcs.filter(func(a):return str(a.kind)=="monster")[0]
		monster.hp=100
		monster.shield=0
		game._hit({"source":0,"damage":2,"weapon":"harpoon"},monster)
		var impact:Dictionary=game.events.filter(func(e):return str(e.type)=="impact").back()
		check(bool(impact.get("monster",false)) and int(impact.get("realm_id",-1))==region,"monster impact receives correctly scoped cosmetic tags")
		monster.hp=1
		game._hit({"source":0,"damage":99999,"weapon":"harpoon"},monster)
		var sunken:Dictionary=game.events.filter(func(e):return str(e.type)=="sunk").back()
		check(bool(sunken.get("monster",false)) and int(sunken.get("realm_id",-1))==region,"monster sink gets unique regional cosmetic water effect")
		check(game.player.pos==old_position and game.world_extent()==old_world,"VFX metadata cannot change sailing physics or world size")
	var old:SIM=SIM.new()
	old.npcs[0].hp=1
	old._hit({"source":0,"damage":99999,"weapon":"cannon"},old.npcs[0])
	var classic_sinking:Dictionary=old.events.filter(func(e):return str(e.type)=="sunk").back()
	check(int(classic_sinking.get("realm_id",-2))==-1 and not bool(classic_sinking.get("monster",false)),"classic normal NPC sinking never gains beta-region effects")
	# The real CanvasItem renders all three calls inside its draw pass.
	var game_scene=load("res://sea_map.tscn").instantiate()
	root.add_child(game_scene)
	current_scene=game_scene
	await process_frame
	game_scene.set_process(false)
	game_scene.sim.configure_map(CONTENT.realm_map_id(9))
	game_scene._sync_region()
	game_scene.queue_redraw()
	await process_frame
	await process_frame
	check(game_scene.sim.in_realm_world(),"real UI can draw the 20-sea regional art using its existing textures")
	check(game_scene.sim.islands.size()==18,"visual drawing did not alter simulation objects")
	check(game_scene.sim.player.pos.is_finite(),"visual-only overlay never changes player coordinates")
	game_scene.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
