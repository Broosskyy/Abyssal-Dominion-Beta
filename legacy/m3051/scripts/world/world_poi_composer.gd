class_name WorldPoiComposer
extends RefCounted
## Deterministic visual POI dressing. This class never grants loot, quests or combat rewards.

static func populate(root:Node3D,level:int,seed_value:int,forbidden:Array[Vector3]=[],sector_id:String="",region_id:String="")->void:
	if root == null: return
	var mix:=ChartCompositionCatalog.poi_mix(region_id,level)
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	var used:Array[Vector3]=forbidden.duplicate()
	var count:=mini(mix.size(),4)
	for i in count:
		var kind:=str(mix[i])
		var pos:=_find_position(rng,used,i,seed_value,region_id)
		if not pos.is_finite(): continue
		used.append(pos)
		var poi:=Node3D.new()
		poi.name="POI_%s_%02d"%[kind,i]
		poi.position=pos
		poi.add_to_group("world_poi_markers")
		poi.set_meta("poi_kind",kind)
		var content_id:="POI-%s-%02d"%[kind.to_upper(),i]
		var instance_id:="%s::%s"%[sector_id if not sector_id.is_empty() else "SECTOR-UNKNOWN",content_id]
		poi.set_meta("content_id",content_id)
		poi.set_meta("poi_instance_id",instance_id)
		poi.set_meta("content_tags",[kind,"poi"])
		var d:=WorldPoiCatalog.definition(kind)
		poi.set_meta("marker_slot",str(d.get("marker_slot","world_interact")))
		poi.set_meta("poi_label",str(d.get("label",kind.to_upper())))
		poi.set_meta("marker_priority",WorldMarkerPriorityCatalog.priority(kind))
		poi.set_meta("visual_only",false)
		poi.set_meta("interaction_radius",5.5)
		poi.set_meta("repeatable",false)
		var world:=tree_world(root)
		poi.set_meta("poi_consumed",world.poi_consumed(instance_id) if world!=null else false)
		root.add_child(poi)
		var slot:=str(d.get("model_slot",""))
		if slot.is_empty() or AssetVisualLibrary.install(poi,slot)==null:
			_fallback(poi,kind)
		MonsterAreaDressing.decorate(poi,kind)
		WreckLandmarkComposer.decorate(poi,kind)

	# Admin-authored POIs are additive and use the same replaceable AssetSlot/fallback contract.
	var tree:=root.get_tree()
	for row in DynamicContentResolver.active_records(tree,"poi"):
		var sectors:Array=row.get("sector_ids",[]);var regions:Array=row.get("region_ids",[])
		if not sectors.is_empty() and sector_id not in sectors:continue
		if not regions.is_empty() and region_id not in regions:continue
		var authored:Variant=row.get("local_position",[])
		var pos:=Vector3(float(authored[0]),0.35,float(authored[1])) if authored is Array and authored.size()>=2 else _find_position(rng,used,used.size(),seed_value,region_id)
		if not pos.is_finite():continue
		used.append(pos)
		var poi:=Node3D.new();var id:=str(row.get("id","POI-DYNAMIC"))
		var instance_id:="%s::%s"%[sector_id if not sector_id.is_empty() else "SECTOR-UNKNOWN",id]
		poi.name=id.replace("-","_");poi.position=pos;poi.add_to_group("world_poi_markers")
		poi.set_meta("poi_kind",str(row.get("kind","dynamic")))
		poi.set_meta("content_id",id);poi.set_meta("poi_instance_id",instance_id);poi.set_meta("content_tags",row.get("tags",["poi"]))
		poi.set_meta("poi_label",str(row.get("name",id)))
		poi.set_meta("marker_slot",str(row.get("marker_slot","world_interact")))
		poi.set_meta("marker_priority",int(row.get("marker_priority",55)))
		poi.set_meta("visual_only",false)
		poi.set_meta("interaction_radius",clampf(float(row.get("interaction_radius",5.5)),2.0,12.0))
		poi.set_meta("repeatable",bool(row.get("repeatable",false)))
		var world:=tree_world(root);poi.set_meta("poi_consumed",world.poi_consumed(instance_id) if world!=null else false)
		poi.set_meta("production_slot",str(row.get("asset_slot","")))
		poi.set_meta("placeholder_replacement_ready",true)
		root.add_child(poi)
		var slot:=str(row.get("asset_slot",""))
		if slot.is_empty() or AssetVisualLibrary.install(poi,slot)==null:_fallback(poi,str(row.get("fallback_kind","shrine")))

