class_name GuildIslandInteraction
extends RefCounted
## Local presentation/query layer only. Future writes require authoritative guild backend.

static func nearest(player:Node3D,max_extra:float=0.0)->Node3D:
	if player==null:return null
	var best:Node3D=null
	var best_d:=INF
	for node in player.get_tree().get_nodes_in_group("guild_islands"):
		if not node is Node3D:continue
		var d:=player.global_position.distance_to((node as Node3D).global_position)
		var range:=float(node.get_meta("interaction_range",9.0))+max_extra
		if d<=range and d<best_d:
			best=node
			best_d=d
	return best

static func prompt(player:Node3D)->Dictionary:
	var island:=nearest(player)
	if island==null:return {}
	return {
		"title":"GILDENINSEL",
		"subtitle":"Anchorage · Kartenlevel %d"%int(island.get_meta("map_level",2)),
		"relation":relation_label(island),
		"actions":GuildIslandComposer.interaction_rows(island),
		"server_authority":false
	}

static func relation_label(island:Node)->String:
	if island==null:return ""
	match str(island.get_meta("relation","neutral_preview")):
		"owned":return "EIGENE GILDE"
		"ally":return "VERBÜNDET"
		"enemy":return "FEIND"
		"war":return "KRIEGSZIEL"
		_:return "NEUTRALE VORSCHAU"

static func activate(player:Node3D,id:String)->Dictionary:
	var island:=nearest(player)
	if island==null:return {"ok":false}
	for row in GuildIslandComposer.interaction_rows(island):
		if str(row.get("id",""))==id:
			var result={"ok":true,"id":id,"label":row.get("label",id),"authority":row.get("authority","presentation_only")}
			if id=="inspect_defense":
				result["rows"]=GuildIslandComposer.tower_rows(island)
				result["focus_kind"]="tower"
			elif id=="inspect_facilities":
				result["rows"]=GuildIslandComposer.facility_rows(island)
				result["focus_kind"]="facility"
			elif id=="inspect_guild":
				result["rows"]=[{"label":"Mitgliedschaft / Rollen / Diplomatie","server_required":true}]
			elif id=="dock":
				result["rows"]=[{"label":"Ankerplatz erkannt · Docking-Kontext lokal verfügbar","server_required":false}]
			elif id=="inspect_harbor":
				result["rows"]=[
					{"label":"Ankerplatz / Dock","server_required":false},
					{"label":"Reparaturstation","server_required":true},
					{"label":"Lager / Versorgung","server_required":true}
				]
				result["focus_kind"]="facility"
			elif id=="range_preview":
				var visible:=not bool(island.get_meta("range_preview_visible",false))
				GuildIslandVisualState.set_range_preview(island,visible)
				result["rows"]=[{"label":"Turmreichweiten %s"%("EIN" if visible else "AUS"),"server_required":false}]
				result["range_preview"]=visible
			return result
	return {"ok":false}
