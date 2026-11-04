class_name DynamicPoiInteraction
extends RefCounted

static func nearest(tree:SceneTree,player:ShipMotor,max_distance:float=5.5)->Node3D:
	if tree==null or player==null:return null
	var best:Node3D=null;var best_distance:=INF
	for node in tree.get_nodes_in_group("world_poi_markers"):
		var poi:=node as Node3D
		if poi==null or bool(poi.get_meta("poi_consumed",false)):continue
		var radius:=minf(max_distance,clampf(float(poi.get_meta("interaction_radius",max_distance)),2.0,12.0)) if max_distance>0.0 else clampf(float(poi.get_meta("interaction_radius",5.5)),2.0,12.0)
		var distance:=player.global_position.distance_to(poi.global_position)
		if distance<=radius and distance<best_distance:
			best=poi;best_distance=distance
	return best

static func prompt(tree:SceneTree,player:ShipMotor)->String:
	var poi:=nearest(tree,player)
	if poi==null:return ""
	return "INTERAGIEREN · "+str(poi.get_meta("poi_label",poi.name))

static func activate(tree:SceneTree,poi:Node3D)->bool:
	if tree==null or poi==null or bool(poi.get_meta("poi_consumed",false)):return false
	var kind:=str(poi.get_meta("poi_kind",""))
	QuestActivityBus.emit(tree,"poi",{
		"content_id":str(poi.get_meta("content_id",poi.name)),
		"tags":poi.get_meta("content_tags",[kind]),
		"amount":1
	})
	if not bool(poi.get_meta("repeatable",false)):
		poi.set_meta("poi_consumed",true)
		var world:=tree.get_first_node_in_group("world_map") as WorldMapSystem
		if world!=null:world.mark_poi_consumed(str(poi.get_meta("poi_instance_id",poi.get_meta("content_id",poi.name))))
	return true

static func activate_nearest(tree:SceneTree,player:ShipMotor)->bool:
	return activate(tree,nearest(tree,player))
