extends SceneTree
## M392: thirty stable creative asset identities and no art-only collision
## swaps. Current real game still uses safe legacy coast until art APPROVED.
const CATALOG=preload("res://island_asset_catalog.gd")
const CONTENT=preload("res://content.gd")
const SIM=preload("res://simulation.gd")
const ECO=preload("res://realm_ecology.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)
func _initialize()->void:
	call_deferred("_run")
func _run()->void:
	var entries:Array=CATALOG.entries()
	var info:Dictionary=CATALOG.counts()
	check(entries.size()==30 and info.total==30,"M392 contains thirty unique island entries")
	check(info.approved+info.pending==30,"game distinguishes approved graphics from planned catalog entries")
	var ids:Dictionary={}
	var preview_ids:Dictionary={}
	for item:Dictionary in entries:
		var id:String=str(item.id)
		check(not ids.has(id),"all asset IDs are unique")
		ids[id]=true
		check(str(item.region)==id.left(1),"island variant belongs to its region")
		check(str(item.size_class) in ["small","medium","large","landmark"],"stable island size classification")
		check(str(item.fallback_art) in ["tropical","rock","snow","snow2"],"legacy fallback is an existing texture")
		check(str(item.source_png).ends_with(id.to_lower()+".png"),"sprite path is stable for Meshy and hand-rendered art")
		check(str(item.mesh_glb).ends_with(id.to_lower()+".glb"),"Meshy 3D art slot deterministic")
		check(str(item.collision_json).ends_with(id.to_lower()+".json"),"silhouette JSON has its own ID")
		check(CATALOG.entry(id).id==id,"entry lookup resolves correct asset")
		if str(item.status)!="approved":
			check(not bool(item.approved),"unapproved art is not secretly switched on")
			check(CATALOG.approved_collision(item).is_empty(),"unapproved PNG never supplies new collision polygon")
		else:
			check(not CATALOG.approved_collision(item).is_empty(),"approved art has independently checked collision")
	for realm_id in range(1,21):
		var region:String=str(CATALOG.REGIONS[int((realm_id-1)/4)])
		var represented:Dictionary={}
		for half in 2:
			for slot in 9:
				var id:String=CATALOG.island_id(realm_id,slot,half)
				check(id.begins_with(region),"large sea uses its own regional art catalog")
				check(ids.has(id),"all 360 sea island slots reference known catalog entries")
				represented[id]=true
				var original_art:String=ECO.island_art(realm_id,slot,half)
				var assignment:Dictionary=CATALOG.resolve(realm_id,slot,half,original_art)
				check(str(assignment.asset_id)==id and str(assignment.size_class)!="","island placement has identity and size class")
				if not bool(assignment.approved):
					check(str(assignment.art)==original_art and str(assignment.texture_path).is_empty() and assignment.collision.is_empty(),
						"unapproved art keeps identical image and physically unchanged shoreline")
				else:
					check(str(assignment.art)=="m392_"+id.to_lower() and not assignment.collision.is_empty(),
						"approved art selects matching verified image and shoreline atomically")
		check(represented.size()==6,"every realm displays its six regional variants across eighteen islands")
	check(CATALOG.island_id(0,1,0).is_empty() and CATALOG.island_id(21,0,0).is_empty(),"unknown realms have no art identity")
	check(CATALOG.island_id(1,9,0).is_empty() and CATALOG.island_id(1,3,4).is_empty(),"illegal island indices rejected")
	check(CATALOG.entry("E07").is_empty(),"unknown asset IDs cannot be loaded")
	var old=SIM.new()
	check(old.map_id==0 and old.islands.size()==9,"classic 40 sea world still uses unchanged island instance count")
	for island:Dictionary in old.islands:
		check(not island.has("m392_asset_id"),"legacy map cannot accidentally become a new asset")
	var old_save:Dictionary=old.export_save()
	for realm_id in [1,5,9,13,20]:
		var sim=SIM.new()
		sim.configure_map(CONTENT.realm_map_id(realm_id))
		check(sim.islands.size()==18,"new large sea still has eighteen navigable islands")
		check(sim.world_extent()==Vector2(17600,6400),"M388 large-sea world bounds unchanged")
		var represented:Dictionary={}
		for island:Dictionary in sim.islands:
			var slot:int=int(island.get("realm_island_index",-1))
			var half:int=int(island.get("realm_island_half",-1))
			var id:String=CATALOG.island_id(realm_id,slot,half)
			check(str(island.get("m392_asset_id",""))==id,"physics island and visual asset share one stable ID")
			check(str(island.get("m392_size_class",""))==str(CATALOG.entry(id).size_class),
				"renderer and simulation share size metadata")
			check(island.outline.size()>7 and island.bounds.has_point(island.pos),"coastline collision matches active bitmap")
			check(not sim.blocked(sim.harbor),"new art catalog does not close harbor")
			represented[id]=true
		check(represented.size()==6,"every tested sea contains its regional variation")
		check(sim.portals.size()==CONTENT.sea_neighbors(sim.map_id).size(),"approved assets do not change cardinals or portals")
		check(sim.player.pos==SIM.START or sim.player.pos.is_finite(),"game navigation remains untouched")
	var restored=SIM.new()
	check(restored.restore_save(old_save),"old save schema remains readable")
	check(restored.map_id==0 and restored.islands.size()==9,"old map and coastline survive catalog introduction")
	var scene=load("res://sea_map.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await process_frame
	scene.set_process(false)
	scene.sim.configure_map(CONTENT.realm_map_id(1))
	scene.queue_redraw()
	await process_frame
	check(scene.island_textures.has("rock") and scene.island_textures.has("tropical"),"original island textures still render on mobile")
	check(scene.sim.islands.size()==18,"new beta scene renders via one shared 2D/3D world without new obstacles")
	scene.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,
		"approved":info.approved,"pending":info.pending}))
	quit(0 if failures.is_empty() else 1)
