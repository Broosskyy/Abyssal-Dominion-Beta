class_name ActionItemBehaviorExecutor
extends RefCounted
static func execute(tree:SceneTree,user:ShipMotor,target:ShipMotor,definition:Dictionary)->bool:
	if user==null:return false
	var health:=user.get_node_or_null("Health") as ShipHealth
	if health==null:return false
	var components:Array=definition.get("behavior_components",[])
	if components.is_empty():
		var legacy:=legacy_component(definition)
		if not legacy.is_empty():components=[legacy]
	if not ContentBehaviorEngine.validate_components(components).is_empty():return false
	var applied:=false
	for row in components:
		if not row is Dictionary:continue
		var kind:=str(row.get("kind",""))
		match kind:
			"damage":
				if target==null:continue
				var h:=target.get_node_or_null("Health") as ShipHealth
				if h!=null:h.apply_damage(float(row.get("amount",0.0)),user,float(row.get("armor_pierce",0.0)));applied=true
			"status":
				if target==null:continue
				var h:=target.get_node_or_null("Health") as ShipHealth
				if h!=null:h.apply_ammo_effect(str(row.get("status_id","")),float(row.get("power",0.0)),float(row.get("duration",0.0)),user);applied=true
			"heal":
				var hull:=float(row.get("hull",0.0));var shield:=float(row.get("shield",0.0))
				if hull>0.0 and health.current_health<health.max_health:applied=health.repair(hull)>0.0 or applied
				if shield>0.0:health.restore_shield(shield);applied=true
			"movement_modifier":
				user.add_speed_effect(str(row.get("effect_id","admin_speed")),float(row.get("speed_mult",1.0)),float(row.get("duration",0.0)));applied=true
			"barrier":
				health.grant_temporary_barrier(float(row.get("amount",0.0)),float(row.get("duration",0.0)));applied=true
			"aoe_damage":
				var hit_any:=false;var radius:=float(row.get("radius",0.0));var pierce:=float(row.get("armor_pierce",0.1))
				for value in tree.get_nodes_in_group(str(row.get("target_group","enemies"))):
					var enemy:=value as ShipMotor
					if enemy!=null and user.global_position.distance_to(enemy.global_position)<=radius:
						var h:=enemy.get_node_or_null("Health") as ShipHealth
						if h!=null:h.apply_damage(float(row.get("amount",0.0)),user,pierce);hit_any=true
				applied=hit_any or applied
			"target_denial":
				var duration:=float(row.get("duration",0.0));user.set_meta("veil_active",true);user.set_meta("veil_until",Time.get_ticks_msec()/1000.0+duration)
				tree.create_timer(duration).timeout.connect(func():
					if is_instance_valid(user) and Time.get_ticks_msec()/1000.0>=float(user.get_meta("veil_until",0.0)):user.set_meta("veil_active",false))
				applied=true
			"repair_block":
				if target!=null:
					var h:=target.get_node_or_null("Health") as ShipHealth
					if h!=null:h.block_repair(float(row.get("duration",0.0)));applied=true
			"recall":
				if bool(row.get("requires_no_target",true)) and target!=null:continue
				if bool(row.get("disallow_in_safe_zone",true)) and user.get_meta("in_safe_zone",false):continue
				var input:=user.get_node_or_null("PlayerInput") as PlayerShipInput
				if input!=null:input.cancel_navigation()
				user.global_position=health.respawn_position;applied=true
			_:
				pass
	return applied
static func legacy_component(definition:Dictionary)->Dictionary:
	match str(definition.get("effect","")):
		"hull_repair":return {"kind":"heal","hull":float(definition.get("amount",0.0))}
		"speed_boost":return {"kind":"movement_modifier","speed_mult":float(definition.get("multiplier",1.0)),"duration":float(definition.get("duration",0.0))}
		"damage","monster_damage":return {"kind":"damage","amount":float(definition.get("damage",0.0)),"armor_pierce":float(definition.get("armor_pierce",0.25 if str(definition.get("effect",""))=="monster_damage" else 0.0))}
		"temporary_barrier":return {"kind":"barrier","amount":float(definition.get("amount",0.0)),"duration":float(definition.get("duration",0.0))}
		"armor_break":return {"kind":"status","status_id":"armor_break","power":float(definition.get("power",0.0)),"duration":float(definition.get("duration",0.0))}
		"aoe_damage":return {"kind":"aoe_damage","amount":float(definition.get("damage",0.0)),"radius":float(definition.get("radius",0.0)),"armor_pierce":0.1,"target_group":"enemies"}
		"target_denial":return {"kind":"target_denial","duration":float(definition.get("duration",0.0))}
		"repair_block":return {"kind":"repair_block","duration":float(definition.get("duration",0.0))}
		"recall":return {"kind":"recall","requires_no_target":true,"disallow_in_safe_zone":true}
	return {}
