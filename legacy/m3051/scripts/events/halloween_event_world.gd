class_name HalloweenEventWorld
extends RefCounted
## Visual seasonal world composition only. No event reward/combat/server authority.

static func apply(root:Node3D,runtime:EventRuntime,map_level:int)->void:
	if root==null:return
	var old:=root.get_node_or_null("M94HalloweenEvent")
	if old!=null:
		root.remove_child(old)
		old.queue_free()
	_clear_guild_layer(root)
	if runtime==null or not runtime.is_active() or runtime.active_event_id!="halloween_abyss_01" or map_level<2:return
	var layer:=Node3D.new()
	layer.name="M94HalloweenEvent"
	layer.add_to_group("event_world_layer")
	layer.set_meta("event_id",runtime.active_event_id)
	layer.set_meta("phase",runtime.phase)
	layer.set_meta("visual_only",true)
	root.add_child(layer)
	_add_slot(layer,"event_halloween_portal_01",Vector3(-27,0.35,-17),1.15)
	_add_slot(layer,"event_halloween_wreck_01",Vector3(25,0.28,18),1.0)
	# Preview sockets only: online positions, pickup eligibility and wreck HP must be
	# supplied by a verified server world snapshot, never by these visual positions.
	for i in 3:
		_add_slot(layer,"event_halloween_pumpkin_01",Vector3(-18.0+float(i)*7.4,0.55,12.0+float(i%2)*4.0),0.85,"_%d"%i)
	_add_slot(layer,"event_halloween_pumpkin_wreck_01",Vector3(19,0.4,-11),1.1)
	var fleet:Array=runtime.phase_row().get("fleet",[])
	for i in mini(3,fleet.size()):
		var angle:float=-0.7+0.7*i
		var fleet_slot:=str(fleet[i])
		var spawned:=HalloweenEventEncounters.spawn(layer,fleet_slot,Vector3(cos(angle)*20.0,0.55,sin(angle)*19.0),runtime)
		if spawned!=null and fleet_slot=="event_halloween_boss_01":
			spawned.set_meta("poi_kind","event_boss")
			spawned.set_meta("marker_priority",96)
			CombatVfx.action(root.get_tree(),"halloween_boss_arrival",spawned.global_position)
	_apply_guild_layer(root)

static func _apply_guild_layer(root:Node3D)->void:
	for island in _sector_islands(root):
		var socket:=Node3D.new()
		socket.name="M94HalloweenGuildLayer"
		socket.position=Vector3(0,1.45,-2.2)
		socket.set_meta("production_slot","event_halloween_guild_deco_01")
		socket.set_meta("visual_only",true)
		island.add_child(socket)
		if AssetVisualLibrary.install(socket,"event_halloween_guild_deco_01")==null:
			var lantern:=MeshInstance3D.new()
			lantern.mesh=FallbackPrimitiveLibrary.sphere(0.42,0.56)
			var mat:=StandardMaterial3D.new()
			mat.albedo_color=Color("d66b2b");mat.emission_enabled=true;mat.emission=Color("a83d18");mat.emission_energy_multiplier=1.2
			lantern.material_override=mat;lantern.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			socket.add_child(lantern)

static func _clear_guild_layer(root:Node3D)->void:
	for island in _sector_islands(root):
		var old:=island.get_node_or_null("M94HalloweenGuildLayer")
		if old!=null:
			island.remove_child(old)
			old.queue_free()

static func _sector_islands(root:Node3D)->Array[Node3D]:
	var result:Array[Node3D]=[]
	if not root.is_inside_tree():return result
	for island in root.get_tree().get_nodes_in_group("guild_islands"):
		if island is Node3D and not island.is_queued_for_deletion() and root.is_ancestor_of(island):
			result.append(island as Node3D)
	return result

static func _add_slot(parent:Node3D,slot:String,pos:Vector3,scale_value:float,suffix:String="")->void:
	var socket:=Node3D.new()
	socket.name="Slot_"+slot+suffix;socket.position=pos;socket.scale=Vector3.ONE*scale_value
	socket.set_meta("production_slot",slot);socket.set_meta("event_id","halloween_abyss_01");socket.set_meta("visual_only",true)
	if slot=="event_halloween_portal_01":
		socket.add_to_group("world_poi_markers");socket.add_to_group("event_interactables")
		socket.set_meta("poi_kind","event_portal");socket.set_meta("poi_label","HALLOWEEN PORTAL");socket.set_meta("marker_slot","m95_event_target")
		socket.set_meta("marker_priority",84);socket.set_meta("interaction_id","event_portal");socket.set_meta("interaction_range",8.5)
	elif slot=="event_halloween_wreck_01":
		socket.add_to_group("world_poi_markers");socket.add_to_group("event_interactables")
		socket.set_meta("poi_kind","event_wreck");socket.set_meta("poi_label","GEISTERWRACK");socket.set_meta("marker_slot","m94_halloween_quest")
		socket.set_meta("marker_priority",73);socket.set_meta("interaction_id","event_halloween_wreck_01");socket.set_meta("interaction_range",8.5)
	elif slot=="event_halloween_pumpkin_01":
		socket.set_meta("collectible_preview_only",true);socket.set_meta("server_spawn_identity_required",true)
	elif slot=="event_halloween_pumpkin_wreck_01":
		socket.set_meta("harpoon_target_preview_only",true);socket.set_meta("server_spawn_identity_required",true)
	parent.add_child(socket)
	if AssetVisualLibrary.install(socket,slot)==null:_fallback(socket,slot)
	if slot=="event_halloween_portal_01":
		CombatVfx.action(parent.get_tree(),"halloween_portal",socket.global_position)

static func _fallback(parent:Node3D,slot:String)->void:
	var body:=MeshInstance3D.new();body.name="HalloweenFallback"
	if "pumpkin_wreck" in slot:
		body.mesh=FallbackPrimitiveLibrary.box(Vector3(3.0,0.62,1.38));body.rotation_degrees.y=20
	elif "pumpkin" in slot:
		body.mesh=FallbackPrimitiveLibrary.sphere(0.8,0.67)
	elif "portal" in slot:
		body.mesh=FallbackPrimitiveLibrary.torus(1.2,1.5);body.rotation_degrees.x=90
	elif "wreck" in slot:
		body.mesh=FallbackPrimitiveLibrary.box(Vector3(3.1,0.42,1.2));body.rotation_degrees.y=-21
	elif "monster" in slot or "boss" in slot:
		body.mesh=FallbackPrimitiveLibrary.sphere(1.05,1.25)
	else:body.mesh=FallbackPrimitiveLibrary.box(Vector3(2.5,0.48,0.92))
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("b95e28") if "pumpkin" in slot else (Color("24372e") if "npc" in slot else Color("5b3b68"))
	mat.emission_enabled=true;mat.emission=Color("aa4c1b") if "pumpkin" in slot else (Color("476b45") if "npc" in slot else Color("6f437d"));mat.emission_energy_multiplier=0.45
	body.material_override=mat;body.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(body)
