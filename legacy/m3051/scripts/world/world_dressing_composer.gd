class_name WorldDressingComposer
extends RefCounted
const FAMILIES := {
	"tropical":["nature_palm_cluster_01","nature_rock_cluster_01","nature_driftwood_cluster_01"],
	"desert":["nature_rock_cluster_01","nature_driftwood_cluster_01"],
	"snow":["nature_rock_cluster_01"]
}

static func decorate_island(island:Node3D,biome:String,seed_value:int,quality:String="balanced")->void:
	if island==null:return
	var region_id:=str(island.get_meta("canonical_region_id",island.get_meta("region_id","")))
	var slots:Array=P1RegionalRuntimeCatalog.nature_slots(region_id)
	if slots.is_empty():slots=FAMILIES.get(biome,FAMILIES.tropical)
	var density:float=float({"low":0.48,"balanced":0.72,"high":1.0}.get(quality,0.72))
	density*=float(island.get_meta("island_prop_density",0.7))
	var budget:=VisualQualityResolver.decorator_budget()
	var count:=clampi(roundi(float(budget)*density),1,budget)
	var rng:=RandomNumberGenerator.new()
	rng.seed=seed_value
	var root:=Node3D.new()
	root.name="M73WorldDressing"
	root.set_meta("visual_only",true)
	root.set_meta("batch_candidate",true)
	root.set_meta("decorator_budget",budget)
	root.set_meta("platform_profile",VisualQualityResolver.platform_key())
	root.set_meta("m149_region",region_id)
	island.add_child(root)
	var radius:=float(island.get_meta("island_radius",5.0))
	for i in count:
		var slot:=str(slots[i%slots.size()])
		var socket:=Node3D.new()
		socket.name="Dress_%02d_%s"%[i,slot]
		var angle:=rng.randf_range(0.0,TAU)
		var r:=rng.randf_range(radius*0.18,radius*0.58)
		socket.position=Vector3(cos(angle)*r,0.75,sin(angle)*r)
		socket.rotation.y=rng.randf_range(-PI,PI)
		socket.scale=Vector3.ONE*rng.randf_range(0.82,1.18)
		socket.set_meta("production_slot",slot)
		root.add_child(socket)
		if AssetVisualLibrary.install(socket,slot)==null:
			_fallback(socket,slot)
		else:
			P1RegionalPresentationAdapter.apply_world_asset(socket,region_id,"world")
		_apply_visibility_budget(socket,quality)
	ShallowCoastDressing.decorate(island,quality)

static func _fallback(parent:Node3D,slot:String)->void:
	var mesh_node:=MeshInstance3D.new()
	mesh_node.name="Fallback"
	if slot=="nature_palm_cluster_01":
		mesh_node.mesh=FallbackPrimitiveLibrary.cylinder(0.10,0.18,1.8)
		mesh_node.position.y=0.9
		mesh_node.material_override=EnvironmentMaterialCatalog.harbor_wood()
	else:
		mesh_node.mesh=FallbackPrimitiveLibrary.sphere(0.45,0.75)
		mesh_node.scale=Vector3(1.2,0.7,1.0)
		mesh_node.material_override=EnvironmentMaterialCatalog.rock()
	parent.add_child(mesh_node)

static func _apply_visibility_budget(root:Node,quality:String)->void:
	var fallback:=28.0 if quality=="low" else (38.0 if quality=="balanced" else 52.0)
	MobilePresentationBudget.apply_geometry_visibility(root,fallback,4.0)