static func _find_position(rng: RandomNumberGenerator, used: Array[Vector3], index:int=0, seed_value:int=0, region_id:String="") -> Vector3:
	# M196: POIs use the complete 360x360 chart and region-aware macro anchors.
	# The POI count remains platform-neutral; only the named region changes its semantic mix and placement.
	const EXTENT:=155.0
	for attempt in 32:
		var p:=ChartCompositionCatalog.poi_anchor(index,seed_value,EXTENT,region_id) if attempt==0 else Vector3(rng.randf_range(-EXTENT,EXTENT),0.35,rng.randf_range(-EXTENT,EXTENT))
		if Vector2(p.x,p.z).length()<28.0: continue
		var ok:=true
		for q in used:
			if Vector2(p.x-q.x,p.z-q.z).length()<16.0:
				ok=false
				break
		if ok:return p
	return Vector3(INF,INF,INF)

static func _fallback(root: Node3D, kind: String) -> void:
	var visual:=Node3D.new()
	visual.name="ProceduralFallback"
	visual.set_meta("classification","POLISHED_PROCEDURAL_FALLBACK")
	root.add_child(visual)
	if kind in ["monster_nest","monster_warning"]:
		for i in 3:
			_add_rock(visual,Vector3((i-1)*0.65,0.28,abs(i-1)*0.25),Vector3(0.75,0.55,0.7))
		if kind=="monster_warning":
			_add_box(visual,Vector3(0,1.0,0),Vector3(0.22,1.8,0.22),EnvironmentMaterialCatalog.harbor_wood())
	elif kind=="wreck_beacon":
		_add_box(visual,Vector3(0,0.18,0),Vector3(1.8,0.16,0.3),EnvironmentMaterialCatalog.harbor_wood())
		_add_box(visual,Vector3(0.55,0.6,0),Vector3(0.16,1.0,0.16),EnvironmentMaterialCatalog.harbor_wood())
	elif kind=="shrine":
		_add_box(visual,Vector3(0,0.8,0),Vector3(0.7,1.6,0.7),EnvironmentMaterialCatalog.harbor_stone())
		_add_box(visual,Vector3(0,1.75,0),Vector3(1.1,0.18,1.1),EnvironmentMaterialCatalog.harbor_stone())
	else:
		_add_box(visual,Vector3(0,0.45,0),Vector3(1.2,0.9,1.2),EnvironmentMaterialCatalog.harbor_wood())

static func _add_rock(parent: Node3D,pos:Vector3,size:Vector3)->void:
	var n:=MeshInstance3D.new()
	n.mesh=FallbackPrimitiveLibrary.sphere(0.5,0.9)
	n.position=pos
	n.scale=size
	n.material_override=EnvironmentMaterialCatalog.rock()
	parent.add_child(n)

static func _add_box(parent:Node3D,pos:Vector3,size:Vector3,material:Material)->void:
	var n:=MeshInstance3D.new()
	n.mesh=FallbackPrimitiveLibrary.box(size)
	n.position=pos
	n.material_override=material
	parent.add_child(n)

static func tree_world(root:Node)->WorldMapSystem:
	if root==null or root.get_tree()==null:return null
	return root.get_tree().get_first_node_in_group("world_map") as WorldMapSystem
