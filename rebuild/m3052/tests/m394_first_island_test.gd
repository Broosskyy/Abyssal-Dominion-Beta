extends SceneTree
## M394: first user-supplied real island, image+reviewed shoreline atomically
## active in the 20-realm beta. Existing 40 seas and bonus maps unchanged.
const CATALOG=preload("res://island_asset_catalog.gd")
const CONTENT=preload("res://content.gd")
const SIM=preload("res://simulation.gd")
var checks:int=0
var failures:Array[String]=[]
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures.append(label)

func _initialize()->void:
	call_deferred("_run")

func _run()->void:
	var descriptor:Dictionary=CATALOG.entry("A01")
	var summary:Dictionary=CATALOG.counts()
	check(summary.total==30 and summary.approved==1 and summary.pending==29,"exactly first A01 art approved, 29 still safe fallback")
	check(descriptor.status=="approved" and bool(descriptor.approved) and bool(descriptor.collision_reviewed),"manual A01 artist and shoreline reviews recorded")
	check(str(descriptor.source_png)=="res://assets/m392/islands/a01.png","actual user-supplied PNG has its expected resource path")
	check(ResourceLoader.exists(str(descriptor.source_png)),"Godot actually imported the new RGBA PNG")
	var texture:Texture2D=load(str(descriptor.source_png))
	check(texture!=null and texture.get_size()==Vector2(512,512),"alpha artwork actually loads at verified game resolution")
	var shape:Dictionary=CATALOG.approved_collision(descriptor)
	check(not shape.is_empty() and shape.points.size()==20 and shape.size==[512,512],"reviewed A01 polygon embedded alongside artwork")
	var fallback:Dictionary=CATALOG.resolve(5,0,0,"rock")
	check(not bool(fallback.approved) and str(fallback.art)=="rock","unapproved region B art still uses original rock")
	var before=SIM.new()
	check(before.map_id==0 and before.islands.size()==9,"historical 40 sea maps remain untouched")
	check(before.islands.all(func(item):return not item.has("m392_asset_id")),"classic islands have no new art keys")
	var backup:Dictionary=before.export_save()
	for realm_id in range(1,5):
		var world=SIM.new()
		world.configure_map(CONTENT.realm_map_id(realm_id))
		var new_islands:Array=world.islands.filter(func(item):return str(item.get("m392_asset_id",""))=="A01")
		check(new_islands.size()>=1,"A01 image is physically placed in beta sea "+str(realm_id))
		check(world.portals.size()==CONTENT.sea_neighbors(world.map_id).size(),"A01 changes no world edge exits")
		check(world.world_extent()==Vector2(17600,6400),"A01 changes no beta world coordinate extents")
		check(not world.blocked(world.harbor),"real sea harbor does not get blocked by new coastline")
		check(not world.plan_path(SIM.START,world.harbor).is_empty(),"navigation from starting sea to harbor stays open")
		for island:Dictionary in new_islands:
			check(str(island.art)=="m392_a01" and str(island.get("m392_art_source",""))=="approved","actual A01 appears instead of fallback")
			check(str(island.get("m392_texture_path",""))==str(descriptor.source_png),"A01 scene uses exact verified PNG")
			check(island.outline.size()==20 and island.bounds.size.length()>10,"A01 has visible polygon and nonempty collision bounds")
			var dimensions:Vector2=Vector2(float(island.width),float(island.width))
			var expected:Vector2=Vector2(island.pos)+(Vector2(shape.points[0][0],shape.points[0][1])-Vector2(.5,.65))*dimensions
			check(island.outline[0].distance_to(expected)<.02,"world coastline is pixel-aligned to drawn island base")
			var centroid:Vector2=Vector2.ZERO
			for p:Vector2 in island.outline:centroid+=p
			centroid/=float(island.outline.size())
			check(world.blocked(centroid,16.0),"solid coast blocks ship center, not the vertical rock spire")
			var west:Vector2=Vector2(island.pos.x-710,island.pos.y+float(island.width)*.13)
			var east:Vector2=Vector2(island.pos.x+710,island.pos.y+float(island.width)*.13)
			check(not world.blocked(west) and not world.blocked(east),"left and right navigation points are valid open water")
			check(not world.segment_free(west,east),"direct sailing route respects physical sand-and-rock coastline")
			var route:Array[Vector2]=world.plan_path(west,east)
			check(not route.is_empty(),"navigation can plot a safe course AROUND first new island")
			if not route.is_empty():
				check(route.back().distance_to(east)<60,"island detour reaches chosen player destination")
				var previous:Vector2=west
				for stop:Vector2 in route:
					check(world.segment_free(previous,stop,2.0),"every programmed detour segment is entirely navigable")
					previous=stop
	var bonus=SIM.new()
	bonus.configure_map(3)
	check(bonus.islands.size()>0 and bonus.islands.all(func(item):return not item.has("m392_asset_id")),"bonus maps do not receive A01 assets")
	var previous=SIM.new()
	check(previous.restore_save(backup) and previous.map_id==0,"legacy save loads without migration or graphic corruption")
	var scene=load("res://sea_map.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await process_frame
	scene.set_process(false)
	scene.sim.configure_map(CONTENT.realm_map_id(1))
	scene.queue_redraw()
	await process_frame
	await process_frame
	check(scene.sim.islands.any(func(item):return str(item.get("m392_art_source",""))=="approved"),"mobile/Classic renderer sees first real island")
	check(scene.island_textures.has("m392_a01"),"new island PNG actually loaded and cached into game renderer")
	scene.queue_free()
	print(JSON.stringify({"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,
		"approved_count":summary.approved,"asset":"A01","png_size":[512,512]}))
	quit(0 if failures.is_empty() else 1)
