class_name DynamicEncounterContent
extends RefCounted
static func definition(tree:SceneTree,id:String)->Dictionary:
	var npc:=DynamicContentResolver.by_id(tree,"npc",id)
	if not npc.is_empty():return npc
	return DynamicContentResolver.by_id(tree,"monster",id)
static func apply_definition(ship:ShipMotor,row:Dictionary)->void:
	if ship==null or row.is_empty():return
	ship.set_meta("content_id",str(row.get("id","")))
	ship.set_meta("production_slot",str(row.get("asset_slot","")))
	ship.set_meta("placeholder_replacement_ready",true)
	var health:=ship.get_node_or_null("Health") as ShipHealth
	if health!=null:
		health.max_health=float(row.get("hull",health.max_health));health.current_health=health.max_health
	var weapons:=ship.get_node_or_null("Weapons") as ShipWeapons
	if weapons!=null:
		weapons.damage=float(row.get("damage",weapons.damage));weapons.reload_seconds=float(row.get("reload",weapons.reload_seconds))
	var ai:=ship.get_node_or_null("EnemyAI") as EnemyShipAI
	if ai!=null:ai.archetype=str(row.get("ai_profile",ai.archetype))
