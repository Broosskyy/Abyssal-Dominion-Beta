class_name HalloweenEventInteraction
extends RefCounted
## Local event-world interaction. Quest progress only; no live reward authority.

static func nearest(player:Node3D)->Node3D:
	if player==null:return null
	var best:Node3D=null
	var best_d:=INF
	for node in player.get_tree().get_nodes_in_group("event_interactables"):
		if not node is Node3D:continue
		var d:=player.global_position.distance_to((node as Node3D).global_position)
		var r:=float(node.get_meta("interaction_range",8.5))
		if d<=r and d<best_d:best=node;best_d=d
	return best

static func prompt(player:Node3D)->Dictionary:
	var node:=nearest(player)
	if node==null:return {}
	var id:=str(node.get_meta("interaction_id",""))
	return {
		"id":id,
		"title":"GEISTERWRACK" if id=="event_halloween_wreck_01" else "HALLOWEEN PORTAL",
		"action":"UNTERSUCHEN" if id=="event_halloween_wreck_01" else "PORTAL PRÜFEN",
		"distance":player.global_position.distance_to(node.global_position)
	}

static func activate(player:Node3D)->Dictionary:
	var node:=nearest(player)
	if node==null:return {"ok":false}
	var id:=str(node.get_meta("interaction_id",""))
	var runtime:=player.get_tree().get_first_node_in_group("event_runtime") as EventRuntime
	if runtime==null or not runtime.is_active():return {"ok":false}
	if id=="event_halloween_wreck_01":
		runtime.record_event_explore(id)
		node.set_meta("explored_local",true)
		return {"ok":true,"message":"Geisterwrack untersucht · Eventauftrag aktualisiert"}
	if id=="event_portal":
		return {"ok":true,"message":"Portal resoniert · %s"%runtime.phase_label()}
	return {"ok":false}
